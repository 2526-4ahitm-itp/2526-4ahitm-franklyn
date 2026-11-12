package handlers

import (
	"context"
	"database/sql"
	"errors"
	"log/slog"
	"math/rand"
	"net/http"

	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/config"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/db"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/http/middlewares"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/http/util"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/service"
	"github.com/google/uuid"
	"github.com/jackc/pgerrcode"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
)

func GetExamById(logger *slog.Logger, pool *pgxpool.Pool) http.HandlerFunc {
	return util.Handle(func(r *http.Request) (util.HttpResponse, error) {
		examId, err := util.GetIdPathParam(r)

		if err != nil {
			return util.HttpResponse{}, util.ErrBadRequest
		}

		exam, err := db.InTxV(r.Context(), pool, func(q *db.Queries) (db.FrExam, error) {
			return q.FindExamById(r.Context(), examId)
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

type CreateExamBody struct {
	Title     string             `json:"title"`
	StartTime pgtype.Timestamptz `json:"startTime"`
	EndTime   pgtype.Timestamptz `json:"endTime"`
}

func (ceb CreateExamBody) Valid(ctx context.Context) util.Problems {
	p := util.Problems{}

	p.Require(len(ceb.Title) >= 3, "title", "must be longer than 2 characters")
	p.Require(len(ceb.Title) <= 40, "title", "must be shorter than 41 characters")

	p.Require(ceb.EndTime.Valid, "endTime", "is required and must be valid")
	p.Require(ceb.StartTime.Valid, "startTime", "is required must be valid")
	p.Require(
		ceb.EndTime.Time.After(ceb.StartTime.Time),
		"endTime",
		"must be after `startTime`",
	)

	return p
}

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

		var pin int16 = (int16)(rand.Intn((int)(cfg.PinMax-cfg.PinMin))) + cfg.PinMin

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
				StartTime: createExamBody.StartTime,
				EndTime:   createExamBody.EndTime,
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
