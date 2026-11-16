package service

import (
	"context"
	"time"

	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/db"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/http/util"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
)

// Opens an exam by id and from a teacher
func OpenExam(ctx context.Context, q *db.Queries, examId uuid.UUID, teacherId *uuid.UUID) (db.FrExam, error) {

	exam, err := q.FindExamByTeacherIdAndId(ctx, db.FindExamByTeacherIdAndIdParams{
		ID:        examId,
		TeacherID: teacherId,
	})

	if err != nil {
		return db.FrExam{}, util.ErrEntityNotFound("Exam", examId)
	}

	if exam.StartedAt.Valid || exam.EndedAt.Valid {
		return db.FrExam{}, util.ErrBadRequest.Msg("Exam has already been started!")
	}

	exam.StartedAt = pgtype.Timestamptz{
		Time:  time.Now(),
		Valid: true,
	}

	updated, err := q.UpdateExam(ctx, db.UpdateExamParams{
		ID:        exam.ID,
		StartTime: exam.StartTime,
		EndTime:   exam.EndTime,
		StartedAt: exam.StartedAt,
		EndedAt: pgtype.Timestamptz{
			Valid: false,
		},
	})

	if err != nil {
		return db.FrExam{}, err
	}

	return updated, nil
}
