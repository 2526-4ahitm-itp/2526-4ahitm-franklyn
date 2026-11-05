package db

import (
	"context"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

func InTx(ctx context.Context, pool *pgxpool.Pool, fn func(*Queries) error) error {
	return pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
		return fn(New(tx))
	})
}

func InTxV[T any](ctx context.Context, pool *pgxpool.Pool, fn func(*Queries) (T, error)) (T, error) {
	var val T

	err := pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
		var err error
		val, err = fn(New(tx))
		if err != nil {
			return err
		}
		return nil
	})

	if err != nil {
		return val, err
	}

	return val, nil
}
