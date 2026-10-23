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

	t.Run("create notice with invalid type fails", func(t *testing.T) {
		e := util.NewE(t, tcc.BaseURL, tcc.KcTeacherAdminToken)

		res := e.POST("/api/v1/notices").
			WithJSON(map[string]any{
				"type":    "invalid-type",
				"content": "this is no content",
			}).
			Expect().
			Status(http.StatusBadRequest)

		obj := res.JSON().Object()

		obj.Value("status").Number().IsEqual(400)
		obj.Value("problems").Array().Length().IsEqual(1)
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

	t.Run("delete notice then notice is gone", func(t *testing.T) {
		e := util.NewE(t, tcc.BaseURL, tcc.KcTeacherAdminToken)

		resCreate := e.POST("/api/v1/notices").
			WithJSON(map[string]any{
				"type":    db.FrNoticeTypeSingle,
				"content": "Some random content",
			}).
			Expect().
			Status(http.StatusCreated)

		id := resCreate.JSON().Object().Value("id").Raw()

		_ = e.DELETE(fmt.Sprintf("/api/v1/notices/%s", id)).
			Expect().
			Status(http.StatusNoContent)

		resGetShouldFail := e.GET(fmt.Sprintf("/api/v1/notices/%s", id)).
			Expect().
			Status(http.StatusNotFound)

		obj := resGetShouldFail.JSON().Object()

		obj.Value("status").Number().IsEqual(http.StatusNotFound)
	})

	t.Run("create multiple notices then multiple notices", func(t *testing.T) {
		util.TruncateAll(t, tcc)
		e := util.NewE(t, tcc.BaseURL, tcc.KcTeacherAdminToken)

		notice1 := map[string]any{
			"type":      db.FrNoticeTypeTimed,
			"content":   "content of timed notice nr. 1",
			"startTime": "2026-10-20T09:16:12",
			"endTime":   "2026-10-10T13:45:33",
		}

		notice2 := map[string]any{
			"type":      db.FrNoticeTypeSingle,
			"content":   "content of single notice nr. 1",
			"startTime": nil,
			"endTime":   nil,
		}

		notice3 := map[string]any{
			"type":      db.FrNoticeTypeAlert,
			"content":   "content of altert notice nr. 1",
			"startTime": nil,
			"endTime":   nil,
		}

		notices := [](map[string]any){
			notice1, notice2, notice3,
		}

		resN1 := e.POST("/api/v1/notices").WithJSON(notice1).Expect().Status(201)
		notice1["id"] = resN1.JSON().Object().Value("id").Raw()

		resN2 := e.POST("/api/v1/notices").WithJSON(notice2).Expect().Status(201)
		notice2["id"] = resN2.JSON().Object().Value("id").Raw()

		resN3 := e.POST("/api/v1/notices").WithJSON(notice3).Expect().Status(201)
		notice3["id"] = resN3.JSON().Object().Value("id").Raw()

		resGetAll := e.GET("/api/v1/notices").Expect().Status(http.StatusOK)

		obj := resGetAll.JSON().Array()
		obj.IsEqual(notices)
	})
}
