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

	examStateScheduled = "scheduled"
	examStateOpen      = "open"
	examStateLive      = "live"
	examStateEnded     = "ended"
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

	// transition drives an exam into the given state along
	// scheduled -> open -> live -> ended, asserting every step on the way.
	transition := func(t *testing.T, e *httpexpect.Expect, id any, state string) {
		t.Helper()

		verbs := map[string][]string{
			examStateOpen:  {"open"},
			examStateLive:  {"open", "start"},
			examStateEnded: {"open", "start", "end"},
		}

		for _, verb := range verbs[state] {
			e.POST(fmt.Sprintf("/api/v1/exams/%s/%s", id, verb)).
				Expect().
				Status(http.StatusOK)
		}
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
		obj.Value("state").String().IsEqual(examStateScheduled)
		obj.ContainsKey("preopenTimeMinutes")

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

	t.Run("open exam sets state to open", func(t *testing.T) {

		e := util.NewE(t, tcc.BaseURL, tcc.KcTeacherAdminToken)

		exam := createExam(t, e, "exam to open")

		res := e.POST(fmt.Sprintf("/api/v1/exams/%s/open", exam["id"])).
			Expect().
			Status(http.StatusOK)

		obj := res.JSON().Object()
		obj.Value("id").IsEqual(exam["id"])
		obj.Value("title").String().IsEqual("exam to open")
		obj.Value("state").String().IsEqual(examStateOpen)
	})

	t.Run("open already opened exam fails", func(t *testing.T) {

		e := util.NewE(t, tcc.BaseURL, tcc.KcTeacherAdminToken)

		exam := createExam(t, e, "exam to open twice")
		transition(t, e, exam["id"], examStateOpen)

		e.POST(fmt.Sprintf("/api/v1/exams/%s/open", exam["id"])).
			Expect().
			Status(http.StatusBadRequest)
	})

	t.Run("open live exam fails", func(t *testing.T) {

		e := util.NewE(t, tcc.BaseURL, tcc.KcTeacherAdminToken)

		exam := createExam(t, e, "live exam to open")
		transition(t, e, exam["id"], examStateLive)

		e.POST(fmt.Sprintf("/api/v1/exams/%s/open", exam["id"])).
			Expect().
			Status(http.StatusBadRequest)
	})

	t.Run("open ended exam fails", func(t *testing.T) {

		e := util.NewE(t, tcc.BaseURL, tcc.KcTeacherAdminToken)

		exam := createExam(t, e, "ended exam to open")
		transition(t, e, exam["id"], examStateEnded)

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

	t.Run("start exam sets state to live", func(t *testing.T) {

		e := util.NewE(t, tcc.BaseURL, tcc.KcTeacherAdminToken)

		exam := createExam(t, e, "exam to start")
		transition(t, e, exam["id"], examStateOpen)

		res := e.POST(fmt.Sprintf("/api/v1/exams/%s/start", exam["id"])).
			Expect().
			Status(http.StatusOK)

		obj := res.JSON().Object()
		obj.Value("id").IsEqual(exam["id"])
		obj.Value("title").String().IsEqual("exam to start")
		obj.Value("state").String().IsEqual(examStateLive)
	})

	t.Run("start a scheduled exam fails", func(t *testing.T) {

		e := util.NewE(t, tcc.BaseURL, tcc.KcTeacherAdminToken)

		exam := createExam(t, e, "scheduled exam to start")

		e.POST(fmt.Sprintf("/api/v1/exams/%s/start", exam["id"])).
			Expect().
			Status(http.StatusBadRequest)
	})

	t.Run("starting a live exam fails", func(t *testing.T) {

		e := util.NewE(t, tcc.BaseURL, tcc.KcTeacherAdminToken)

		exam := createExam(t, e, "exam to be started twice")
		transition(t, e, exam["id"], examStateLive)

		e.POST(fmt.Sprintf("/api/v1/exams/%s/start", exam["id"])).
			Expect().
			Status(http.StatusBadRequest)
	})

	t.Run("start ended exam fails", func(t *testing.T) {

		e := util.NewE(t, tcc.BaseURL, tcc.KcTeacherAdminToken)

		exam := createExam(t, e, "ended exam to start")
		transition(t, e, exam["id"], examStateEnded)

		e.POST(fmt.Sprintf("/api/v1/exams/%s/start", exam["id"])).
			Expect().
			Status(http.StatusBadRequest)
	})

	t.Run("start unknown exam is not found", func(t *testing.T) {

		e := util.NewE(t, tcc.BaseURL, tcc.KcTeacherAdminToken)

		res := e.POST(fmt.Sprintf("/api/v1/exams/%s/start", unknownExamID)).
			Expect().
			Status(http.StatusNotFound)

		obj := res.JSON().Object()
		obj.Value("status").Number().IsEqual(http.StatusNotFound)
	})

	t.Run("start exam with malformed id fails", func(t *testing.T) {

		e := util.NewE(t, tcc.BaseURL, tcc.KcTeacherAdminToken)

		res := e.POST(fmt.Sprintf("/api/v1/exams/%s/start", malformedExamID)).
			Expect().
			Status(http.StatusBadRequest)

		obj := res.JSON().Object()
		obj.Value("status").Number().IsEqual(http.StatusBadRequest)
	})

	t.Run("start exam of another teacher is not found", func(t *testing.T) {

		owner := util.NewE(t, tcc.BaseURL, tcc.KcTeacherAdminToken)
		other := util.NewE(t, tcc.BaseURL, tcc.KcTeacherToken)

		exam := createExam(t, owner, "exam of another teacher to start")
		transition(t, owner, exam["id"], examStateOpen)

		res := other.POST(fmt.Sprintf("/api/v1/exams/%s/start", exam["id"])).
			Expect().
			Status(http.StatusNotFound)

		obj := res.JSON().Object()
		obj.Value("status").Number().IsEqual(http.StatusNotFound)
	})

	t.Run("end exam sets state to ended", func(t *testing.T) {

		e := util.NewE(t, tcc.BaseURL, tcc.KcTeacherAdminToken)

		exam := createExam(t, e, "exam to end")
		transition(t, e, exam["id"], examStateLive)

		res := e.POST(fmt.Sprintf("/api/v1/exams/%s/end", exam["id"])).
			Expect().
			Status(http.StatusOK)

		obj := res.JSON().Object()
		obj.Value("id").IsEqual(exam["id"])
		obj.Value("title").String().IsEqual("exam to end")
		obj.Value("state").String().IsEqual(examStateEnded)
	})

	t.Run("end a scheduled exam fails", func(t *testing.T) {

		e := util.NewE(t, tcc.BaseURL, tcc.KcTeacherAdminToken)

		exam := createExam(t, e, "scheduled exam to end")

		e.POST(fmt.Sprintf("/api/v1/exams/%s/end", exam["id"])).
			Expect().
			Status(http.StatusBadRequest)
	})

	t.Run("end an opened exam fails", func(t *testing.T) {

		e := util.NewE(t, tcc.BaseURL, tcc.KcTeacherAdminToken)

		exam := createExam(t, e, "opened exam to end")
		transition(t, e, exam["id"], examStateOpen)

		e.POST(fmt.Sprintf("/api/v1/exams/%s/end", exam["id"])).
			Expect().
			Status(http.StatusBadRequest)
	})

	t.Run("ending an ended exam fails", func(t *testing.T) {

		e := util.NewE(t, tcc.BaseURL, tcc.KcTeacherAdminToken)

		exam := createExam(t, e, "exam to be ended twice")
		transition(t, e, exam["id"], examStateEnded)

		e.POST(fmt.Sprintf("/api/v1/exams/%s/end", exam["id"])).
			Expect().
			Status(http.StatusBadRequest)
	})

	t.Run("end unknown exam is not found", func(t *testing.T) {

		e := util.NewE(t, tcc.BaseURL, tcc.KcTeacherAdminToken)

		res := e.POST(fmt.Sprintf("/api/v1/exams/%s/end", unknownExamID)).
			Expect().
			Status(http.StatusNotFound)

		obj := res.JSON().Object()
		obj.Value("status").Number().IsEqual(http.StatusNotFound)
	})

	t.Run("end exam with malformed id fails", func(t *testing.T) {

		e := util.NewE(t, tcc.BaseURL, tcc.KcTeacherAdminToken)

		res := e.POST(fmt.Sprintf("/api/v1/exams/%s/end", malformedExamID)).
			Expect().
			Status(http.StatusBadRequest)

		obj := res.JSON().Object()
		obj.Value("status").Number().IsEqual(http.StatusBadRequest)
	})

	t.Run("end exam of another teacher is not found", func(t *testing.T) {

		owner := util.NewE(t, tcc.BaseURL, tcc.KcTeacherAdminToken)
		other := util.NewE(t, tcc.BaseURL, tcc.KcTeacherToken)

		exam := createExam(t, owner, "exam of another teacher to end")
		transition(t, owner, exam["id"], examStateLive)

		res := other.POST(fmt.Sprintf("/api/v1/exams/%s/end", exam["id"])).
			Expect().
			Status(http.StatusNotFound)

		obj := res.JSON().Object()
		obj.Value("status").Number().IsEqual(http.StatusNotFound)
	})

	// examRoutes are every exam route, used to pin the statuses the spec
	// states for all of them at once.
	type examRoute struct {
		name   string
		method string
		path   string
		body   map[string]any
	}

	examRoutes := func(id any) []examRoute {
		return []examRoute{
			{name: "list exams", method: http.MethodGet, path: "/api/v1/exams"},
			{name: "create exam", method: http.MethodPost, path: "/api/v1/exams", body: map[string]any{
				"title":     "exam the caller may not create",
				"startTime": examStartTime,
				"endTime":   examEndTime,
			}},
			{name: "get exam", method: http.MethodGet,
				path: fmt.Sprintf("/api/v1/exams/%s", id)},
			{name: "open exam", method: http.MethodPost,
				path: fmt.Sprintf("/api/v1/exams/%s/open", id)},
			{name: "start exam", method: http.MethodPost,
				path: fmt.Sprintf("/api/v1/exams/%s/start", id)},
			{name: "end exam", method: http.MethodPost,
				path: fmt.Sprintf("/api/v1/exams/%s/end", id)},
		}
	}

	t.Run("exam endpoints are forbidden for students", func(t *testing.T) {

		teacher := util.NewE(t, tcc.BaseURL, tcc.KcTeacherAdminToken)

		exam := createExam(t, teacher, "exam a student must not touch")

		for _, c := range examRoutes(exam["id"]) {
			t.Run(c.name, func(t *testing.T) {
				student := util.NewE(t, tcc.BaseURL, tcc.KcStudentToken)

				req := student.Request(c.method, c.path)
				if c.body != nil {
					req = req.WithJSON(c.body)
				}

				res := req.
					Expect().
					Status(http.StatusForbidden)

				obj := res.JSON().Object()
				obj.Value("status").Number().IsEqual(http.StatusForbidden)
			})
		}
	})

	t.Run("exam endpoints are unauthorized without a token", func(t *testing.T) {

		for _, c := range examRoutes(unknownExamID) {
			t.Run(c.name, func(t *testing.T) {
				e := util.NewE(t, tcc.BaseURL, "")

				req := e.Request(c.method, c.path)
				if c.body != nil {
					req = req.WithJSON(c.body)
				}

				res := req.
					Expect().
					Status(http.StatusUnauthorized)

				obj := res.JSON().Object()
				obj.Value("status").Number().IsEqual(http.StatusUnauthorized)
			})
		}
	})
}
