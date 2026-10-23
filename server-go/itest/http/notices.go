package http

import (
	"fmt"
	"net/http"
	"testing"
	"time"

	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/db"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/http/handlers"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/itest/util"
)

func TestNotices(t *testing.T, tcc *util.TestContextContainer) {
	t.Cleanup(func() { util.TruncateAll(t, tcc) })

	t.Run("create single notice", func(t *testing.T) {

		e := util.NewE(t, tcc.BaseURL, tcc.KcTeacherAdminToken)

		res := e.POST("/api/v1/notices").
			WithJSON(map[string]any{
				"type":    db.FrNoticeTypeSingle,
				"content": "Schulschluss um 12:00",
			}).
			Expect().
			Status(http.StatusCreated)

		obj := res.JSON().Object()
		obj.Value("type").String().IsEqual(string(db.FrNoticeTypeSingle))
		obj.Value("content").String().IsEqual("Schulschluss um 12:00")

		id := obj.Value("id").String().NotEmpty().Raw()
		res.Header("Location").IsEqual("/api/v1/notices/" + id)
	})

	t.Run("create timed notice without start/end with 2 problems", func(t *testing.T) {

		e := util.NewE(t, tcc.BaseURL, tcc.KcTeacherAdminToken)

		res := e.POST("/api/v1/notices").
			WithJSON(map[string]any{
				"type":    db.FrNoticeTypeTimed,
				"content": "Some random content",
			}).
			Expect().
			Status(http.StatusBadRequest)

		obj := res.JSON().Object()

		obj.Value("status").Number().IsEqual(400)
		obj.Value("problems").Array().Length().IsEqual(2)

	})

	t.Run("update a notice", func(t *testing.T) {

		e := util.NewE(t, tcc.BaseURL, tcc.KcTeacherAdminToken)

		res1 := e.POST("/api/v1/notices").
			WithJSON(map[string]any{
				"type":      db.FrNoticeTypeTimed,
				"content":   "some other random content 2",
				"startTime": time.Now().UTC().Format(time.RFC3339),
				"endTime":   time.Now().Add(time.Hour).UTC().Format(time.RFC3339),
			}).
			Expect().
			Status(http.StatusCreated)

		obj := res1.JSON().Object()

		id := obj.Value("id").Raw()

		res := e.PATCH(fmt.Sprintf("/api/v1/notices/%s", id)).
			WithJSON(handlers.NoticeUpdateBody{
				Content: "some new content",
			}).
			Expect().
			Status(http.StatusOK)

		obj = res.JSON().Object()
		obj.Value("type").String().IsEqual("timed")
		obj.Value("content").String().IsEqual("some new content")
	})
}
