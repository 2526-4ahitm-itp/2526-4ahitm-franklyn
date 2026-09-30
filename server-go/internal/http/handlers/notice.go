package handlers

import (
	"database/sql"
	"errors"
	"fmt"
	"log/slog"
	"net/http"

	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/db"
	"github.com/jackc/pgx/v5/pgxpool"
)

func CreateNotice(logger *slog.Logger, pool *pgxpool.Pool) http.HandlerFunc {
	return Handle(func(w http.ResponseWriter, r *http.Request) error {

		createNotice, err := decode[db.CreateNoticeParams](r)

		if err != nil {
			return err
		}

		if createNotice.Type == db.FrNoticeTypeTimed &&
			(!createNotice.StartTime.Valid || !createNotice.EndTime.Valid) {
			return encode(w, r, http.StatusUnprocessableEntity, ErrorResponse{
				Status:  http.StatusUnprocessableEntity,
				Message: `A "timed" notice must always have a "startTime" and "endTime"!`,
			})
		}

		newNotice, err := db.InTxV(r.Context(), pool, func(q *db.Queries) (db.FrNotice, error) {
			return q.CreateNotice(r.Context(), createNotice)
		})

		if err != nil {
			return err
		}

		w.Header().Set("Location", r.URL.Path+"/"+newNotice.ID.String())

		return encode(w, r, http.StatusCreated, newNotice)
	}, logger)
}

func DeleteNotice(logger *slog.Logger, pool *pgxpool.Pool) http.HandlerFunc {
	return Handle(func(w http.ResponseWriter, r *http.Request) error {

		id, err := getIdPathParam(r)

		if err != nil {
			return encode(w, r, http.StatusBadRequest, ErrorResponse{
				Status: http.StatusBadRequest,
			})
		}

		err = db.InTx(r.Context(), pool, func(q *db.Queries) error {
			return q.DeleteNotice(r.Context(), id)
		})

		if err != nil {
			return err
		}
		w.WriteHeader(http.StatusNoContent)
		return nil
	}, logger)
}

func UpdateNotice(logger *slog.Logger, pool *pgxpool.Pool) http.HandlerFunc {
	return Handle(func(w http.ResponseWriter, r *http.Request) error {
		return errors.New("Not yet implemented")
	}, logger)
}

func GetNoticeById(logger *slog.Logger, pool *pgxpool.Pool) http.HandlerFunc {
	return Handle(func(w http.ResponseWriter, r *http.Request) error {

		id, err := getIdPathParam(r)

		if err != nil {
			return encode(w, r, http.StatusBadRequest, ErrorResponse{
				Status: http.StatusBadRequest,
			})
		}

		notice, err := db.InTxV(r.Context(), pool, func(q *db.Queries) (db.FrNotice, error) {
			return q.GetNoticeById(r.Context(), id)
		})

		if errors.Is(err, sql.ErrNoRows) {
			return encode(w, r, http.StatusNotFound, ErrorResponse{
				Status:  http.StatusNotFound,
				Message: fmt.Sprintf(`Notice with id "%s" does not exist!`, id),
			})
		}

		if err != nil {
			return err
		}

		return encode(w, r, http.StatusOK, notice)
	}, logger)
}

func GetNotices(logger *slog.Logger, pool *pgxpool.Pool) http.HandlerFunc {
	return Handle(func(w http.ResponseWriter, r *http.Request) error {

		notices, err := db.InTxV(r.Context(), pool, func(q *db.Queries) ([]db.FrNotice, error) {
			return q.GetNotices(r.Context())
		})

		if err != nil {
			return err
		}

		return encode(w, r, http.StatusOK, notices)
	}, logger)
}
