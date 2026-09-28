package infrastructure

import (
	"context"
	"database/sql"
	"embed"
	"fmt"
	"log/slog"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/jackc/pgx/v5/stdlib"
	"github.com/pressly/goose/v3"
)

func CreatePool(ctx context.Context, logger *slog.Logger, cfg *Config) *pgxpool.Pool {
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

	if err != nil {
		logger.Error("Failed to create pool")
		panic(err)
	}

	db := stdlib.OpenDBFromPool(pool)
	defer db.Close()

	setupDB(logger, db)

	return pool
}

//go:embed migrations/*.sql
var embedMigrations embed.FS

func setupDB(logger *slog.Logger, db *sql.DB) {

	goose.SetBaseFS(embedMigrations)

	if err := goose.SetDialect("postgres"); err != nil {
		panic(err)
	}

	if err := goose.Up(db, "migrations"); err != nil {
		logger.Error("Goose migrations failed", "err", err)
		panic(err)
	}
}
