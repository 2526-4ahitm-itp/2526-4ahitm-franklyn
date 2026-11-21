package rpc

import (
	"encoding/json"
	"log/slog"
	"net/http"

	"connectrpc.com/connect/v2"
	"connectrpc.com/connect/v2/connecthttp"
	"connectrpc.com/grpcreflect/v2"
	"connectrpc.com/validate"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/config"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/db"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/proto/franklyn/exam/v1/examv1connect"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/rpc/handlers"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/rpc/middleware"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/service"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Server struct {
	*slog.Logger
	*db.Queries
	*pgxpool.Pool
	*service.OIDC
}

func NewServer(
	logger *slog.Logger,
	cfg *config.Config,
	q *db.Queries,
	pool *pgxpool.Pool,
	oidc *service.OIDC,
) (http.Handler, *http.Protocols) {

	server := connect.NewServer(
		validate.NewServerInterceptor(),
		middleware.NewAuthInterceptor(cfg, q, logger, oidc),
	)

	examv1connect.RegisterExamServiceHandler(server, handlers.NewExamService(logger, q, pool, cfg))

	if cfg.Dev {
		grpcreflect.Register(server)
	}

	mux := http.NewServeMux()
	connecthttp.Mount(mux, server)
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		err := pool.Ping(r.Context())

		enc := json.NewEncoder(w)

		w.Header().Set("Content-Type", "application/health+json")
		if err != nil {
			logger.Error("Healthcheck database ping failed", "error", err)
			w.WriteHeader(http.StatusInternalServerError)
			_ = enc.Encode(map[string]string{
				"status": "fail",
			})
		} else {
			w.WriteHeader(http.StatusOK)
			_ = enc.Encode(map[string]string{
				"status": "pass",
			})
		}
	})

	p := new(http.Protocols)
	p.SetHTTP1(true)
	p.SetUnencryptedHTTP2(true)
	return mux, p
}
