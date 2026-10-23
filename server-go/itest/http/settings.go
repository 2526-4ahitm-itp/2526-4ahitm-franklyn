package http

import (
	"net/http"
	"testing"

	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/db"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/http/handlers"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/itest/util"
)

func TestSettings(t *testing.T, tcc *util.TestContextContainer) {
	t.Cleanup(func() { util.TruncateAll(t, tcc) })

	t.Run("unprovisioned settings returns 404", func(t *testing.T) {

		e := util.NewE(t, tcc.BaseURL, tcc.KcTeacherAdminToken)

		res := e.GET("/api/v1/settings").
			Expect().
			Status(http.StatusNotFound)

		obj := res.JSON().Object()
		obj.Value("status").Number().IsEqual(http.StatusNotFound)
		obj.Value("message").String().IsEqual("Settings not provisioned yet")
	})

	t.Run("set settings works", func(t *testing.T) {

		e := util.NewE(t, tcc.BaseURL, tcc.KcTeacherAdminToken)

		res := e.POST("/api/v1/settings").
			WithJSON(handlers.UserSettingsBody{
				Language: "de",
				Theme:    db.FrSettingsThemeDark,
			}).
			Expect().
			Status(http.StatusOK)

		obj := res.JSON().Object()

		obj.Value("theme").String().IsEqual(string(db.FrSettingsThemeDark))
		obj.Value("language").String().IsEqual("de")
	})

	t.Run("settings get after set", func(t *testing.T) {

		e := util.NewE(t, tcc.BaseURL, tcc.KcTeacherAdminToken)

		_ = e.POST("/api/v1/settings").
			WithJSON(handlers.UserSettingsBody{
				Theme:    db.FrSettingsThemeLight,
				Language: "en",
			}).
			Expect().
			Status(http.StatusOK)

		res := e.GET("/api/v1/settings").
			Expect().
			Status(http.StatusOK)

		obj := res.JSON().Object()
		obj.Value("theme").String().IsEqual(string(db.FrSettingsThemeLight))
		obj.Value("language").String().IsEqual("en")
	})
}
