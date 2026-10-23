package http

import (
	"net/http"
	"testing"

	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/db"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/itest/util"
)

func TestAuth(t *testing.T, tcc *util.TestContextContainer) {
	t.Cleanup(func() { util.TruncateAll(t, tcc) })

	cases := []struct {
		name     string
		token    string
		username string
		role     db.FrUserType
	}{
		{"student", tcc.KcStudentToken, "it123456", db.FrUserTypeSTUDENT},
		{"teacher", tcc.KcTeacherToken, "e.musterfrau", db.FrUserTypeTEACHER},
		{"student admin", tcc.KcStudentAdminToken, "if123456", db.FrUserTypeSTUDENT},
		{"teacher admin", tcc.KcTeacherAdminToken, "l.born", db.FrUserTypeTEACHER},
	}

	for _, c := range cases {
		t.Run(c.name+" token authenticates", func(t *testing.T) {

			e := util.NewE(t, tcc.BaseURL, c.token)

			res := e.GET("/api/v1/auth").
				Expect().
				Status(http.StatusOK)

			obj := res.JSON().Object()
			obj.Value("preferredUsername").String().IsEqual(c.username)
			obj.Value("role").String().IsEqual(string(c.role))
			obj.Value("id").String().NotEmpty()
		})
	}

	t.Run("no token is rejected", func(t *testing.T) {

		e := util.NewE(t, tcc.BaseURL, "")

		e.GET("/api/v1/auth").
			Expect().
			Status(http.StatusUnauthorized)
	})
}
