package http

import (
	"log/slog"
	"net/http"

	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/http/handlers"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/http/middlewares"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/infrastructure"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/store"
)

func NewServer(
	logger *slog.Logger,
	cfg *infrastructure.Config,
	store *store.Queries,
) http.Handler {
	mux := http.NewServeMux()

	addRoutes(
		mux,
		logger,
	)

	var handler http.Handler = mux

	handler = middlewares.FiftyFifty(handler)

	return handler
}

func addRoutes(mux *http.ServeMux, logger *slog.Logger) {

	logger.Info("Adding routes")

	mux.Handle("/test", handlers.HandleTest())
}
