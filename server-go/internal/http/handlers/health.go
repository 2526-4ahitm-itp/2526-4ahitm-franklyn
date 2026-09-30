package handlers

import (
	"encoding/json"
	"log/slog"
	"net/http"

	"github.com/jackc/pgx/v5/pgxpool"
)

type HealthResponse struct {
	Status string `json:"status"`
}

const (
	StatusPassing = "pass"
	StatusError   = "fail"
)

func HandleHealth(logger *slog.Logger, pool *pgxpool.Pool) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		err := pool.Ping(r.Context())

		enc := json.NewEncoder(w)

		w.Header().Set("Content-Type", "application/health+json")
		if err != nil {
			logger.Error("Healthcheck database ping failed", "error", err)
			w.WriteHeader(http.StatusInternalServerError)
			enc.Encode(HealthResponse{
				Status: StatusError,
			})
		} else {
			w.WriteHeader(http.StatusOK)
			enc.Encode(HealthResponse{
				Status: StatusPassing,
			})
		}
	}
}
