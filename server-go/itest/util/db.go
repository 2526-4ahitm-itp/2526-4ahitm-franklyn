package util

import (
	"context"
	"strconv"
	"testing"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/testcontainers/testcontainers-go"
	"github.com/testcontainers/testcontainers-go/wait"
)

func CreatePostgres(t *testing.T, ctx context.Context) (*pgxpool.Pool, int, func(), error) {
	postgresC, err := testcontainers.Run(
		ctx, "postgres:18-alpine",
		testcontainers.WithExposedPorts("5432/tcp"),
		testcontainers.WithEnv(map[string]string{
			"POSTGRES_DB":       "db",
			"POSTGRES_USER":     "app",
			"POSTGRES_PASSWORD": "app",
		}),
		testcontainers.WithWaitStrategy(
			wait.ForListeningPort("5432/tcp"),
			wait.ForLog("database system is ready to accept connections").
				WithOccurrence(2),
		),
	)

	if err != nil {
		return nil, 0, nil, err
	}

	mapped, err := postgresC.MappedPort(ctx, "5432/tcp")

	if err != nil {
		return nil, 0, nil, err
	}

	pool, err := createPool(ctx, int(mapped.Num()))

	if err != nil {
		return nil, 0, nil, err
	}

	return pool, int(mapped.Num()), func() {
		pool.Close()
		testcontainers.CleanupContainer(t, postgresC)
	}, nil
}

func createPool(ctx context.Context, dbPort int) (*pgxpool.Pool, error) {

	pool, err := pgxpool.New(
		ctx,
		"postgres://app:app@localhost:"+strconv.Itoa(dbPort)+"/db",
	)

	if err != nil {
		return nil, err
	}

	err = pool.Ping(ctx)

	if err != nil {
		return nil, err
	}

	return pool, nil
}
