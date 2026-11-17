package http

import (
	"fmt"
	"net/http"
	"testing"

	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/itest/util"
	"github.com/gavv/httpexpect/v2"
)

const (
	unknownExamID   = "3f2504e0-4f89-41d3-9a0c-0305e82c3301"
	malformedExamID = "not-a-uuid"

	examStartTime = "9999-11-20T08:00:00Z"
	examEndTime   = "9999-11-20T09:30:00Z"
)

func TestExams(t *testing.T, tcc *util.TestContextContainer) {
	t.Cleanup(func() { util.TruncateAll(t, tcc) })

	createExam := func(t *testing.T, e *httpexpect.Expect, title string) map[string]any {
		t.Helper()

		return e.POST("/api/v1/exams").
			WithJSON(map[string]any{
				"title":     title,
				"startTime": examStartTime,
				"endTime":   examEndTime,
			}).
			Expect().
			Status(http.StatusCreated).
			JSON().Object().Raw()
	}

	t.Run("create exam", func(t *testing.T) {

		e := util.NewE(t, tcc.BaseURL, tcc.KcTeacherAdminToken)

		res := e.POST("/api/v1/exams").
			WithJSON(map[string]any{
				"title":     "NWT Test 1",
				"startTime": examStartTime,
				"endTime":   examEndTime,
			}).
			Expect().
			Status(http.StatusCreated)

		obj := res.JSON().Object()
		obj.Value("title").String().IsEqual("NWT Test 1")
		obj.Value("startTime").String().IsEqual(examStartTime)
		obj.Value("endTime").String().IsEqual(examEndTime)
		obj.Value("teacherId").String().NotEmpty()
		obj.Value("pin").Number().InRange(tcc.Config.PinMin, tcc.Config.PinMax)
		obj.Value("startedAt").IsNull()
		obj.Value("endedAt").IsNull()

		id := obj.Value("id").String().NotEmpty().Raw()
		res.Header("Location").IsEqual("/api/v1/exams/" + id)
	})

	t.Run("create exam without title with 1 problem", func(t *testing.T) {

		e := util.NewE(t, tcc.BaseURL, tcc.KcTeacherAdminToken)

		res := e.POST("/api/v1/exams").
			WithJSON(map[string]any{
				"startTime": examStartTime,
				"endTime":   examEndTime,
			}).
			Expect().
			Status(http.StatusBadRequest)

		obj := res.JSON().Object()

		obj.Value("status").Number().IsEqual(http.StatusBadRequest)
		obj.Value("problems").Array().Length().IsEqual(1)
	})

	t.Run("get exam is equal", func(t *testing.T) {

		e := util.NewE(t, tcc.BaseURL, tcc.KcTeacherAdminToken)

		exam := createExam(t, e, "this is an exams title")

		res := e.GET(fmt.Sprintf("/api/v1/exams/%s", exam["id"])).
			Expect().
			Status(http.StatusOK)

		obj := res.JSON().Object()
		obj.IsEqual(exam)
	})

	t.Run("get unknown exam is not found", func(t *testing.T) {

		e := util.NewE(t, tcc.BaseURL, tcc.KcTeacherAdminToken)

		res := e.GET(fmt.Sprintf("/api/v1/exams/%s", unknownExamID)).
			Expect().
			Status(http.StatusNotFound)

		obj := res.JSON().Object()
		obj.Value("status").Number().IsEqual(http.StatusNotFound)
	})

	t.Run("get exam with malformed id fails", func(t *testing.T) {

		e := util.NewE(t, tcc.BaseURL, tcc.KcTeacherAdminToken)

		res := e.GET(fmt.Sprintf("/api/v1/exams/%s", malformedExamID)).
			Expect().
			Status(http.StatusBadRequest)

		obj := res.JSON().Object()
		obj.Value("status").Number().IsEqual(http.StatusBadRequest)
	})

	t.Run("get exam of another teacher is not found", func(t *testing.T) {

		owner := util.NewE(t, tcc.BaseURL, tcc.KcTeacherAdminToken)
		other := util.NewE(t, tcc.BaseURL, tcc.KcTeacherToken)

		exam := createExam(t, owner, "exam of another teacher")

		res := other.GET(fmt.Sprintf("/api/v1/exams/%s", exam["id"])).
			Expect().
			Status(http.StatusNotFound)

		obj := res.JSON().Object()
		obj.Value("status").Number().IsEqual(http.StatusNotFound)
	})

	t.Run("get my exams without exams is empty", func(t *testing.T) {
		util.TruncateAll(t, tcc)

		e := util.NewE(t, tcc.BaseURL, tcc.KcTeacherAdminToken)

		res := e.GET("/api/v1/exams").
			Expect().
			Status(http.StatusOK)

		res.JSON().Array().IsEmpty()
	})

	t.Run("create multiple exams then multiple exams", func(t *testing.T) {
		util.TruncateAll(t, tcc)

		e := util.NewE(t, tcc.BaseURL, tcc.KcTeacherAdminToken)

		exam1 := createExam(t, e, "content of exam nr. 1")
		exam2 := createExam(t, e, "content of exam nr. 2")
		exam3 := createExam(t, e, "content of exam nr. 3")

		exams := [](map[string]any){
			exam1, exam2, exam3,
		}

		res := e.GET("/api/v1/exams").
			Expect().
			Status(http.StatusOK)

		res.JSON().Array().IsEqual(exams)
	})

	t.Run("get my exams returns only own exams", func(t *testing.T) {
		util.TruncateAll(t, tcc)

		owner := util.NewE(t, tcc.BaseURL, tcc.KcTeacherAdminToken)
		other := util.NewE(t, tcc.BaseURL, tcc.KcTeacherToken)

		exam1 := createExam(t, owner, "own exam nr. 1")
		exam2 := createExam(t, owner, "own exam nr. 2")
		_ = createExam(t, other, "exam of the other teacher")

		res := owner.GET("/api/v1/exams").
			Expect().
			Status(http.StatusOK)

		res.JSON().Array().IsEqual([](map[string]any){exam1, exam2})
	})

	t.Run("open exam sets startedAt", func(t *testing.T) {

		e := util.NewE(t, tcc.BaseURL, tcc.KcTeacherAdminToken)

		exam := createExam(t, e, "exam to open")

		res := e.POST(fmt.Sprintf("/api/v1/exams/%s/open", exam["id"])).
			Expect().
			Status(http.StatusOK)

		obj := res.JSON().Object()
		obj.Value("id").IsEqual(exam["id"])
		obj.Value("title").String().IsEqual("exam to open")
		obj.Value("startedAt").String().NotEmpty()
		obj.Value("endedAt").IsNull()
	})

	t.Run("open already opened exam fails", func(t *testing.T) {

		e := util.NewE(t, tcc.BaseURL, tcc.KcTeacherAdminToken)

		exam := createExam(t, e, "exam to open twice")

		_ = e.POST(fmt.Sprintf("/api/v1/exams/%s/open", exam["id"])).
			Expect().
			Status(http.StatusOK)

		e.POST(fmt.Sprintf("/api/v1/exams/%s/open", exam["id"])).
			Expect().
			Status(http.StatusBadRequest)
	})

	t.Run("open unknown exam is not found", func(t *testing.T) {

		e := util.NewE(t, tcc.BaseURL, tcc.KcTeacherAdminToken)

		res := e.POST(fmt.Sprintf("/api/v1/exams/%s/open", unknownExamID)).
			Expect().
			Status(http.StatusNotFound)

		obj := res.JSON().Object()
		obj.Value("status").Number().IsEqual(http.StatusNotFound)
	})

	t.Run("open exam with malformed id fails", func(t *testing.T) {

		e := util.NewE(t, tcc.BaseURL, tcc.KcTeacherAdminToken)

		res := e.POST(fmt.Sprintf("/api/v1/exams/%s/open", malformedExamID)).
			Expect().
			Status(http.StatusBadRequest)

		obj := res.JSON().Object()
		obj.Value("status").Number().IsEqual(http.StatusBadRequest)
	})

	t.Run("open exam of another teacher is not found", func(t *testing.T) {

		owner := util.NewE(t, tcc.BaseURL, tcc.KcTeacherAdminToken)
		other := util.NewE(t, tcc.BaseURL, tcc.KcTeacherToken)

		exam := createExam(t, owner, "exam of another teacher to open")

		res := other.POST(fmt.Sprintf("/api/v1/exams/%s/open", exam["id"])).
			Expect().
			Status(http.StatusNotFound)

		obj := res.JSON().Object()
		obj.Value("status").Number().IsEqual(http.StatusNotFound)
	})

	t.Run("start exam sets start_time", func(t *testing.T) {

		e := util.NewE(t, tcc.BaseURL, tcc.KcTeacherAdminToken)

		exam := createExam(t, e, "exam to start")

		_ = e.POST(fmt.Sprintf("/api/v1/exams/%s/open", exam["id"])).
			Expect().
			Status(http.StatusOK)

		res := e.POST(fmt.Sprintf("/api/v1/exams/%s/start", exam["id"])).
			Expect().
			Status(http.StatusOK)

		obj := res.JSON().Object()
		obj.Value("id").IsEqual(exam["id"])
		obj.Value("title").String().IsEqual("exam to start")
		obj.Value("startTime").String().NotEqual(examStartTime)
		obj.Value("endTime").String().IsEqual(examEndTime)
	})

	t.Run("start a non opened exam fails", func(t *testing.T) {

		e := util.NewE(t, tcc.BaseURL, tcc.KcTeacherAdminToken)

		exam := createExam(t, e, "exam to fail starting twice")

		_ = e.POST(fmt.Sprintf("/api/v1/exams/%s/start", exam["id"])).
			Expect().
			Status(http.StatusBadRequest)
	})

	t.Run("starting a started exam fails", func(t *testing.T) {

		e := util.NewE(t, tcc.BaseURL, tcc.KcTeacherAdminToken)

		exam := createExam(t, e, "exam to be started twice")

		_ = e.POST(fmt.Sprintf("/api/v1/exams/%s/open", exam["id"])).
			Expect().
			Status(http.StatusOK)

		_ = e.POST(fmt.Sprintf("/api/v1/exams/%s/start", exam["id"])).
			Expect().
			Status(http.StatusOK)

		_ = e.POST(fmt.Sprintf("/api/v1/exams/%s/start", exam["id"])).
			Expect().
			Status(http.StatusBadRequest)
	})
}
