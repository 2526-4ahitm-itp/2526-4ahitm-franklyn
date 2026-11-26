package handlers

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"time"

	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/db"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/http/util"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/service"
	"github.com/jackc/pgx/v5/pgxpool"
)

func baseNoticeValidator(
	noticeType db.FrNoticeType,
	content string,
	start *time.Time,
	end *time.Time,
) util.Problems {
	p := util.Problems{}

	p.Require(
		noticeType.Valid(),
		"type",
		fmt.Sprintf("must be one of %s",
			util.CollectArrToValids(db.AllFrNoticeTypeValues())),
	)

	if noticeType == db.FrNoticeTypeTimed {
		p.Require(
			start != nil,
			"startTime",
			"must exist and be valid for a notice of type `"+string(db.FrNoticeTypeTimed)+"`",
		)
		p.Require(
			end != nil,
			"endTime",
			"must exist and be valid for a notice of type `"+string(db.FrNoticeTypeTimed)+"`",
		)
	}

	p.Require(len(content) > 5, "content", "must be longer than 5 characters")

	return p
}

type CreateNoticeBody struct {
	Type      db.FrNoticeType `json:"type"`
	Content   string          `json:"content"`
	StartTime *time.Time      `json:"startTime"`
	EndTime   *time.Time      `json:"endTime"`
}

func (b CreateNoticeBody) Valid(ctx context.Context) util.Problems {
	return baseNoticeValidator(b.Type, b.Content, b.StartTime, b.EndTime)
}

// CreateNotice godoc
//
//	@Summary	Create a notice
//	@Tags		notices
//	@Accept		json
//	@Produce	json
//	@Security	BearerAuth
//	@Param		request	body		CreateNoticeBody	true	"notice to create"
//	@Success	201		{object}	db.FrNotice			"created notice"
//	@Header		201		{string}	Location			"URL of the created notice"
//	@Failure	400		{object}	util.ErrorResponse	"malformed body, or validation failed, see `problems`"
//	@Failure	403		{object}	util.ErrorResponse	"caller is not an admin"
//	@Router		/api/v1/notices [post]
func CreateNotice(logger *slog.Logger, pool *pgxpool.Pool) http.HandlerFunc {
	return util.HandleAuthed(func(r *http.Request, user *db.FrUser) (util.HttpResponse, error) {

		createNotice, err := util.DecodeValid[CreateNoticeBody](r)

		if err != nil {
			return util.HttpResponse{}, err
		}

		newNotice, err := db.InTxV(r.Context(), pool, func(q *db.Queries) (*db.FrNotice, error) {
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

		return *util.CreatedBody(r, newNotice, newNotice.ID), nil
	}, logger)
}

// DeleteNotice godoc
//
//	@Summary		Delete a notice
//	@Description	Idempotent: deleting a notice that does not exist answers 204 as well.
//	@Tags			notices
//	@Produce		json
//	@Security		BearerAuth
//	@Param			id	path	string	true	"notice id"	format(uuid)
//	@Success		204	"notice deleted, or did not exist"
//	@Failure		400	{object}	util.ErrorResponse	"malformed id"
//	@Failure		403	{object}	util.ErrorResponse	"caller is not an admin"
//	@Router			/api/v1/notices/{id} [delete]
func DeleteNotice(logger *slog.Logger, pool *pgxpool.Pool) http.HandlerFunc {
	return util.HandleAuthed(func(r *http.Request, user *db.FrUser) (util.HttpResponse, error) {

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
	Content   string     `json:"content"`
	StartTime *time.Time `json:"startTime"`
	EndTime   *time.Time `json:"endTime"`
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

// UpdateNotice godoc
//
//	@Summary		Update a notice
//	@Description	Replaces content and schedule of an existing notice. The notice type cannot be changed.
//	@Tags			notices
//	@Accept			json
//	@Produce		json
//	@Security		BearerAuth
//	@Param			id		path		string				true	"notice id"	format(uuid)
//	@Param			request	body		NoticeUpdateBody	true	"fields to update"
//	@Success		200		{object}	db.FrNotice			"updated notice"
//	@Failure		400		{object}	util.ErrorResponse	"malformed id or body, or validation failed, see `problems`"
//	@Failure		403		{object}	util.ErrorResponse	"caller is not an admin"
//	@Failure		404		{object}	util.ErrorResponse	"no notice with that id"
//	@Router			/api/v1/notices/{id} [patch]
func UpdateNotice(logger *slog.Logger, pool *pgxpool.Pool) http.HandlerFunc {
	return util.HandleAuthed(func(r *http.Request, user *db.FrUser) (util.HttpResponse, error) {

		updateNotice, err := util.DecodeValid[NoticeUpdateBody](r)

		id, err2 := util.GetIdPathParam(r)

		if err != nil || err2 != nil {
			return util.HttpResponse{}, util.ErrBadRequest
		}

		newUpdatedNotice, err := db.InTxV(r.Context(), pool, func(q *db.Queries) (*db.FrNotice, error) {
			return q.UpdateNotice(r.Context(), db.UpdateNoticeParams{
				ID:        id,
				Content:   updateNotice.Content,
				StartTime: updateNotice.StartTime,
				EndTime:   updateNotice.EndTime,
			})
		})

		if errors.Is(err, sql.ErrNoRows) {
			return util.HttpResponse{}, util.ErrNotFound.Msg(
				"%s",
				(&service.ErrEntityNotFound{Name: "Notice", ID: &id}).Error(),
			)
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

// GetNoticeById godoc
//
//	@Summary	Get a notice by id
//	@Tags		notices
//	@Produce	json
//	@Security	BearerAuth
//	@Param		id	path		string	true	"notice id"	format(uuid)
//	@Success	200	{object}	db.FrNotice
//	@Failure	400	{object}	util.ErrorResponse	"malformed id"
//	@Failure	404	{object}	util.ErrorResponse	"no notice with that id"
//	@Router		/api/v1/notices/{id} [get]
func GetNoticeById(logger *slog.Logger, pool *pgxpool.Pool) http.HandlerFunc {
	return util.HandleAuthed(func(r *http.Request, user *db.FrUser) (util.HttpResponse, error) {

		id, err := util.GetIdPathParam(r)

		if err != nil {
			return util.HttpResponse{}, util.ErrBadRequest
		}

		notice, err := db.InTxV(r.Context(), pool, func(q *db.Queries) (*db.FrNotice, error) {
			return q.GetNoticeById(r.Context(), id)
		})

		if errors.Is(err, sql.ErrNoRows) {
			return util.HttpResponse{}, util.ErrNotFound.Msg(
				"%s",
				(&service.ErrEntityNotFound{Name: "Notice", ID: &id}).Error(),
			)
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

// GetNotices godoc
//
//	@Summary	List all notices
//	@Tags		notices
//	@Produce	json
//	@Security	BearerAuth
//	@Success	200	{array}	db.FrNotice
//	@Router		/api/v1/notices [get]
func GetNotices(logger *slog.Logger, pool *pgxpool.Pool) http.HandlerFunc {
	return util.HandleAuthed(func(r *http.Request, user *db.FrUser) (util.HttpResponse, error) {

		notices, err := db.InTxV(r.Context(), pool, func(q *db.Queries) ([]*db.FrNotice, error) {
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
