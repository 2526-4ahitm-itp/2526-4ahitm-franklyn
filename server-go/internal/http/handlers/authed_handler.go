package handlers

import (
	"errors"
	"log/slog"
	"net/http"

	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/config"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/db"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/http/middlewares"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/http/util"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/service"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

func HandleThis(logger *slog.Logger, pool *pgxpool.Pool, cfg *config.Config) http.HandlerFunc {
	return util.Handle(func(r *http.Request) (util.HttpResponse, error) {
		user, ok := middlewares.GetJwtUser(r.Context())

		if !ok {
			return util.HttpResponse{}, errors.New("jwt user missing from context")
		}
		ourUser, err := service.JwtUser(user, cfg)

		if err != nil {
			return util.HttpResponse{}, errors.New("jwt user failed to service")
		}

		provisionedUser, err := db.InTxV(r.Context(), pool, func(q *db.Queries) (db.FrUser, error) {
			return service.PersistedUser(r.Context(), q, user, cfg)
		})

		if err != nil {
			return util.HttpResponse{}, err
		}

		u, _ := uuid.Parse("fdf28df2-5348-4970-9c49-2b0f8840fd76")

		someUser, err := db.InTxV(r.Context(), pool, func(q *db.Queries) (db.FrUser, error) {
			return q.FindUserByID(r.Context(), u)
		})

		return util.HttpResponse{
			Status: http.StatusOK,
			Body: map[string]any{
				"ourUser":         ourUser,
				"provisionedUser": provisionedUser,
				"user":            someUser,
			},
		}, nil
	}, logger)
}
