package util

import (
	"context"
	"net"
	"strings"
	"testing"

	"charm.land/log/v2"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/config"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/stretchr/testify/require"
)

func GetFreePort() (port int, err error) {
	var a *net.TCPAddr
	if a, err = net.ResolveTCPAddr("tcp", "localhost:0"); err == nil {
		var l *net.TCPListener
		if l, err = net.ListenTCP("tcp", a); err == nil {
			defer l.Close()
			return l.Addr().(*net.TCPAddr).Port, nil
		}
	}
	return
}

type TestContextContainer struct {
	KcStudentToken      string
	KcTeacherToken      string
	KcStudentAdminToken string
	KcTeacherAdminToken string

	Config config.Config

	Pool     *pgxpool.Pool
	Provider *KCProvider
	Context  context.Context
	L        *log.Logger

	BaseURL string
}

func TruncateAll(t *testing.T, tcc *TestContextContainer) {
	t.Helper()

	rows, err := tcc.Pool.Query(tcc.Context, `
              SELECT tablename FROM pg_tables
              WHERE schemaname = 'public' AND tablename <> 'goose_db_version'`)
	require.NoError(t, err)

	tables, err := pgx.CollectRows(rows, pgx.RowTo[string])
	require.NoError(t, err)
	if len(tables) == 0 {
		return
	}

	_, err = tcc.Pool.Exec(tcc.Context,
		`TRUNCATE `+strings.Join(tables, ", ")+` RESTART IDENTITY CASCADE`)
	require.NoError(t, err)
}
