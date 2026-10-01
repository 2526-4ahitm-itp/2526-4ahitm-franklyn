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
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/config"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/db"
	myhttp "github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/http"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/service"
	"github.com/jackc/pgx/v5/pgxpool"
)

//go:embed banner-red-nologo.txt
var bannerRedNoLogo string

//go:embed banner-neutral.txt
var bannerNeutral string

//go:embed banner-neutral-nologo.txt
var bannerNeutralNoLogo string

//go:embed banner-red.txt
var bannerRed string

//go:embed banner-green.txt
var bannerGreen string

//go:embed banner-magenta.txt
var bannerMagenta string

func run(ctx context.Context, w io.Writer, args []string) error {

	// fmt.Println(bannerRedNoLogo)
	// fmt.Println(bannerNeutralNoLogo)
	// fmt.Println(bannerNeutral)
	fmt.Println(bannerRed)
	// fmt.Println(bannerGreen)
	// fmt.Println(bannerMagenta)

	charm := log.NewWithOptions(os.Stderr, log.Options{ReportTimestamp: true})
	logger := slog.New(charm)

	logger.Info("Loading config...")
	cfg, err := config.LoadConfig()

	if err != nil {
		slog.Error("Configuration failed to load")
		return err
	}

	logger.Info("Franklyn is starting...")

	var pool *pgxpool.Pool = nil
	err = nil

	backoff := 2.0

	for pool == nil || err != nil {
		pool, err = db.CreatePool(ctx, logger.WithGroup("db"), &cfg)
		if err != nil || pool == nil {
			logger.Error(
				fmt.Sprintf(
					"Failed to connect to the database. Retrying in %.1f seconds.",
					backoff,
				),
			)
			backoff = math.Min(backoff*1.6, 120)

			select {
			case <-time.After(time.Duration(backoff * float64(time.Second))):
			case <-ctx.Done():
				return ctx.Err()
			}

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

	oidc, err := service.CreateOIDC(cfg, ctx)

	srv := myhttp.NewServer(logger.WithGroup("http"), &cfg, queries, pool, oidc)

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
