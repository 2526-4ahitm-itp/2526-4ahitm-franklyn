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

	PinMin                    int16 `env:"PIN_MIN" envDefault:"1337"`
	PinMax                    int16 `env:"PIN_MAX" envDefault:"4200"`
	DefaultPreopenTimeMinutes int32 `env:"DEFAULT_PREOPEN_TIME_MINUTES" envDefault:"15"`

	Dev bool `env:"DEV" envDefault:"false"`

	StorageDir             string  `env:"STORAGE_DIR" envDefault:"/var/lib/franklyn"`
	StorageWarnPercent     float64 `env:"STORAGE_WARN_PERCENT" envDefault:"15"`
	StorageCriticalPercent float64 `env:"STORAGE_CRITICAL_PERCENT" envDefault:"5"`

	SMTPHost     string   `env:"SMTP_HOST"`
	SMTPPort     int      `env:"SMTP_PORT" envDefault:"587"`
	SMTPSecurity string   `env:"SMTP_SECURITY" envDefault:"starttls"`
	SMTPUsername string   `env:"SMTP_USERNAME"`
	SMTPPassword string   `env:"SMTP_PASSWORD"`
	SMTPFrom     string   `env:"SMTP_FROM"`
	AlertEmails  []string `env:"ALERT_EMAILS" envSeparator:","`
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
	if c.StorageCriticalPercent <= 0 || c.StorageCriticalPercent >= c.StorageWarnPercent || c.StorageWarnPercent >= 100 {
		e = append(e, fmt.Errorf(
			"\"FRANKLYN_STORAGE_CRITICAL_PERCENT\" (%g) and \"FRANKLYN_STORAGE_WARN_PERCENT\" (%g) must satisfy 0 < critical < warn < 100",
			c.StorageCriticalPercent,
			c.StorageWarnPercent,
		))
	}
	if c.SMTPSecurity != "none" && c.SMTPSecurity != "starttls" && c.SMTPSecurity != "tls" {
		e = append(e, fmt.Errorf(
			"\"FRANKLYN_SMTP_SECURITY\" (%s) must be one of `none`, `starttls`, `tls`",
			c.SMTPSecurity,
		))
	}
	if c.SMTPSecurity == "none" && c.SMTPUsername != "" {
		e = append(e, fmt.Errorf(
			"\"FRANKLYN_SMTP_USERNAME\" requires \"FRANKLYN_SMTP_SECURITY\" `starttls` or `tls`",
		))
	}
	if c.SMTPHost != "" && (c.SMTPFrom == "" || len(c.AlertEmails) == 0) {
		e = append(e, fmt.Errorf(
			"\"FRANKLYN_SMTP_HOST\" requires \"FRANKLYN_SMTP_FROM\" and \"FRANKLYN_ALERT_EMAILS\"",
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
