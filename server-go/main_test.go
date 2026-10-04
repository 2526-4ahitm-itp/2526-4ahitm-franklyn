package main

import (
	"context"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"strconv"
	"testing"
	"time"

	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/config"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/itest/util"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

type TestContextContainer struct {
	KcStudentToken      string
	KcTeacherToken      string
	KcStudentAdminToken string
	KcTeacherAdminToken string

	Pool     *pgxpool.Pool
	Provider *util.KCProvider
	Context  context.Context
}

func TestMain(t *testing.T) {
	ctx := context.Background()
	ctx, cancel := context.WithCancel(ctx)
	t.Cleanup(cancel)

	port, err := util.GetFreePort()

	if err != nil {
		t.Error("Could not get a free port, trying :8081")
		port = 8081
	}

	provider, err := util.CreateProvider(ctx)

	if err != nil {
		t.Fatal("Failed to create provider", err)
	}

	pool, dbPort, cleanup, err := util.CreatePostgres(t, ctx)
	if err != nil {
		t.Fatal("Postgres creation failed", err)
	}

	defer cleanup()

	student := provider.Token(map[string]any{
		"sub":                uuid.New().String(),
		"name":               "Max Mustermann",
		"given_name":         "Max",
		"preferred_username": "it123456",
		"family_name":        "Mustermann",
		"email":              "m.mustermann@students.htl-leonding.ac.at",
		"distinguished_name": "CN=it123456,CN=Max Mustermann,OU=Stundents," +
			"OU=HTL,DC=HTL-LEONDING,DC=AC,DC=AT",
	})

	teacher := provider.Token(map[string]any{
		"sub":                uuid.New().String(),
		"preferred_username": "e.musterfrau",
		"email":              "e.musterfrau@htl-leonding.ac.at",
		"distinguished_name": "CN=e.mustermann,CN=Erika Musterfrau,OU=Teachers" +
			",OU=HTL,DC=HTL-LEONDING,DC=AC,DC=AT",
	})

	studentAdmin := provider.Token(map[string]any{
		"sub":                uuid.New().String(),
		"name":               "Franz Fröhlich",
		"given_name":         "Franz",
		"preferred_username": "if123456",
		"family_name":        "Fröhlich",
		"email":              "f.fröhlich@students.htl-leonding.ac.at",
		"distinguished_name": "CN=if123456,CN=Franz Fröhlich,OU=Stundents," +
			"OU=HTL,DC=HTL-LEONDING,DC=AC,DC=AT",
		"realm_access": map[string]any{"roles": []string{"franklyn-admin"}},
	})

	teacherAdmin := provider.Token(map[string]any{
		"sub":                uuid.New().String(),
		"name":               "Lilli Born",
		"given_name":         "Lilli",
		"preferred_username": "l.born",
		"family_name":        "Born",
		"email":              "l.born@htl-leonding.ac.at",
		"distinguished_name": "CN=l.born,CN=Lilli Born,OU=Teachers," +
			"OU=HTL,DC=HTL-LEONDING,DC=AC,DC=AT",
		"realm_access": map[string]any{"roles": []string{"franklyn-admin"}},
	})

	_ = TestContextContainer{
		KcTeacherToken:      teacher,
		KcStudentToken:      student,
		KcStudentAdminToken: studentAdmin,
		KcTeacherAdminToken: teacherAdmin,
		Provider:            &provider,
		Pool:                pool,
		Context:             ctx,
	}

	defer provider.Server.Close()

	cfg := config.Config{
		DBUsername: "app",
		DBPassword: "app",
		DBHost:     "localhost",
		DBPort:     dbPort,
		DBDatabase: "db",

		KCClientId:    "server",
		KCProviderURL: provider.Server.URL,

		Host: "localhost",
		Port: port,

		LogLevel: slog.LevelDebug,
	}

	go run(ctx, os.Stdout, os.Args, cfg)

	err = waitForReady(
		ctx,
		time.Duration(60*time.Second),
		"http://"+cfg.Host+":"+strconv.Itoa(cfg.Port)+"/health",
	)

	if err != nil {
		t.Error("waitForReady failed with error", err)
	}
	t.Log("Done")
}

// waitForReady calls the specified endpoint until it gets a 200
// response or until the context is cancelled or the timeout is
// reached.
func waitForReady(
	ctx context.Context,
	timeout time.Duration,
	endpoint string,
) error {
	client := http.Client{}
	startTime := time.Now()
	for {
		req, err := http.NewRequestWithContext(
			ctx,
			http.MethodGet,
			endpoint,
			nil,
		)
		if err != nil {
			return fmt.Errorf("failed to create request: %w", err)
		}

		resp, err := client.Do(req)
		if err != nil {
			fmt.Printf("Error making request: %s\n", err.Error())
			time.Sleep(time.Duration(200 * time.Millisecond))
			continue
		}
		if resp.StatusCode == http.StatusOK {
			fmt.Println("Endpoint is ready!")
			resp.Body.Close()
			return nil
		}
		resp.Body.Close()

		select {
		case <-ctx.Done():
			return ctx.Err()
		default:
			if time.Since(startTime) >= timeout {
				return fmt.Errorf("timeout reached while waiting for endpoint")
			}
			// wait a little while between checks
			time.Sleep(250 * time.Millisecond)
		}
	}
}
