package handlers

import (
	"context"
	"database/sql"
	"errors"
	"log/slog"
	"math/rand"
	"net/http"
	"time"

	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/config"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/db"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/http/middlewares"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/http/util"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/service"
	"github.com/google/uuid"
	"github.com/jackc/pgerrcode"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

// GetExamById godoc
//
//	@Summary		Get one of the calling teacher's exams by id
//	@Description	Only exams owned by the calling teacher are visible, any other id answers 404.
//	@Tags			exams
//	@Produce		json
//	@Security		BearerAuth
//	@Param			id	path		string	true	"exam id"	format(uuid)
//	@Success		200	{object}	db.FrExam
//	@Failure		400	{object}	util.ErrorResponse	"malformed id"
//	@Failure		403	{object}	util.ErrorResponse	"caller is not a teacher"
//	@Failure		404	{object}	util.ErrorResponse	"no exam with that id owned by the caller"
//	@Router			/api/v1/exams/{id} [get]
func GetExamById(logger *slog.Logger, pool *pgxpool.Pool) http.HandlerFunc {
	return util.Handle(func(r *http.Request) (util.HttpResponse, error) {
		examId, err := util.GetIdPathParam(r)

		if err != nil {
			return util.HttpResponse{}, util.ErrBadRequest
		}

		user, err := middlewares.GetFrUser(r.Context())

		if err != nil {
			return util.HttpResponse{}, err
		}

		exam, err := db.InTxV(r.Context(), pool, func(q *db.Queries) (db.FrExam, error) {
			return q.FindExamByTeacherIdAndId(r.Context(),
				db.FindExamByTeacherIdAndIdParams{
					ID:        examId,
					TeacherID: &user.ID,
				})
		})

		if errors.Is(err, sql.ErrNoRows) {
			return util.HttpResponse{}, util.ErrEntityNotFound("Exam", examId)
		}

		if err != nil {
			return util.HttpResponse{}, err
		}

		return util.HttpResponse{
			Status: http.StatusOK,
			Body:   exam,
		}, nil
	}, logger)
}

// GetMyExams godoc
//
//	@Summary	List the calling teacher's exams
//	@Tags		exams
//	@Produce	json
//	@Security	BearerAuth
//	@Success	200	{array}		db.FrExam
//	@Failure	403	{object}	util.ErrorResponse	"caller is not a teacher"
//	@Router		/api/v1/exams [get]
func GetMyExams(logger *slog.Logger, pool *pgxpool.Pool) http.HandlerFunc {
	return util.Handle(func(r *http.Request) (util.HttpResponse, error) {
		user, err := middlewares.GetFrUser(r.Context())

		if err != nil {
			return util.HttpResponse{}, err
		}

		exams, err := db.InTxV(r.Context(), pool, func(q *db.Queries) ([]db.FrExam, error) {
			return q.FindExamByTeacherId(r.Context(), &user.ID)
		})

		if err != nil {
			return util.HttpResponse{}, err
		}

		return util.HttpResponse{
			Status: http.StatusOK,
			Body:   exams,
		}, nil
	}, logger)
}

type CreateExamBody struct {
	Title     string     `json:"title"`
	StartTime *time.Time `json:"startTime"`
	EndTime   *time.Time `json:"endTime"`
}

func (ceb CreateExamBody) Valid(ctx context.Context) util.Problems {
	p := util.Problems{}

	p.Require(len(ceb.Title) >= 3, "title", "must be longer than 2 characters")
	p.Require(len(ceb.Title) <= 40, "title", "must be shorter than 41 characters")

	p.Require(ceb.EndTime != nil, "endTime", "is required and must be valid")
	p.Require(ceb.StartTime != nil, "startTime", "is required must be valid")
	if ceb.EndTime != nil && ceb.StartTime != nil {
		p.Require(
			ceb.EndTime.After(*ceb.StartTime),
			"endTime",
			"must be after `startTime`",
		)
	}

	return p
}

// CreateExam godoc
//
//	@Summary		Create an exam
//	@Description	Creates an exam owned by the calling teacher and assigns it a join PIN.
//	@Tags			exams
//	@Accept			json
//	@Produce		json
//	@Security		BearerAuth
//	@Param			request	body		CreateExamBody		true	"exam to create"
//	@Success		201		{object}	db.FrExam			"created exam"
//	@Header			201		{string}	Location			"URL of the created exam"
//	@Failure		400		{object}	util.ErrorResponse	"malformed body, or validation failed, see `problems`"
//	@Failure		403		{object}	util.ErrorResponse	"caller is not a teacher"
//	@Failure		404		{object}	util.ErrorResponse	"the teacher does not exist"
//	@Router			/api/v1/exams [post]
func CreateExam(logger *slog.Logger, pool *pgxpool.Pool, cfg *config.Config) http.HandlerFunc {
	return util.Handle(func(r *http.Request) (util.HttpResponse, error) {

		idToken, err := middlewares.GetJwtUser(r.Context())

		if err != nil {
			return util.HttpResponse{}, err
		}

		createExamBody, err := util.DecodeValid[CreateExamBody](r)

		if err != nil {
			return util.HttpResponse{}, err
		}

		teacherId := uuid.MustParse(idToken.Subject)

		// TODO: an existing pin will fail with Unique failure, retry on this error

		pin := (int16)(rand.Intn((int)(cfg.PinMax-cfg.PinMin))) + cfg.PinMin

		exam, err := db.InTxV(r.Context(), pool, func(q *db.Queries) (db.FrExam, error) {
			persistedUser, err := service.PersistedUser(
				r.Context(),
				q,
				idToken,
				cfg,
			)

			if err != nil {
				return db.FrExam{}, err
			}

			return q.CreateExam(r.Context(), db.CreateExamParams(db.CreateExamParams{
				TeacherID: &persistedUser.ID,
				Title:     createExamBody.Title,
				StartTime: *createExamBody.StartTime,
				EndTime:   *createExamBody.EndTime,
				Pin:       pin,
			}))
		})

		var pgErr *pgconn.PgError

		if errors.As(err, &pgErr) && pgErr.Code == pgerrcode.ForeignKeyViolation {
			return util.HttpResponse{}, util.ErrEntityNotFound("Teacher", teacherId)
		}

		if err != nil {
			return util.HttpResponse{}, err
		}

		return util.CreatedBody(r, exam, exam.ID), nil

	}, logger)
}

// actions: start, end, update schedule
// model:
// 		open now sets startedAt for actual
//		start now sets start_time for meta

// OpenExam godoc
//
//	@Summary		Open an exam
//	@Description	Opens an exam so students can join it, recording the moment it went live. Only an exam that has neither been opened nor ended can be opened.
//	@Tags			exams
//	@Produce		json
//	@Security		BearerAuth
//	@Param			id	path		string				true	"exam id"	format(uuid)
//	@Success		200	{object}	db.FrExam			"opened exam"
//	@Failure		400	{object}	util.ErrorResponse	"malformed id, or the exam is already open or has ended"
//	@Failure		403	{object}	util.ErrorResponse	"caller is not a teacher"
//	@Failure		404	{object}	util.ErrorResponse	"no exam with that id owned by the caller"
//	@Router			/api/v1/exams/{id}/open [post]
func OpenExam(logger *slog.Logger, pool *pgxpool.Pool) http.HandlerFunc {
	return util.Handle(func(r *http.Request) (util.HttpResponse, error) {
		id, err := util.GetIdPathParam(r)

		if err != nil {
			return util.HttpResponse{}, util.ErrBadRequest
		}

		user, err := middlewares.GetFrUser(r.Context())

		if err != nil {
			return util.HttpResponse{}, err
		}

		updatedExam, err := db.InTxV(r.Context(), pool, func(q *db.Queries) (db.FrExam, error) {
			return service.OpenExam(r.Context(), q, id, &user.ID)
		})

		if err != nil {
			return util.HttpResponse{}, err
		}

		return util.HttpResponse{
			Status: http.StatusOK,
			Body:   updatedExam,
		}, nil
	}, logger)
}
