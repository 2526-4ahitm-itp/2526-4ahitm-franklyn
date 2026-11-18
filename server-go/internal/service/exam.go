package service

import (
	"context"
	"database/sql"
	"errors"
	"math"
	"time"

	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/db"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/http/util"
	"github.com/google/uuid"
)

// Opens an exam by id and from a teacher. Only a scheduled exam can be opened.
// If `scheduled` is true then `preopen_time` will not be overwritten. If false
// then `preopen_time` is overwritten to now - `start_time`.
func OpenExam(ctx context.Context, q *db.Queries, scheduled bool, examId uuid.UUID, teacherId *uuid.UUID) (db.FrExam, error) {

	exam, err := q.FindExamByTeacherIdAndId(ctx, db.FindExamByTeacherIdAndIdParams{
		ID:        examId,
		TeacherID: teacherId,
	})

	if errors.Is(err, sql.ErrNoRows) {
		return db.FrExam{}, util.ErrEntityNotFound("Exam", examId)
	}

	if err != nil {
		return db.FrExam{}, util.ErrEntityNotFound("Exam", examId)
	}

	if exam.State != db.FrExamStateTypeScheduled {
		return db.FrExam{}, util.ErrBadRequest.Msg("Exam is not in scheduled state!")
	}

	// TODO: check side effect where this function is called but now is after start_time
	newPreopenTime := exam.PreopenTimeMinutes
	if !scheduled {
		// round up here because we want to take the minute before now.
		// if start_time - now is 5.5 minutes it would use 5 minutes when simply
		// casting to int but that is still in the future so students would only
		// be able to join after this minute has passed.

		newPreopenTime = int32(math.Ceil(time.Until(exam.StartTime).Minutes()))
	}

	updated, err := q.UpdateExam(ctx, db.UpdateExamParams{
		ID:                 exam.ID,
		Title:              exam.Title,
		StartTime:          exam.StartTime,
		EndTime:            exam.EndTime,
		State:              db.FrExamStateTypeOpen,
		PreopenTimeMinutes: newPreopenTime,
	})

	if err != nil {
		return db.FrExam{}, err
	}

	return updated, nil
}

// Starts an exam by id and from a teacher. Only an open exam can be started.
// If `scheduled` is true then `start_time` will not be overwriten. If false
// then `start_time` is overwritten to now.
func StartExam(ctx context.Context, q *db.Queries, scheduled bool, examId uuid.UUID, teacherId *uuid.UUID) (db.FrExam, error) {

	exam, err := q.FindExamByTeacherIdAndId(ctx, db.FindExamByTeacherIdAndIdParams{
		ID:        examId,
		TeacherID: teacherId,
	})

	if errors.Is(err, sql.ErrNoRows) {
		return db.FrExam{}, util.ErrEntityNotFound("Exam", examId)
	}

	if err != nil {
		return db.FrExam{}, util.ErrEntityNotFound("Exam", examId)
	}

	if exam.State != db.FrExamStateTypeOpen {
		return db.FrExam{}, util.ErrBadRequest.Msg("Exam is not in open state!")
	}

	var newStartTime = exam.StartTime
	if !scheduled {
		newStartTime = time.Now()
	}

	updated, err := q.UpdateExam(ctx, db.UpdateExamParams{
		ID:                 exam.ID,
		Title:              exam.Title,
		StartTime:          newStartTime,
		EndTime:            exam.EndTime,
		State:              db.FrExamStateTypeLive,
		PreopenTimeMinutes: exam.PreopenTimeMinutes,
	})

	if err != nil {
		return db.FrExam{}, err
	}

	return updated, nil
}

// Ends an exam by id and from a teacher. Only a live exam can be ended.
// If `scheduled` is true then `end_time` will not be overwritten. If false then
// `end_time` is overwritten to now.
func EndExam(ctx context.Context, q *db.Queries, scheduled bool, examId uuid.UUID, teacherId *uuid.UUID) (db.FrExam, error) {

	exam, err := q.FindExamByTeacherIdAndId(ctx, db.FindExamByTeacherIdAndIdParams{
		ID:        examId,
		TeacherID: teacherId,
	})

	if errors.Is(err, sql.ErrNoRows) {
		return db.FrExam{}, util.ErrEntityNotFound("Exam", examId)
	}

	if err != nil {
		return db.FrExam{}, err
	}

	if exam.State != db.FrExamStateTypeLive {
		return db.FrExam{}, util.ErrBadRequest.Msg("Exam is not in live state!")
	}

	newEndTime := exam.EndTime
	if !scheduled {
		newEndTime = time.Now()
	}

	updated, err := q.UpdateExam(ctx, db.UpdateExamParams{
		ID:                 exam.ID,
		Title:              exam.Title,
		StartTime:          exam.StartTime,
		EndTime:            newEndTime,
		State:              db.FrExamStateTypeEnded,
		PreopenTimeMinutes: exam.PreopenTimeMinutes,
	})

	if err != nil {
		return db.FrExam{}, err
	}

	return updated, nil
}
