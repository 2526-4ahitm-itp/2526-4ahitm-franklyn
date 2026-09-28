package main

import (
	"context"
	_ "embed"
	"fmt"
	"io"
	"log/slog"
	"net"
	"net/http"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"

	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/db"
	myhttp "github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/http"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/infrastructure"
	"github.com/lmittmann/tint"
)

//go:embed banner.txt
var banner string

func run(ctx context.Context, w io.Writer, args []string) error {

	fmt.Println(banner)

	slog.Info("Loading config...")
	cfg, err := infrastructure.LoadConfig()

	if err != nil {
		slog.Error("Configuration failed to load")
		return err
	}

	logger := slog.New(tint.NewTextHandler(w, &tint.Options{
		Level:      cfg.LogLevel,
		TimeFormat: "2006/01/02 15:04:05",
	}))
	logger.Info("Franklyn is starting...")

	pool := infrastructure.CreatePool(ctx, logger, &cfg)
	defer pool.Close()

	queries := db.New(pool)

	srv := myhttp.NewServer(logger, &cfg, queries)

	httpServer := &http.Server{
		Addr:    net.JoinHostPort(cfg.Host, strconv.Itoa(cfg.Port)),
		Handler: srv,
	}

	srvErr := make(chan error, 1)
	go func() {
		logger.Info("Listening on " + httpServer.Addr)
		srvErr <- httpServer.ListenAndServe()
	}()

	select {
	case err := <-srvErr:
		return err // bind failed or server died
	case <-ctx.Done():
		shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()
		return httpServer.Shutdown(shutdownCtx)
	}
}

func main() {
	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer cancel()
	if err := run(ctx, os.Stdout, os.Args); err != nil {
		fmt.Fprintf(os.Stderr, "%s\n", err)
		os.Exit(1)
	}
}
