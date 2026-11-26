package main

import (
	"context"
	_ "embed"
	"fmt"
	"io"
	"log/slog"
	"math"
	"math/rand/v2"
	"net"
	"net/http"
	"os"
	"os/signal"
	"strconv"
	"strings"
	"syscall"
	"time"

	"charm.land/log/v2"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/docs"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/config"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/db"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/rpc"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/service"
	"github.com/jackc/pgx/v5/pgxpool"
	"golang.org/x/sync/errgroup"
)

// //go:embed banner-red-nologo.txt
// var bannerRedNoLogo string
//
// //go:embed banner-neutral.txt
// var bannerNeutral string
//
// //go:embed banner-neutral-nologo.txt
// var bannerNeutralNoLogo string

//go:embed banner-red.txt
var bannerRed string

// //go:embed banner-green.txt
// var bannerGreen string
//
// //go:embed banner-magenta.txt
// var bannerMagenta string

func run(ctx context.Context, w io.Writer, args []string, cfg *config.Config) error {

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

	logger.Info(fmt.Sprintf("Franklyn (%s) is starting...", config.Version))
	if cfg.Dev {
		logger.Warn("FRANKLYN IS IN DEVELOPMENT MODE! DO NOT HOST FRANKLYN IN DEV MODE!")
		logger.Warn("FRANKLYN IS IN DEVELOPMENT MODE! DO NOT HOST FRANKLYN IN DEV MODE!")
		logger.Warn("FRANKLYN IS IN DEVELOPMENT MODE! DO NOT HOST FRANKLYN IN DEV MODE!")
	}

	docs.SwaggerInfo.Version = config.Version
	docs.SwaggerInfo.Host = net.JoinHostPort(cfg.Host, strconv.Itoa(cfg.Port))

	g, gctx := errgroup.WithContext(ctx)
	var pool *pgxpool.Pool
	var oidc *service.OIDC

	logger.Info("Starting to acquire resources...")

	g.Go(func() (err error) {
		pool, err = createResourceWithBackoff(
			gctx,
			"postgres",
			fmt.Sprintf("%s:%d", cfg.DBHost, cfg.DBPort),
			logger.WithGroup("db"),
			120,
			10,
			func(ctx context.Context) (*pgxpool.Pool, error) {
				return db.CreatePool(ctx, logger.WithGroup("db"), cfg)
			},
		)
		return
	})

	g.Go(func() (err error) {
		oidc, err = createResourceWithBackoff(
			gctx,
			"keycloak",
			cfg.KCProviderURL,
			logger.WithGroup("oidc"),
			120,
			10,
			func(ctx context.Context) (*service.OIDC, error) {
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
			"Database", pool != nil,
			"keycloak", oidc != nil,
		)

		return err
	}

	defer pool.Close()

	logger.Info("All resources acquired. Now starting...")

	queries := db.New(pool)

	var httpLog = slog.NewLogLogger(
		logger.WithGroup("serve").Handler(),
		slog.LevelInfo,
	)

	// srv := myhttp.NewServer(logger.WithGroup("http"), cfg, queries, pool, oidc)
	srv, p := rpc.NewServer(logger.WithGroup("rpc"), cfg, queries, pool, oidc)

	httpServer := &http.Server{
		Addr:      net.JoinHostPort(cfg.Host, strconv.Itoa(cfg.Port)),
		Handler:   srv,
		ErrorLog:  httpLog,
		Protocols: p,
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
	resourceName string,
	address string,
	logger *slog.Logger,
	maxSeconds float64,
	maxTries int,
	constructor func(ctx context.Context) (T, error),
) (T, error) {

	logger = logger.WithGroup("resource")
	logger.InfoContext(
		ctx,
		fmt.Sprintf("connecting to %s...", resourceName),
		"address",
		address,
	)

	var err error
	var resource T

	backoff := 2.0

	for tries := 1; tries <= maxTries; tries++ {
		resource, err = constructor(ctx)
		rand := rand.Float64()/20.0 + 0.9

		retryIn := time.Duration(math.Round(backoff*rand*10)) * time.Second / 10

		if err != nil {
			backoff = math.Min(backoff*1.6, maxSeconds)

			if tries > 1 {
				level := slog.LevelInfo
				if tries > 4 {
					level = slog.LevelWarn
				}

				lines := strings.Split(strings.TrimSpace(err.Error()), "\n")
				lastLine := strings.TrimSpace(lines[len(lines)-1])

				logger.Log(ctx,
					level,
					fmt.Sprintf("connecting to %s...\t", resourceName),
					"tries", tries,
					"retry_in", retryIn,
					"error", lastLine,
				)
			}

			select {
			case <-time.After(retryIn):
			case <-ctx.Done():
				return resource, ctx.Err()
			}

		} else {
			return resource, err
		}
	}

	return resource, fmt.Errorf(
		"failed to acquire %s: failed all %d tries",
		resourceName,
		maxTries,
	)
}

//	@title			Franklyn Server
//	@description	Student monitoring system
//	@description
//	@description	Every endpoint except `/health` requires a bearer token; a missing or invalid one answers 401 with an `ErrorResponse`.

//	@contact.name	Franklyn Team
//	@contact.email	franklyn@htl-leonding.ac.at

//	@license.name	MIT
//	@license.url	https://mit-license.org/

//	@BasePath	/

//	@securityDefinitions.apikey	BearerAuth
//	@in							header
//	@name						Authorization
//	@description				`Bearer <token>`.

// @externalDocs.description	FranklynAPI
// @externalDocs.url			https://franklyn.htl-leonding.ac.at/docs/TODO
func main() {
	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	log.Info("Loading config...")
	cfg, err := config.LoadConfig()
	if err != nil {
		log.Fatalf(
			"Loading configuration failed:\n%s\n\n"+
				"If you have issues configuring Franklyn then check out the docs at "+
				"https://franklyn.htl-leonding.ac.at/en/guide/self-host/environment-variables/"+
				"\nExiting now...",
			strings.ReplaceAll(err.Error(), ";", "\n"),
		)
	}
	defer cancel()
	if err := run(ctx, os.Stdout, os.Args, &cfg); err != nil {
		fmt.Fprintf(os.Stderr, "%s\n", err)
		os.Exit(1)
	}
}
