package service

import (
	"context"
	"time"

	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/db"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/http/util"
	"github.com/google/uuid"
)

// Opens an exam by id and from a teacher. If startedAt or endedAt are not null
// then a 400 error will be thrown.
func OpenExam(ctx context.Context, q *db.Queries, examId uuid.UUID, teacherId *uuid.UUID) (db.FrExam, error) {

	exam, err := q.FindExamByTeacherIdAndId(ctx, db.FindExamByTeacherIdAndIdParams{
		ID:        examId,
		TeacherID: teacherId,
	})

	if err != nil {
		return db.FrExam{}, util.ErrEntityNotFound("Exam", examId)
	}

	if exam.StartedAt != nil || exam.EndedAt != nil {
		return db.FrExam{}, util.ErrBadRequest.Msg("Exam has already been started!")
	}

	var now = time.Now()

	updated, err := q.UpdateExam(ctx, db.UpdateExamParams{
		ID:        exam.ID,
		Title:     exam.Title,
		StartTime: exam.StartTime,
		EndTime:   exam.EndTime,
		StartedAt: &now,
		EndedAt:   nil})

	if err != nil {
		return db.FrExam{}, err
	}

	return updated, nil
}
