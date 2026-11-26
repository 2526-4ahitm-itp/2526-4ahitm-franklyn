package rpc

import (
	"context"
	"net/http"
	"testing"
	"time"

	"connectrpc.com/connect/v2"
	"connectrpc.com/connect/v2/connecthttp"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/types/known/timestamppb"

	commonv1 "github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/proto/franklyn/common/v1"
	examcommon "github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/proto/franklyn/exam/common"
	examv1 "github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/proto/franklyn/exam/v1"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/proto/franklyn/exam/v1/examv1connect"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/itest/util"
)

const (
	unknownExamID   = "3f2504e0-4f89-41d3-9a0c-0305e82c3301"
	malformedExamID = "not-a-uuid"
)

var (
	examStartTime = time.Date(9999, time.November, 20, 8, 0, 0, 0, time.UTC)
	examEndTime   = time.Date(9999, time.November, 20, 9, 30, 0, 0, time.UTC)
)

// newExamClient builds an ExamService client against the running test
// server that sends token as a bearer token. An empty token sends no
// Authorization header at all.
func newExamClient(tcc *util.TestContextContainer, token string) examv1connect.ExamServiceClient {
	auth := func(next connect.ClientFunc) connect.ClientFunc {
		return func(ctx context.Context, spec connect.Spec) (connect.ClientStream, error) {
			if info, ok := connect.CallInfoForClientContext(ctx); ok && token != "" {
				info.RequestHeader().Set("Authorization", "Bearer "+token)
			}
			return next(ctx, spec)
		}
	}

	return examv1connect.NewExamServiceClient(
		connect.NewClient(connecthttp.NewTransport(http.DefaultClient, tcc.BaseURL), auth),
	)
}

