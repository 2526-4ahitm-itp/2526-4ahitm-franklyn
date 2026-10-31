package config

import (
	"log/slog"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestLoadConfig(t *testing.T) {

	minConfig := "FRANKLYN_DB_USERNAME=app" +
		"\nFRANKLYN_DB_PASSWORD=app" +
		"\nFRANKLYN_DB_HOST=localhost" +
		// "\nFRANKLYN_DB_PORT=5432" +
		"\nFRANKLYN_DB_DATABASE=db" +

		// "\nFRANKLYN_KC_CLIENT_ID=server" +
		"\nFRANKLYN_KC_PROVIDER_URL=http://localhost:7070/realms/franklyn" +

		// "\nFRANKLYN_HOST=localhost" +
		// "\nFRANKLYN_PORT=8080" +
		//
		// "\nFRANKLYN_LOG_LEVEL=debug" +

		"\nFRANKLYN_ROLE_CLAIM=distinguished_name" +
		"\nFRANKLYN_ROLE_CLAIM_SEPARATOR=," +
		"\nFRANKLYN_ROLE_TEACHER=OU=Teachers" +
		"\nFRANKLYN_ROLE_STUDENT=OU=Students"

	t.Run("load config with defaults", func(t *testing.T) {
		dir := t.TempDir()
		err := os.WriteFile(filepath.Join(dir, ".env.dev"), []byte(minConfig), 0o600)

		if err != nil {
			t.Fatal("Writing setup .env.dev file failed", err)
		}

		t.Chdir(dir)
		isolateEnv(t)
		cfg, err := LoadConfig()

		assert.Empty(t, err, "error should be null for successful load")
		assert.NotEmpty(t, cfg, "config should not be null")

		assert.Equal(t, cfg.DBPort, 5432, "DBPort defaults to 5432")
		assert.Equal(t, cfg.Host, "localhost", "Host defaults to localhost")
		assert.Equal(t, cfg.Port, 8080, "Port defaults to 8080")
		assert.Equal(t, cfg.LogLevel, slog.LevelWarn, "LogLevel defaults to warn")
	})

	t.Run("missing config fails", func(t *testing.T) {

		dir := t.TempDir()

		t.Chdir(dir)
		isolateEnv(t)
		cfg, err := LoadConfig()

		assert.Error(t, err, "missing configuration leads to an error")
		assert.Empty(t, cfg, "configuration should not load")
	})
}

func isolateEnv(t *testing.T) {
	for _, kv := range os.Environ() {
		if k, v, _ := strings.Cut(kv, "="); strings.HasPrefix(k, "FRANKLYN_") {
			t.Setenv(k, v)
			_ = os.Unsetenv(k)
		}
	}
}
