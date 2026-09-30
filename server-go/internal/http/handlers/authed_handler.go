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
	return util.Handle(func(w http.ResponseWriter, r *http.Request) error {
		user, ok := middlewares.GetJwtUser(r.Context())

		if !ok {
			return errors.New("Failed to get jwt user from context")
		}

		util.Encode(w, r, http.StatusOK, *user)

		return nil
	}, logger)
}
