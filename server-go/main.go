package main

import (
	"context"
	_ "embed"
	"fmt"
	"io"
	stdlog "log"
	"log/slog"
	"math"
	"net"
	"net/http"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"

	"charm.land/log/v2"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/db"
	myhttp "github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/http"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/infrastructure"
	"github.com/jackc/pgx/v5/pgxpool"
)

//go:embed banner.txt
var banner string

//go:embed banner2.txt
var banner2 string

func run(ctx context.Context, w io.Writer, args []string) error {
	fmt.Println(banner2)

	charm := log.NewWithOptions(os.Stderr, log.Options{ReportTimestamp: true})
	logger := slog.New(charm)

	logger.Info("Loading config...")
	cfg, err := infrastructure.LoadConfig()

	if err != nil {
		slog.Error("Configuration failed to load")
		return err
	}

	logger.Info("Franklyn is starting...")

	var pool *pgxpool.Pool = nil
	err = nil

	backoff := 2.0

	for pool == nil || err != nil {
		pool, err = infrastructure.CreatePool(ctx, logger.WithGroup("db"), &cfg)
		if err != nil || pool == nil {
			logger.Error(
				fmt.Sprintf(
					"Failed to connect to the database. Retrying in %.1f seconds.",
					backoff,
				),
			)
			backoff = math.Min(backoff*1.6, 120)

			time.Sleep(time.Duration(backoff * float64(time.Second)))
			logger.Info("Trying to reconnect to database...")
		}
	}
	defer pool.Close()

	logger.Info("Connected to Database!")

	queries := db.New(pool)

	var httpLog *stdlog.Logger = slog.NewLogLogger(
		logger.WithGroup("serve").Handler(),
		slog.LevelInfo,
	)

	srv := myhttp.NewServer(logger.WithGroup("http"), &cfg, queries, pool)

	httpServer := &http.Server{
		Addr:     net.JoinHostPort(cfg.Host, strconv.Itoa(cfg.Port)),
		Handler:  srv,
		ErrorLog: httpLog,
	}

	srvErr := make(chan error, 1)
	go func() {
		httpLog.Print("Listening on " + httpServer.Addr)
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
