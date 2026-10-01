package handlers

import (
	"database/sql"
	"errors"
	"log/slog"
	"net/http"

	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/db"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/http/util"
	"github.com/jackc/pgx/v5/pgxpool"
)

func CreateNotice(logger *slog.Logger, pool *pgxpool.Pool) http.HandlerFunc {
	return util.Handle(func(r *http.Request) (util.HttpResponse, error) {

		createNotice, err := util.Decode[db.CreateNoticeParams](r)

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
			return q.CreateNotice(r.Context(), createNotice)
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

func UpdateNotice(logger *slog.Logger, pool *pgxpool.Pool) http.HandlerFunc {
	return util.Handle(func(r *http.Request) (util.HttpResponse, error) {
		return util.HttpResponse{}, errors.New("Not yet implemented")
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
