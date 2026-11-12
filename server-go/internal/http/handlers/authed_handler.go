package handlers

import (
	"log/slog"
	"net/http"

	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/config"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/db"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/http/middlewares"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/http/util"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/service"
	"github.com/jackc/pgx/v5/pgxpool"
)

func HandleThis(logger *slog.Logger, pool *pgxpool.Pool, cfg *config.Config) http.HandlerFunc {
	return util.Handle(func(r *http.Request) (util.HttpResponse, error) {
		user, err := middlewares.GetJwtUser(r.Context())

		if err != nil {
			return util.HttpResponse{}, err
		}

		provisionedUser, err := db.InTxV(r.Context(), pool, func(q *db.Queries) (db.FrUser, error) {
			return service.PersistedUser(r.Context(), q, user, cfg)
		})

		if err != nil {
			return util.HttpResponse{}, err
		}

		return util.HttpResponse{
			Status: http.StatusOK,
			Body:   provisionedUser,
		}, nil
	}, logger)
}
