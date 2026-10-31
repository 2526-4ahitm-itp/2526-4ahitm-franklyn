package handlers

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"log/slog"
	"net/http"

	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/config"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/db"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/http/middlewares"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/http/util"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/service"
	"github.com/jackc/pgx/v5/pgxpool"
)

func GetUserSettings(logger *slog.Logger, pool *pgxpool.Pool, cfg *config.Config) http.HandlerFunc {
	return util.Handle(func(r *http.Request) (util.HttpResponse, error) {

		idToken, ok := middlewares.GetJwtUser(r.Context())

		if !ok {
			return util.HttpResponse{}, errors.New("failed to get jwt user")
		}

		settings, err := db.InTxV(r.Context(), pool, func(q *db.Queries) (db.FrSetting, error) {
			user, err := service.PersistedUser(r.Context(), q, idToken, cfg)

			if err != nil {
				return db.FrSetting{}, err
			}

			return q.GetUserSettings(r.Context(), user.ID)
		})

		if errors.Is(err, sql.ErrNoRows) {
			return util.HttpResponse{}, util.ErrNotFound.Msg("Settings not provisioned yet")
		}

		if err != nil {
			return util.HttpResponse{}, err
		}

		return util.HttpResponse{
			Status: http.StatusOK,
			Body: UserSettingsBody{
				Theme:    settings.Theme,
				Language: settings.Language,
			},
		}, nil
	}, logger)
}

type UserSettingsBody struct {
	Language string             `json:"language"`
	Theme    db.FrSettingsTheme `json:"theme"`
}

func (usb UserSettingsBody) Valid(ctx context.Context) util.Problems {
	p := util.Problems{}
	p.Require(
		usb.Theme == db.FrSettingsThemeDark ||
			usb.Theme == db.FrSettingsThemeLight ||
			usb.Theme == db.FrSettingsThemeSystem,
		"theme", fmt.Sprintf("must be one of %s, %s, %s",
			db.FrSettingsThemeDark,
			db.FrSettingsThemeLight,
			db.FrSettingsThemeSystem),
	)
	p.Require(usb.Language != "", "language", "must be valid")
	return p
}

func SetUserSettings(logger *slog.Logger, pool *pgxpool.Pool, cfg *config.Config) http.HandlerFunc {
	return util.Handle(func(r *http.Request) (util.HttpResponse, error) {
		idToken, ok := middlewares.GetJwtUser(r.Context())

		if !ok {
			return util.HttpResponse{}, errors.New("failed to get jwt user")
		}

		settingsBody, err := util.DecodeValid[UserSettingsBody](r)

		if err != nil {
			return util.HttpResponse{}, err
		}

		settings, err := db.InTxV(r.Context(), pool, func(q *db.Queries) (db.FrSetting, error) {
			user, err := service.PersistedUser(r.Context(), q, idToken, cfg)

			if err != nil {
				return db.FrSetting{}, err
			}

			return q.ProvisionSettings(r.Context(), db.ProvisionSettingsParams{
				UserID:   user.ID,
				Theme:    settingsBody.Theme,
				Language: settingsBody.Language,
			})
		})

		if err != nil {
			return util.HttpResponse{}, err
		}

		return util.HttpResponse{
			Status: http.StatusOK,
			Body: UserSettingsBody{
				Theme:    settings.Theme,
				Language: settings.Language,
			},
		}, nil
	}, logger)
}
