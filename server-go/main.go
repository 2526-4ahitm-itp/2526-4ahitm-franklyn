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
	"golang.org/x/sync/errgroup"
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

func run(ctx context.Context, w io.Writer, args []string, cfg config.Config) error {

	fmt.Println(bannerRed)

	var options log.Options

	if cfg.LogLevel == slog.LevelDebug {
		options = log.Options{
			ReportTimestamp: true,
			ReportCaller:    true,
		}
	} else {
		options = log.Options{
			ReportTimestamp: true,
		}
	}

	charm := log.NewWithOptions(os.Stderr, options)

	logger := slog.New(charm)

	logger.Info("Franklyn is starting...")

	g, gctx := errgroup.WithContext(ctx)
	var pool *pgxpool.Pool
	var oidc service.OIDC

	logger.Info("Starting to acquire resources...")

	g.Go(func() (err error) {
		pool, err = createResourceWithBackoff(
			gctx,
			logger.WithGroup("db"),
			120,
			func(ctx context.Context) (*pgxpool.Pool, error) {
				return db.CreatePool(ctx, logger.WithGroup("db"), &cfg)
			},
		)
		return
	})

	g.Go(func() (err error) {
		oidc, err = createResourceWithBackoff(
			gctx,
			logger.WithGroup("oidc"),
			120,
			func(ctx context.Context) (service.OIDC, error) {
				return service.CreateOIDC(cfg, ctx)
			},
		)
		return
	})

	if err := g.Wait(); err != nil {
		if pool != nil {
			pool.Close()
		}

		logger.Error(
			"Failed to acquire one of the resources",
			"pool", pool != nil,
			"TokenVerifier", oidc.TokenVerifier != nil,
			"Provider", oidc.Provider != nil,
		)

		return err
	}

	defer pool.Close()

	logger.Info("All resources acquired. Now starting...")

	queries := db.New(pool)

	var httpLog *stdlog.Logger = slog.NewLogLogger(
		logger.WithGroup("serve").Handler(),
		slog.LevelInfo,
	)

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

func createResourceWithBackoff[T any](
	ctx context.Context,
	logger *slog.Logger,
	maxSeconds float64,
	constructor func(ctx context.Context) (T, error),
) (T, error) {

	logger = logger.WithGroup("resource")

	var err error
	var resource T

	backoff := 2.0

	for {
		resource, err = constructor(ctx)
		if err != nil {
			logger.Error(
				fmt.Sprintf(
					"Failed to connect to resource. Retrying in %.1f seconds.",
					backoff,
				),
				"err", err,
			)
			backoff = math.Min(backoff*1.6, maxSeconds)

			select {
			case <-time.After(time.Duration(backoff * float64(time.Second))):
			case <-ctx.Done():
				return resource, ctx.Err()
			}

			logger.Info("Trying to connect to resource...")
		} else {
			return resource, err
		}
	}
}

func main() {
	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	log.Info("Loading config...")
	cfg, err := config.LoadConfig()
	if err != nil {
		log.Fatal("Loading configuration failed. Exiting...")
	}
	defer cancel()
	if err := run(ctx, os.Stdout, os.Args, cfg); err != nil {
		fmt.Fprintf(os.Stderr, "%s\n", err)
		os.Exit(1)
	}
}
