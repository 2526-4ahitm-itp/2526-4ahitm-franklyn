package handlers

import (
	"log/slog"
	"net/http"

	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/config"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/db"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/http/util"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/service"
	"github.com/jackc/pgx/v5/pgxpool"
)

// HandleThis godoc
//
//	@Summary		Get the authenticated user
//	@Description	Returns the user the presented token belongs to.
//	@Description	As a side effect the user is provisioned from the token on first call. Manual provisioning is to be removed, after which this is a plain getter.
//	@Tags			auth
//	@Produce		json
//	@Security		BearerAuth
//	@Success		200	{object}	db.FrUser
//	@Router			/api/v1/auth [get]
func HandleThis(logger *slog.Logger, pool *pgxpool.Pool, cfg *config.Config) http.HandlerFunc {
	return util.HandleAuthed(func(r *http.Request, user db.FrUser) (util.HttpResponse, error) {
		idToken, err := util.GetJwtUser(r.Context())

		if err != nil {
			return util.HttpResponse{}, err
		}

		provisionedUser, err := db.InTxV(r.Context(), pool, func(q *db.Queries) (db.FrUser, error) {
			return service.PersistedUser(r.Context(), q, idToken, cfg)
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
