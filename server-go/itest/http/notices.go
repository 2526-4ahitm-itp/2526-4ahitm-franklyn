package http

import (
	"net/http"
	"testing"

	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/db"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/itest/util"
	"github.com/gavv/httpexpect/v2"
)

func TestNotices(t *testing.T, tcc *util.TestContextContainer) {
	t.Cleanup(func() { util.TruncateAll(t, tcc) })

	t.Run("create single notice", func(t *testing.T) {

		e := httpexpect.Default(t, tcc.BaseURL).
			Builder(func(r *httpexpect.Request) {
				r.WithHeader("Authorization", "Bearer "+tcc.KcTeacherAdminToken)
			})

		res := e.POST("/api/notices").
			WithJSON(map[string]any{
				"type":    db.FrNoticeTypeSingle,
				"content": "Schulschluss um 13:00",
			}).
			Expect().
			Status(http.StatusCreated)

		obj := res.JSON().Object()
		obj.Value("type").String().IsEqual(string(db.FrNoticeTypeSingle))
		obj.Value("content").String().IsEqual("Schulschluss um 12:00")

		id := obj.Value("id").String().NotEmpty().Raw()
		res.Header("Location").IsEqual("/api/notices/" + id)
	})
}