func TestExams(t *testing.T, tcc *util.TestContextContainer) {
	t.Cleanup(func() { util.TruncateAll(t, tcc) })

	t.Run("create exam", func(t *testing.T) {
		client := newExamClient(tcc, tcc.KcTeacherAdminToken)

		res, err := client.CreateExam(t.Context(), &examv1.CreateExamRequest{
			Title:     "NWT Test 1",
			StartTime: timestamppb.New(examStartTime),
			EndTime:   timestamppb.New(examEndTime),
		})
		require.NoError(t, err)

		exam := res.GetExam()
		assert.Equal(t, "NWT Test 1", exam.GetTitle())
		assert.Equal(t, examStartTime, exam.GetStartTime().AsTime())
		assert.Equal(t, examEndTime, exam.GetEndTime().AsTime())
		assert.NotEmpty(t, exam.GetTeacherId().GetId())
		assert.GreaterOrEqual(t, int64(exam.GetPin()), int64(tcc.Config.PinMin))
		assert.LessOrEqual(t, int64(exam.GetPin()), int64(tcc.Config.PinMax))
		assert.Equal(t, examcommon.ExamState_EXAM_STATE_SCHEDULED, exam.GetState())
		assert.NotEmpty(t, exam.GetId().GetId())
	})

	t.Run("create exam without title with 1 problem", func(t *testing.T) {
		client := newExamClient(tcc, tcc.KcTeacherAdminToken)

		_, err := client.CreateExam(t.Context(), &examv1.CreateExamRequest{
			StartTime: timestamppb.New(examStartTime),
			EndTime:   timestamppb.New(examEndTime),
		})
		assert.Equal(t, connect.CodeInvalidArgument, connect.CodeOf(err))
	})

	t.Run("get exam is equal", func(t *testing.T) {
		client := newExamClient(tcc, tcc.KcTeacherAdminToken)

		created, err := client.CreateExam(t.Context(), &examv1.CreateExamRequest{
			Title:     "this is an exams title",
			StartTime: timestamppb.New(examStartTime),
			EndTime:   timestamppb.New(examEndTime),
		})
		require.NoError(t, err)

		found, err := client.FindExamById(t.Context(), &examv1.FindExamByIdRequest{
			Id: created.GetExam().GetId(),
		})
		require.NoError(t, err)

		assert.True(t, proto.Equal(created.GetExam(), found.GetExam()),
			"expected %v, got %v", created.GetExam(), found.GetExam())
	})

	t.Run("get unknown exam is not found", func(t *testing.T) {
		client := newExamClient(tcc, tcc.KcTeacherAdminToken)

		_, err := client.FindExamById(t.Context(), &examv1.FindExamByIdRequest{
			Id: &commonv1.UUID{Id: unknownExamID},
		})
		assert.Equal(t, connect.CodeNotFound, connect.CodeOf(err))
	})

	t.Run("get exam with malformed id fails", func(t *testing.T) {
		client := newExamClient(tcc, tcc.KcTeacherAdminToken)

		_, err := client.FindExamById(t.Context(), &examv1.FindExamByIdRequest{
			Id: &commonv1.UUID{Id: malformedExamID},
		})
		assert.Equal(t, connect.CodeInvalidArgument, connect.CodeOf(err))
	})

	t.Run("get exam of another teacher is not found", func(t *testing.T) {
		owner := newExamClient(tcc, tcc.KcTeacherAdminToken)
		other := newExamClient(tcc, tcc.KcTeacherToken)

		created, err := owner.CreateExam(t.Context(), &examv1.CreateExamRequest{
			Title:     "exam of another teacher",
			StartTime: timestamppb.New(examStartTime),
			EndTime:   timestamppb.New(examEndTime),
		})
		require.NoError(t, err)

		_, err = other.FindExamById(t.Context(), &examv1.FindExamByIdRequest{
			Id: created.GetExam().GetId(),
		})
		assert.Equal(t, connect.CodeNotFound, connect.CodeOf(err))
	})

	t.Run("get my exams without exams is empty", func(t *testing.T) {
		util.TruncateAll(t, tcc)

		client := newExamClient(tcc, tcc.KcTeacherAdminToken)

		res, err := client.FindMyExams(t.Context(), &examv1.FindMyExamsRequest{})
		require.NoError(t, err)

		assert.Empty(t, res.GetExam())
	})

	t.Run("create multiple exams then multiple exams", func(t *testing.T) {
		util.TruncateAll(t, tcc)

		client := newExamClient(tcc, tcc.KcTeacherAdminToken)

		exam1, err := client.CreateExam(t.Context(), &examv1.CreateExamRequest{
			Title:     "content of exam nr. 1",
			StartTime: timestamppb.New(examStartTime),
			EndTime:   timestamppb.New(examEndTime),
		})
		require.NoError(t, err)

		exam2, err := client.CreateExam(t.Context(), &examv1.CreateExamRequest{
			Title:     "content of exam nr. 2",
			StartTime: timestamppb.New(examStartTime),
			EndTime:   timestamppb.New(examEndTime),
		})
		require.NoError(t, err)

		exam3, err := client.CreateExam(t.Context(), &examv1.CreateExamRequest{
			Title:     "content of exam nr. 3",
			StartTime: timestamppb.New(examStartTime),
			EndTime:   timestamppb.New(examEndTime),
		})
		require.NoError(t, err)

		res, err := client.FindMyExams(t.Context(), &examv1.FindMyExamsRequest{})
		require.NoError(t, err)

		exams := res.GetExam()
		require.Len(t, exams, 3)
		assert.True(t, proto.Equal(exam1.GetExam(), exams[0]), "expected %v, got %v", exam1.GetExam(), exams[0])
		assert.True(t, proto.Equal(exam2.GetExam(), exams[1]), "expected %v, got %v", exam2.GetExam(), exams[1])
		assert.True(t, proto.Equal(exam3.GetExam(), exams[2]), "expected %v, got %v", exam3.GetExam(), exams[2])
	})

	t.Run("get my exams returns only own exams", func(t *testing.T) {
		util.TruncateAll(t, tcc)

		owner := newExamClient(tcc, tcc.KcTeacherAdminToken)
		other := newExamClient(tcc, tcc.KcTeacherToken)

		exam1, err := owner.CreateExam(t.Context(), &examv1.CreateExamRequest{
			Title:     "own exam nr. 1",
			StartTime: timestamppb.New(examStartTime),
			EndTime:   timestamppb.New(examEndTime),
		})
		require.NoError(t, err)

		exam2, err := owner.CreateExam(t.Context(), &examv1.CreateExamRequest{
			Title:     "own exam nr. 2",
			StartTime: timestamppb.New(examStartTime),
			EndTime:   timestamppb.New(examEndTime),
		})
		require.NoError(t, err)

		_, err = other.CreateExam(t.Context(), &examv1.CreateExamRequest{
			Title:     "exam of the other teacher",
			StartTime: timestamppb.New(examStartTime),
			EndTime:   timestamppb.New(examEndTime),
		})
		require.NoError(t, err)

		res, err := owner.FindMyExams(t.Context(), &examv1.FindMyExamsRequest{})
		require.NoError(t, err)

		exams := res.GetExam()
		require.Len(t, exams, 2)
		assert.True(t, proto.Equal(exam1.GetExam(), exams[0]), "expected %v, got %v", exam1.GetExam(), exams[0])
		assert.True(t, proto.Equal(exam2.GetExam(), exams[1]), "expected %v, got %v", exam2.GetExam(), exams[1])
	})

	t.Run("open exam sets state to open", func(t *testing.T) {
		client := newExamClient(tcc, tcc.KcTeacherAdminToken)

		created, err := client.CreateExam(t.Context(), &examv1.CreateExamRequest{
			Title:     "exam to open",
			StartTime: timestamppb.New(examStartTime),
			EndTime:   timestamppb.New(examEndTime),
		})
		require.NoError(t, err)

		res, err := client.OpenExam(t.Context(), &examv1.OpenExamRequest{Id: created.GetExam().GetId()})
		require.NoError(t, err)

		exam := res.GetExam()
		assert.Equal(t, created.GetExam().GetId().GetId(), exam.GetId().GetId())
		assert.Equal(t, "exam to open", exam.GetTitle())
		assert.Equal(t, examcommon.ExamState_EXAM_STATE_OPEN, exam.GetState())
	})

	t.Run("open already opened exam fails", func(t *testing.T) {
		client := newExamClient(tcc, tcc.KcTeacherAdminToken)

		created, err := client.CreateExam(t.Context(), &examv1.CreateExamRequest{
			Title:     "exam to open twice",
			StartTime: timestamppb.New(examStartTime),
			EndTime:   timestamppb.New(examEndTime),
		})
		require.NoError(t, err)
		id := created.GetExam().GetId()

		_, err = client.OpenExam(t.Context(), &examv1.OpenExamRequest{Id: id})
		require.NoError(t, err)

		_, err = client.OpenExam(t.Context(), &examv1.OpenExamRequest{Id: id})
		assert.Equal(t, connect.CodeFailedPrecondition, connect.CodeOf(err))
	})

	t.Run("open live exam fails", func(t *testing.T) {
		client := newExamClient(tcc, tcc.KcTeacherAdminToken)

		created, err := client.CreateExam(t.Context(), &examv1.CreateExamRequest{
			Title:     "live exam to open",
			StartTime: timestamppb.New(examStartTime),
			EndTime:   timestamppb.New(examEndTime),
		})
		require.NoError(t, err)
		id := created.GetExam().GetId()

		_, err = client.OpenExam(t.Context(), &examv1.OpenExamRequest{Id: id})
		require.NoError(t, err)
		_, err = client.StartExam(t.Context(), &examv1.StartExamRequest{Id: id})
		require.NoError(t, err)

		_, err = client.OpenExam(t.Context(), &examv1.OpenExamRequest{Id: id})
		assert.Equal(t, connect.CodeFailedPrecondition, connect.CodeOf(err))
	})

	t.Run("open ended exam fails", func(t *testing.T) {
		client := newExamClient(tcc, tcc.KcTeacherAdminToken)

		created, err := client.CreateExam(t.Context(), &examv1.CreateExamRequest{
			Title:     "ended exam to open",
			StartTime: timestamppb.New(examStartTime),
			EndTime:   timestamppb.New(examEndTime),
		})
		require.NoError(t, err)
		id := created.GetExam().GetId()

		_, err = client.OpenExam(t.Context(), &examv1.OpenExamRequest{Id: id})
		require.NoError(t, err)
		_, err = client.StartExam(t.Context(), &examv1.StartExamRequest{Id: id})
		require.NoError(t, err)
		_, err = client.EndExam(t.Context(), &examv1.EndExamRequest{Id: id})
		require.NoError(t, err)

		_, err = client.OpenExam(t.Context(), &examv1.OpenExamRequest{Id: id})
		assert.Equal(t, connect.CodeFailedPrecondition, connect.CodeOf(err))
	})

	t.Run("open unknown exam is not found", func(t *testing.T) {
		client := newExamClient(tcc, tcc.KcTeacherAdminToken)

		_, err := client.OpenExam(t.Context(), &examv1.OpenExamRequest{
			Id: &commonv1.UUID{Id: unknownExamID},
		})
		assert.Equal(t, connect.CodeNotFound, connect.CodeOf(err))
	})

	t.Run("open exam with malformed id fails", func(t *testing.T) {
		client := newExamClient(tcc, tcc.KcTeacherAdminToken)

		_, err := client.OpenExam(t.Context(), &examv1.OpenExamRequest{
			Id: &commonv1.UUID{Id: malformedExamID},
		})
		assert.Equal(t, connect.CodeInvalidArgument, connect.CodeOf(err))
	})

	t.Run("open exam of another teacher is not found", func(t *testing.T) {
		owner := newExamClient(tcc, tcc.KcTeacherAdminToken)
		other := newExamClient(tcc, tcc.KcTeacherToken)

		created, err := owner.CreateExam(t.Context(), &examv1.CreateExamRequest{
			Title:     "exam of another teacher to open",
			StartTime: timestamppb.New(examStartTime),
			EndTime:   timestamppb.New(examEndTime),
		})
		require.NoError(t, err)

		_, err = other.OpenExam(t.Context(), &examv1.OpenExamRequest{Id: created.GetExam().GetId()})
		assert.Equal(t, connect.CodeNotFound, connect.CodeOf(err))
	})

	t.Run("start exam sets state to live", func(t *testing.T) {
		client := newExamClient(tcc, tcc.KcTeacherAdminToken)

		created, err := client.CreateExam(t.Context(), &examv1.CreateExamRequest{
			Title:     "exam to start",
			StartTime: timestamppb.New(examStartTime),
			EndTime:   timestamppb.New(examEndTime),
		})
		require.NoError(t, err)
		id := created.GetExam().GetId()

		_, err = client.OpenExam(t.Context(), &examv1.OpenExamRequest{Id: id})
		require.NoError(t, err)

		res, err := client.StartExam(t.Context(), &examv1.StartExamRequest{Id: id})
		require.NoError(t, err)

		exam := res.GetExam()
		assert.Equal(t, id.GetId(), exam.GetId().GetId())
		assert.Equal(t, "exam to start", exam.GetTitle())
		assert.Equal(t, examcommon.ExamState_EXAM_STATE_LIVE, exam.GetState())
	})

	t.Run("start a scheduled exam fails", func(t *testing.T) {
		client := newExamClient(tcc, tcc.KcTeacherAdminToken)

		created, err := client.CreateExam(t.Context(), &examv1.CreateExamRequest{
			Title:     "scheduled exam to start",
			StartTime: timestamppb.New(examStartTime),
			EndTime:   timestamppb.New(examEndTime),
		})
		require.NoError(t, err)

		_, err = client.StartExam(t.Context(), &examv1.StartExamRequest{Id: created.GetExam().GetId()})
		assert.Equal(t, connect.CodeFailedPrecondition, connect.CodeOf(err))
	})

	t.Run("starting a live exam fails", func(t *testing.T) {
		client := newExamClient(tcc, tcc.KcTeacherAdminToken)

		created, err := client.CreateExam(t.Context(), &examv1.CreateExamRequest{
			Title:     "exam to be started twice",
			StartTime: timestamppb.New(examStartTime),
			EndTime:   timestamppb.New(examEndTime),
		})
		require.NoError(t, err)
		id := created.GetExam().GetId()

		_, err = client.OpenExam(t.Context(), &examv1.OpenExamRequest{Id: id})
		require.NoError(t, err)
		_, err = client.StartExam(t.Context(), &examv1.StartExamRequest{Id: id})
		require.NoError(t, err)

		_, err = client.StartExam(t.Context(), &examv1.StartExamRequest{Id: id})
		assert.Equal(t, connect.CodeFailedPrecondition, connect.CodeOf(err))
	})

	t.Run("start ended exam fails", func(t *testing.T) {
		client := newExamClient(tcc, tcc.KcTeacherAdminToken)

		created, err := client.CreateExam(t.Context(), &examv1.CreateExamRequest{
			Title:     "ended exam to start",
			StartTime: timestamppb.New(examStartTime),
			EndTime:   timestamppb.New(examEndTime),
		})
		require.NoError(t, err)
		id := created.GetExam().GetId()

		_, err = client.OpenExam(t.Context(), &examv1.OpenExamRequest{Id: id})
		require.NoError(t, err)
		_, err = client.StartExam(t.Context(), &examv1.StartExamRequest{Id: id})
		require.NoError(t, err)
		_, err = client.EndExam(t.Context(), &examv1.EndExamRequest{Id: id})
		require.NoError(t, err)

		_, err = client.StartExam(t.Context(), &examv1.StartExamRequest{Id: id})
		assert.Equal(t, connect.CodeFailedPrecondition, connect.CodeOf(err))
	})

	t.Run("start unknown exam is not found", func(t *testing.T) {
		client := newExamClient(tcc, tcc.KcTeacherAdminToken)

		_, err := client.StartExam(t.Context(), &examv1.StartExamRequest{
			Id: &commonv1.UUID{Id: unknownExamID},
		})
		assert.Equal(t, connect.CodeNotFound, connect.CodeOf(err))
	})

	t.Run("start exam with malformed id fails", func(t *testing.T) {
		client := newExamClient(tcc, tcc.KcTeacherAdminToken)

		_, err := client.StartExam(t.Context(), &examv1.StartExamRequest{
			Id: &commonv1.UUID{Id: malformedExamID},
		})
		assert.Equal(t, connect.CodeInvalidArgument, connect.CodeOf(err))
	})

	t.Run("start exam of another teacher is not found", func(t *testing.T) {
		owner := newExamClient(tcc, tcc.KcTeacherAdminToken)
		other := newExamClient(tcc, tcc.KcTeacherToken)

		created, err := owner.CreateExam(t.Context(), &examv1.CreateExamRequest{
			Title:     "exam of another teacher to start",
			StartTime: timestamppb.New(examStartTime),
			EndTime:   timestamppb.New(examEndTime),
		})
		require.NoError(t, err)
		id := created.GetExam().GetId()

		_, err = owner.OpenExam(t.Context(), &examv1.OpenExamRequest{Id: id})
		require.NoError(t, err)

		_, err = other.StartExam(t.Context(), &examv1.StartExamRequest{Id: id})
		assert.Equal(t, connect.CodeNotFound, connect.CodeOf(err))
	})

	t.Run("end exam sets state to ended", func(t *testing.T) {
		client := newExamClient(tcc, tcc.KcTeacherAdminToken)

		created, err := client.CreateExam(t.Context(), &examv1.CreateExamRequest{
			Title:     "exam to end",
			StartTime: timestamppb.New(examStartTime),
			EndTime:   timestamppb.New(examEndTime),
		})
		require.NoError(t, err)
		id := created.GetExam().GetId()

		_, err = client.OpenExam(t.Context(), &examv1.OpenExamRequest{Id: id})
		require.NoError(t, err)
		_, err = client.StartExam(t.Context(), &examv1.StartExamRequest{Id: id})
		require.NoError(t, err)

		res, err := client.EndExam(t.Context(), &examv1.EndExamRequest{Id: id})
		require.NoError(t, err)

		exam := res.GetExam()
		assert.Equal(t, id.GetId(), exam.GetId().GetId())
		assert.Equal(t, "exam to end", exam.GetTitle())
		assert.Equal(t, examcommon.ExamState_EXAM_STATE_ENDED, exam.GetState())
	})

	t.Run("end a scheduled exam fails", func(t *testing.T) {
		client := newExamClient(tcc, tcc.KcTeacherAdminToken)

		created, err := client.CreateExam(t.Context(), &examv1.CreateExamRequest{
			Title:     "scheduled exam to end",
			StartTime: timestamppb.New(examStartTime),
			EndTime:   timestamppb.New(examEndTime),
		})
		require.NoError(t, err)

		_, err = client.EndExam(t.Context(), &examv1.EndExamRequest{Id: created.GetExam().GetId()})
		assert.Equal(t, connect.CodeFailedPrecondition, connect.CodeOf(err))
	})

	t.Run("end an opened exam fails", func(t *testing.T) {
		client := newExamClient(tcc, tcc.KcTeacherAdminToken)

		created, err := client.CreateExam(t.Context(), &examv1.CreateExamRequest{
			Title:     "opened exam to end",
			StartTime: timestamppb.New(examStartTime),
			EndTime:   timestamppb.New(examEndTime),
		})
		require.NoError(t, err)
		id := created.GetExam().GetId()

		_, err = client.OpenExam(t.Context(), &examv1.OpenExamRequest{Id: id})
		require.NoError(t, err)

		_, err = client.EndExam(t.Context(), &examv1.EndExamRequest{Id: id})
		assert.Equal(t, connect.CodeFailedPrecondition, connect.CodeOf(err))
	})

	t.Run("ending an ended exam fails", func(t *testing.T) {
		client := newExamClient(tcc, tcc.KcTeacherAdminToken)

		created, err := client.CreateExam(t.Context(), &examv1.CreateExamRequest{
			Title:     "exam to be ended twice",
			StartTime: timestamppb.New(examStartTime),
			EndTime:   timestamppb.New(examEndTime),
		})
		require.NoError(t, err)
		id := created.GetExam().GetId()

		_, err = client.OpenExam(t.Context(), &examv1.OpenExamRequest{Id: id})
		require.NoError(t, err)
		_, err = client.StartExam(t.Context(), &examv1.StartExamRequest{Id: id})
		require.NoError(t, err)
		_, err = client.EndExam(t.Context(), &examv1.EndExamRequest{Id: id})
		require.NoError(t, err)

		_, err = client.EndExam(t.Context(), &examv1.EndExamRequest{Id: id})
		assert.Equal(t, connect.CodeFailedPrecondition, connect.CodeOf(err))
	})

	t.Run("end unknown exam is not found", func(t *testing.T) {
		client := newExamClient(tcc, tcc.KcTeacherAdminToken)

		_, err := client.EndExam(t.Context(), &examv1.EndExamRequest{
			Id: &commonv1.UUID{Id: unknownExamID},
		})
		assert.Equal(t, connect.CodeNotFound, connect.CodeOf(err))
	})

	t.Run("end exam with malformed id fails", func(t *testing.T) {
		client := newExamClient(tcc, tcc.KcTeacherAdminToken)

		_, err := client.EndExam(t.Context(), &examv1.EndExamRequest{
			Id: &commonv1.UUID{Id: malformedExamID},
		})
		assert.Equal(t, connect.CodeInvalidArgument, connect.CodeOf(err))
	})

	t.Run("end exam of another teacher is not found", func(t *testing.T) {
		owner := newExamClient(tcc, tcc.KcTeacherAdminToken)
		other := newExamClient(tcc, tcc.KcTeacherToken)

		created, err := owner.CreateExam(t.Context(), &examv1.CreateExamRequest{
			Title:     "exam of another teacher to end",
			StartTime: timestamppb.New(examStartTime),
			EndTime:   timestamppb.New(examEndTime),
		})
		require.NoError(t, err)
		id := created.GetExam().GetId()

		_, err = owner.OpenExam(t.Context(), &examv1.OpenExamRequest{Id: id})
		require.NoError(t, err)
		_, err = owner.StartExam(t.Context(), &examv1.StartExamRequest{Id: id})
		require.NoError(t, err)

		_, err = other.EndExam(t.Context(), &examv1.EndExamRequest{Id: id})
		assert.Equal(t, connect.CodeNotFound, connect.CodeOf(err))
	})

	t.Run("exam rpcs are forbidden for students", func(t *testing.T) {
		teacher := newExamClient(tcc, tcc.KcTeacherAdminToken)

		created, err := teacher.CreateExam(t.Context(), &examv1.CreateExamRequest{
			Title:     "exam a student must not touch",
			StartTime: timestamppb.New(examStartTime),
			EndTime:   timestamppb.New(examEndTime),
		})
		require.NoError(t, err)
		id := created.GetExam().GetId()

		t.Run("list exams", func(t *testing.T) {
			student := newExamClient(tcc, tcc.KcStudentToken)

			_, err := student.FindMyExams(t.Context(), &examv1.FindMyExamsRequest{})
			assert.Equal(t, connect.CodePermissionDenied, connect.CodeOf(err))
		})

		t.Run("create exam", func(t *testing.T) {
			student := newExamClient(tcc, tcc.KcStudentToken)

			_, err := student.CreateExam(t.Context(), &examv1.CreateExamRequest{
				Title:     "exam the caller may not create",
				StartTime: timestamppb.New(examStartTime),
				EndTime:   timestamppb.New(examEndTime),
			})
			assert.Equal(t, connect.CodePermissionDenied, connect.CodeOf(err))
		})

		t.Run("get exam", func(t *testing.T) {
			student := newExamClient(tcc, tcc.KcStudentToken)

			_, err := student.FindExamById(t.Context(), &examv1.FindExamByIdRequest{Id: id})
			assert.Equal(t, connect.CodePermissionDenied, connect.CodeOf(err))
		})

		t.Run("open exam", func(t *testing.T) {
			student := newExamClient(tcc, tcc.KcStudentToken)

			_, err := student.OpenExam(t.Context(), &examv1.OpenExamRequest{Id: id})
			assert.Equal(t, connect.CodePermissionDenied, connect.CodeOf(err))
		})

		t.Run("start exam", func(t *testing.T) {
			student := newExamClient(tcc, tcc.KcStudentToken)

			_, err := student.StartExam(t.Context(), &examv1.StartExamRequest{Id: id})
			assert.Equal(t, connect.CodePermissionDenied, connect.CodeOf(err))
		})

		t.Run("end exam", func(t *testing.T) {
			student := newExamClient(tcc, tcc.KcStudentToken)

			_, err := student.EndExam(t.Context(), &examv1.EndExamRequest{Id: id})
			assert.Equal(t, connect.CodePermissionDenied, connect.CodeOf(err))
		})
	})

	t.Run("exam rpcs are unauthenticated without a token", func(t *testing.T) {
		id := &commonv1.UUID{Id: unknownExamID}

		t.Run("list exams", func(t *testing.T) {
			client := newExamClient(tcc, "")

			_, err := client.FindMyExams(t.Context(), &examv1.FindMyExamsRequest{})
			assert.Equal(t, connect.CodeUnauthenticated, connect.CodeOf(err))
		})

		t.Run("create exam", func(t *testing.T) {
			client := newExamClient(tcc, "")

			_, err := client.CreateExam(t.Context(), &examv1.CreateExamRequest{
				Title:     "exam the caller may not create",
				StartTime: timestamppb.New(examStartTime),
				EndTime:   timestamppb.New(examEndTime),
			})
			assert.Equal(t, connect.CodeUnauthenticated, connect.CodeOf(err))
		})

		t.Run("get exam", func(t *testing.T) {
			client := newExamClient(tcc, "")

			_, err := client.FindExamById(t.Context(), &examv1.FindExamByIdRequest{Id: id})
			assert.Equal(t, connect.CodeUnauthenticated, connect.CodeOf(err))
		})

		t.Run("open exam", func(t *testing.T) {
			client := newExamClient(tcc, "")

			_, err := client.OpenExam(t.Context(), &examv1.OpenExamRequest{Id: id})
			assert.Equal(t, connect.CodeUnauthenticated, connect.CodeOf(err))
		})

		t.Run("start exam", func(t *testing.T) {
			client := newExamClient(tcc, "")

			_, err := client.StartExam(t.Context(), &examv1.StartExamRequest{Id: id})
			assert.Equal(t, connect.CodeUnauthenticated, connect.CodeOf(err))
		})

		t.Run("end exam", func(t *testing.T) {
			client := newExamClient(tcc, "")

			_, err := client.EndExam(t.Context(), &examv1.EndExamRequest{Id: id})
			assert.Equal(t, connect.CodeUnauthenticated, connect.CodeOf(err))
		})
	})
}
