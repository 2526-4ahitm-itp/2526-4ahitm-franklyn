package http

import (
	"log/slog"
	"net/http"

	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/config"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/db"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/http/handlers"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/http/middlewares"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/service"
	"github.com/jackc/pgx/v5/pgxpool"
)

func NewServer(
	logger *slog.Logger,
	cfg *config.Config,
	store *db.Queries,
	pool *pgxpool.Pool,
	oidc service.OIDC,
) http.Handler {
	mux := http.NewServeMux()

	addRoutes(
		mux,
		logger.WithGroup("routes"),
		pool,
	)

	handlerLogger := logger.WithGroup("handler")

	var handler http.Handler = mux

	handler = middlewares.AuthRequired(handler, handlerLogger.WithGroup("auth"), oidc)
	return handler
}

func addRoutes(mux *http.ServeMux, logger *slog.Logger, pool *pgxpool.Pool) {

	logger.Info("Adding routes")

	mux.Handle("GET /health", handlers.HandleHealth(logger.WithGroup("health"), pool))
	mux.Handle("GET /api/v1/auth", handlers.HandleThis(logger.WithGroup("auth"), pool))

	mux.Handle("POST /api/v1/notices", handlers.CreateNotice(logger.WithGroup("notice"), pool))
	mux.Handle("PATCH /api/v1/notices/{id}", handlers.UpdateNotice(logger.WithGroup("notice"), pool))
	mux.Handle("GET /api/v1/notices/{id}", handlers.GetNoticeById(logger.WithGroup("notice"), pool))
	mux.Handle("GET /api/v1/notices", handlers.GetNotices(logger.WithGroup("notice"), pool))
	mux.Handle("DELETE /api/v1/notices/{id}", handlers.DeleteNotice(logger.WithGroup("notice"), pool))
}
