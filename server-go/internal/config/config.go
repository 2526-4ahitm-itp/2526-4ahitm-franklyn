package config

import (
	"log/slog"

	"github.com/caarlos0/env/v11"
	"github.com/joho/godotenv"
)

type Config struct {
	DBUsername string `env:"DB_USERNAME"`
	DBPassword string `env:"DB_PASSWORD"`
	DBHost     string `env:"DB_HOST"`
	DBPort     int    `env:"DB_PORT"`
	DBDatabase string `env:"DB_DATABASE"`

	KCClientId    string `env:"KC_CLIENT_ID"`
	KCProviderURL string `env:"KC_PROVIDER_URL"`

	Host string `env:"HOST"`
	Port int    `env:"PORT"`

	LogLevel slog.Level `env:"LOG_LEVEL"`
}

func LoadConfig() (Config, error) {
	_ = godotenv.Load(".env.dev")
	return env.ParseAsWithOptions[Config](env.Options{Prefix: "FRANKLYN_"})
}
