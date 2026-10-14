package handlers

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"log/slog"
	"net/http"

	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/db"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/http/util"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
)

func baseNoticeValidator(
	noticeType db.FrNoticeType,
	content string,
	start pgtype.Timestamp,
	end pgtype.Timestamp,
) util.Problems {
	p := util.Problems{}

	p.Require(noticeType == db.FrNoticeTypeTimed ||
		noticeType == db.FrNoticeTypeAlert ||
		noticeType == db.FrNoticeTypeSingle, "type",
		fmt.Sprintf("must be of value `%s`, `%s` or `%s`",
			db.FrNoticeTypeSingle, db.FrNoticeTypeTimed, db.FrNoticeTypeAlert),
	)

	if noticeType == db.FrNoticeTypeTimed {
		p.Require(
			start.Valid,
			"startTime",
			"must exist and be valid for a notice of type `"+string(db.FrNoticeTypeTimed)+"`",
		)
		p.Require(
			end.Valid,
			"endTime",
			"must exist and be valid for a notice of type `"+string(db.FrNoticeTypeTimed)+"`",
		)
	}

	p.Require(len(content) > 5, "content", "must be longer than 5 characters")

	return p
}

type CreateNoticeBody struct {
	Type      db.FrNoticeType  `json:"type"`
	Content   string           `json:"content"`
	StartTime pgtype.Timestamp `json:"startTime"`
	EndTime   pgtype.Timestamp `json:"endTime"`
}

func (b CreateNoticeBody) Valid(ctx context.Context) util.Problems {
	return baseNoticeValidator(b.Type, b.Content, b.StartTime, b.EndTime)
}

func CreateNotice(logger *slog.Logger, pool *pgxpool.Pool) http.HandlerFunc {
	return util.Handle(func(r *http.Request) (util.HttpResponse, error) {

		createNotice, err := util.DecodeValid[CreateNoticeBody](r)

		if err != nil {
			return util.HttpResponse{}, err
		}

		if createNotice.Type == db.FrNoticeTypeTimed &&
			(!createNotice.StartTime.Valid || !createNotice.EndTime.Valid) {
			return util.HttpResponse{},
				util.GeneralError(
					http.StatusUnprocessableEntity,
					`A "timed" notice must always have a "startTime" and "endTime"!`,
				)
		}

		newNotice, err := db.InTxV(r.Context(), pool, func(q *db.Queries) (db.FrNotice, error) {
			return q.CreateNotice(r.Context(), db.CreateNoticeParams{
				Type:      createNotice.Type,
				Content:   createNotice.Content,
				StartTime: createNotice.StartTime,
				EndTime:   createNotice.EndTime,
			})
		})

		if err != nil {
			return util.HttpResponse{}, err
		}

		return util.HttpResponse{
			Status: http.StatusCreated,
			Body:   newNotice,
			ExtraHeaders: map[string]string{
				"Location": r.URL.Path + "/" + newNotice.ID.String(),
			},
		}, nil
	}, logger)
}

func DeleteNotice(logger *slog.Logger, pool *pgxpool.Pool) http.HandlerFunc {
	return util.Handle(func(r *http.Request) (util.HttpResponse, error) {

		id, err := util.GetIdPathParam(r)

		if err != nil {
			return util.HttpResponse{}, util.ErrBadRequest
		}

		err = db.InTx(r.Context(), pool, func(q *db.Queries) error {
			return q.DeleteNotice(r.Context(), id)
		})

		if err != nil {
			return util.HttpResponse{}, err
		}
		return util.HttpResponse{
			Status: http.StatusNoContent,
		}, nil
	}, logger)
}

type NoticeUpdateBody struct {
	Content   string           `json:"content"`
	StartTime pgtype.Timestamp `json:"start_time"`
	EndTime   pgtype.Timestamp `json:"end_time"`
}

func (b NoticeUpdateBody) Valid(ctx context.Context) util.Problems {
	// Start and end time validation happens at db layer because a query would
	// be necessary before even running validation which I don't like.
	// That is why I use the "single" notice here because it doesn't check start
	// and end time.
	return baseNoticeValidator(db.FrNoticeTypeSingle, b.Content, b.StartTime, b.EndTime)
}

// TODO: Add notice check constraints to make type with start/end time enforced
// in the db layer.
func UpdateNotice(logger *slog.Logger, pool *pgxpool.Pool) http.HandlerFunc {
	return util.Handle(func(r *http.Request) (util.HttpResponse, error) {

		updateNotice, err := util.Decode[NoticeUpdateBody](r)

		id, err2 := util.GetIdPathParam(r)

		if err != nil || err2 != nil {
			return util.HttpResponse{}, util.ErrBadRequest
		}

		newUpdatedNotice, err := db.InTxV(r.Context(), pool, func(q *db.Queries) (db.FrNotice, error) {
			return q.UpdateNotice(r.Context(), db.UpdateNoticeParams{
				ID:        id,
				Content:   updateNotice.Content,
				StartTime: updateNotice.StartTime,
				EndTime:   updateNotice.EndTime,
			})
		})

		if errors.Is(err, sql.ErrNoRows) {
			return util.HttpResponse{},
				util.ErrNotFound.Msg(`Notice with id "%s" does not exist!`, id)
		}

		if err != nil {
			return util.HttpResponse{}, err
		}

		return util.HttpResponse{
			Status: http.StatusOK,
			Body:   newUpdatedNotice,
		}, nil
	}, logger)
}

func GetNoticeById(logger *slog.Logger, pool *pgxpool.Pool) http.HandlerFunc {
	return util.Handle(func(r *http.Request) (util.HttpResponse, error) {

		id, err := util.GetIdPathParam(r)

		if err != nil {
			return util.HttpResponse{}, util.ErrBadRequest
		}

		notice, err := db.InTxV(r.Context(), pool, func(q *db.Queries) (db.FrNotice, error) {
			return q.GetNoticeById(r.Context(), id)
		})

		if errors.Is(err, sql.ErrNoRows) {
			return util.HttpResponse{},
				util.ErrNotFound.Msg(`Notice with id "%s" does not exist!`, id)
		}

		if err != nil {
			return util.HttpResponse{}, err
		}

		return util.HttpResponse{
			Status: http.StatusOK,
			Body:   notice,
		}, nil
	}, logger)
}

func GetNotices(logger *slog.Logger, pool *pgxpool.Pool) http.HandlerFunc {
	return util.Handle(func(r *http.Request) (util.HttpResponse, error) {

		notices, err := db.InTxV(r.Context(), pool, func(q *db.Queries) ([]db.FrNotice, error) {
			return q.GetNotices(r.Context())
		})

		if err != nil {
			return util.HttpResponse{}, err
		}

		return util.HttpResponse{
			Status: http.StatusOK,
			Body:   notices,
		}, nil
	}, logger)
}
