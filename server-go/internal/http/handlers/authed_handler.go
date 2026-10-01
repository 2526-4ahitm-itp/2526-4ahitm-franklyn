package handlers

import (
	"errors"
	"log/slog"
	"net/http"

	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/http/middlewares"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/http/util"
	"github.com/jackc/pgx/v5/pgxpool"
)

func HandleThis(logger *slog.Logger, pool *pgxpool.Pool) http.HandlerFunc {
	return util.Handle(func(r *http.Request) (util.HttpResponse, error) {
		user, ok := middlewares.GetJwtUser(r.Context())

		if !ok {
			return util.HttpResponse{}, errors.New("jwt user missing from context")
		}

		return util.HttpResponse{
			Status: http.StatusOK,
			Body:   user,
		}, nil
	}, logger)
}
