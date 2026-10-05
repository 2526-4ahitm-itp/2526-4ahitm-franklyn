package config

import (
	"log/slog"

	"github.com/caarlos0/env/v11"
	"github.com/joho/godotenv"
)

type Config struct {
	DBUsername string `env:"DB_USERNAME,required,notEmpty"`
	DBPassword string `env:"DB_PASSWORD,required,notEmpty"`
	DBHost     string `env:"DB_HOST,required,notEmpty"`
	DBPort     int    `env:"DB_PORT" envDefault:"5432"`
	DBDatabase string `env:"DB_DATABASE,required,notEmpty"`

	KCClientId    string `env:"KC_CLIENT_ID" envDefault:"server"`
	KCProviderURL string `env:"KC_PROVIDER_URL,required,notEmpty"`

	Host string `env:"HOST" envDefault:"localhost"`
	Port int    `env:"PORT" envDefault:"8080"`

	LogLevel slog.Level `env:"LOG_LEVEL" envDefault:"warn"`

	RoleClaim          string `env:"ROLE_CLAIM,required,notEmpty"`
	RoleClaimSeparator string `env:"ROLE_CLAIM_SEPARATOR,required,notEmpty"`
	RoleTeacher        string `env:"ROLE_TEACHER,required,notEmpty"`
	RoleStudent        string `env:"ROLE_STUDENT,required,notEmpty"`
}

func LoadConfig() (Config, error) {
	_ = godotenv.Load(".env.dev")
	config, err := env.ParseAsWithOptions[Config](env.Options{Prefix: "FRANKLYN_"})

	if err != nil {
		return Config{}, err
	}

	return config, nil
}
