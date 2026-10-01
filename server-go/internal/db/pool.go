package db

import (
	"context"
	"database/sql"
	"embed"
	"fmt"
	stdlog "log"
	"log/slog"

	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/config"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/jackc/pgx/v5/stdlib"
	"github.com/pressly/goose/v3"
)

func CreatePool(ctx context.Context, logger *slog.Logger, cfg *config.Config) (*pgxpool.Pool, error) {
	pool, err := pgxpool.New(
		ctx,
		fmt.Sprintf("postgres://%s:%s@%s:%d/%s",
			cfg.DBUsername,
			cfg.DBPassword,
			cfg.DBHost,
			cfg.DBPort,
			cfg.DBDatabase,
		),
	)

	logger.Info("Created database pool")

	if err != nil {
		logger.Error("Failed to create pool")
		return nil, err
	}

	err = pool.Ping(ctx)

	if err != nil {
		logger.Error("Failed to ping the database")
		return nil, err
	}

	db := stdlib.OpenDBFromPool(pool)
	defer db.Close()

	err = setupDB(logger, db)

	if err != nil {
		return nil, err
	}

	return pool, nil
}

//go:embed migrations/*.sql
var embedMigrations embed.FS

func setupDB(logger *slog.Logger, db *sql.DB) error {

	var gooseLogger *stdlog.Logger = slog.NewLogLogger(
		logger.WithGroup("goose").Handler(),
		slog.LevelInfo,
	)
	goose.SetBaseFS(embedMigrations)
	goose.SetLogger(gooseLogger)

	if err := goose.SetDialect("postgres"); err != nil {
		return err
	}

	if err := goose.Up(db, "migrations"); err != nil {
		logger.Error("Goose migrations failed", "err", err)
		return err
	}

	return nil
}
