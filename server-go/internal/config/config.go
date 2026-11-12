package config

import (
	"fmt"
	"log/slog"

	"github.com/caarlos0/env/v11"
	"github.com/joho/godotenv"
)

// This is the version of the Go Server available at runtime.
var Version string = "0.0.0-dev.1"

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

	PinMin int16 `env:"PIN_MIN" envDefault:"1337"`
	PinMax int16 `env:"PIN_MAX" envDefault:"4200"`
}

func (c Config) validate() []error {
	e := []error{}

	if c.PinMin < 0 {
		e = append(e, fmt.Errorf(
			"\"FRANKLYN_PIN_MIN\" (%d) must be at least `0`",
			c.PinMin,
		))
	}
	if c.PinMax < 1 {
		e = append(e, fmt.Errorf(
			"\"FRANKLYN_PIN_MAX\" (%d) must be at least `1`",
			c.PinMax,
		))
	}
	if c.PinMin >= c.PinMax {
		e = append(e, fmt.Errorf(
			"\"FRANKLYN_PIN_MIN\" (%d) must be less than \"FRANKLYN_PIN_MAX\" (%d)",
			c.PinMin,
			c.PinMax,
		))
	}
	return e
}

func LoadConfig() (Config, error) {
	_ = godotenv.Load(".env.dev")
	config, err := env.ParseAsWithOptions[Config](env.Options{Prefix: "FRANKLYN_"})

	if err != nil {
		return Config{}, err
	}

	errors := config.validate()

	if len(errors) > 0 {
		return Config{}, env.AggregateError{
			Errors: errors,
		}
	}

	return config, nil
}
