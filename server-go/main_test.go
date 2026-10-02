package main

import (
	"context"
	"fmt"
	"log/slog"
	"net"
	"net/http"
	"os"
	"strconv"
	"testing"
	"time"

	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/config"
)

func TestMain(t *testing.T) {
	ctx := context.Background()
	ctx, cancel := context.WithCancel(ctx)
	t.Cleanup(cancel)

	port, err := getFreePort()

	if err != nil {
		t.Error("Could not get a free port, trying :8081")
		port = 8081
	}

	cfg := config.Config{
		DBUsername: "app",
		DBPassword: "app",
		DBHost:     "localhost",
		DBPort:     5432,
		DBDatabase: "db",

		KCClientId:    "server",
		KCProviderURL: "http://localhost:7070/realms/franklyn",

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

func getFreePort() (port int, err error) {
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
