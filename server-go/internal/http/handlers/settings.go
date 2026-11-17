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

// GetUserSettings godoc
//
//	@Summary		Get the settings of the authenticated user
//	@Description	Settings are not created together with the user. Until they have been written once this answers 404 and the client falls back to its own defaults.
//	@Tags			settings
//	@Produce		json
//	@Security		BearerAuth
//	@Success		200	{object}	UserSettingsBody
//	@Failure		404	{object}	util.ErrorResponse	"settings not provisioned yet"
//	@Router			/api/v1/settings [get]
func GetUserSettings(logger *slog.Logger, pool *pgxpool.Pool, cfg *config.Config) http.HandlerFunc {
	return util.Handle(func(r *http.Request) (util.HttpResponse, error) {

		idToken, err := middlewares.GetJwtUser(r.Context())

		if err != nil {
			return util.HttpResponse{}, err
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

// SetUserSettings godoc
//
//	@Summary		Replace the settings of the authenticated user
//	@Description	Writes the full settings representation, creating it if it does not exist yet. Answers 200 in both cases.
//	@Tags			settings
//	@Accept			json
//	@Produce		json
//	@Security		BearerAuth
//	@Param			request	body		UserSettingsBody	true	"settings to store"
//	@Success		200		{object}	UserSettingsBody	"stored settings"
//	@Failure		400		{object}	util.ErrorResponse	"malformed body, or validation failed, see `problems`"
//	@Router			/api/v1/settings [put]
func SetUserSettings(logger *slog.Logger, pool *pgxpool.Pool, cfg *config.Config) http.HandlerFunc {
	return util.Handle(func(r *http.Request) (util.HttpResponse, error) {
		idToken, err := middlewares.GetJwtUser(r.Context())

		if err != nil {
			return util.HttpResponse{}, err
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
