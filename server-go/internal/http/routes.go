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
		cfg,
	)

	handlerLogger := logger.WithGroup("handler")

	var handler http.Handler = mux

	handler = middlewares.AuthRequired(handler, handlerLogger.WithGroup("auth"), oidc, cfg)
	return handler
}

func addRoutes(mux *http.ServeMux, logger *slog.Logger, pool *pgxpool.Pool, cfg *config.Config) {

	adminOnly := middlewares.CreateRequireRoles([]string{"franklyn-admin"})

	requireTeacher := middlewares.CreateRequireType(db.FrUserTypeTEACHER, logger)

	logger.Info("Adding routes")

	mux.Handle("GET /health", handlers.HandleHealth(logger.WithGroup("health"), pool))
	mux.Handle("GET /api/v1/auth", handlers.HandleThis(logger.WithGroup("auth"), pool, cfg))

	noticeLogger := logger.WithGroup("notice")

	mux.Handle("POST /api/v1/notices", adminOnly(handlers.CreateNotice(noticeLogger, pool)))

	mux.Handle("PATCH /api/v1/notices/{id}", adminOnly(handlers.UpdateNotice(noticeLogger, pool)))
	mux.Handle("GET /api/v1/notices/{id}", handlers.GetNoticeById(noticeLogger, pool))
	mux.Handle("GET /api/v1/notices", handlers.GetNotices(noticeLogger, pool))
	mux.Handle("DELETE /api/v1/notices/{id}", adminOnly(handlers.DeleteNotice(noticeLogger, pool)))

	settingsLogger := logger.WithGroup("settings")

	mux.Handle("GET /api/v1/settings", handlers.GetUserSettings(settingsLogger, pool, cfg))
	mux.Handle("POST /api/v1/settings", handlers.SetUserSettings(settingsLogger, pool, cfg))

	// exams
	examLogger := logger.WithGroup("exam")
	mux.Handle("GET /api/v1/exams/{id}", requireTeacher(handlers.GetExamById(examLogger, pool)))
	mux.Handle("POST /api/v1/exams", requireTeacher(handlers.CreateExam(examLogger, pool, cfg)))

}
