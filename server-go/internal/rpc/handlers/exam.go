package handlers

import (
	"context"
	"database/sql"
	"errors"
	"log/slog"
	"math/rand"
	"time"

	"connectrpc.com/connect/v2"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/config"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/db"
	commonv1 "github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/proto/franklyn/common/v1"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/proto/franklyn/exam/common"
	examv1 "github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/proto/franklyn/exam/v1"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/rpc/middleware"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/rpc/util"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/service"
	"github.com/google/uuid"
	"github.com/jackc/pgerrcode"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	"google.golang.org/protobuf/types/known/timestamppb"
)

type ExamService struct {
	logger *slog.Logger
	q      *db.Queries
	pool   *pgxpool.Pool
	cfg    *config.Config
}

func NewExamService(logger *slog.Logger, q *db.Queries, pool *pgxpool.Pool, cfg *config.Config) *ExamService {
	return &ExamService{logger, q, pool, cfg}
}

func mapDbExamToProtoExam(dbExam *db.FrExam) (*common.Exam, error) {
	var state common.ExamState
	switch dbExam.State {
	case db.FrExamStateTypeOpen:
		state = common.ExamState_EXAM_STATE_OPEN
	case db.FrExamStateTypeLive:
		state = common.ExamState_EXAM_STATE_LIVE
	case db.FrExamStateTypeEnded:
		state = common.ExamState_EXAM_STATE_ENDED
	case db.FrExamStateTypeScheduled:
		state = common.ExamState_EXAM_STATE_SCHEDULED
	default:
		state = common.ExamState_EXAM_STATE_UNSPECIFIED
	}

	return &common.Exam{
		Id: &commonv1.UUID{
			Id: dbExam.ID.String(),
		},
		TeacherId: &commonv1.UUID{
			Id: dbExam.TeacherID.String(),
		},
		State:              state,
		Title:              dbExam.Title,
		Pin:                int32(dbExam.Pin),
		PreopenTimeMinutes: int32(dbExam.PreopenTimeMinutes),

		StartTime: timestamppb.New(dbExam.StartTime),
		EndTime:   timestamppb.New(dbExam.EndTime),
	}, nil

}

func wrapErr(e error, log *slog.Logger) error {
	if errors.Is(e, sql.ErrNoRows) {
		return connect.NewError(connect.CodeNotFound, "exam not found")
	}

	var pgErr *pgconn.PgError
	if errors.As(e, &pgErr) && pgErr.Code == pgerrcode.ForeignKeyViolation {
		return connect.NewError(connect.CodeNotFound, "teacher not found")
	}

	if errNotFound, ok := errors.AsType[*service.ErrEntityNotFound](e); ok {
		return connect.NewError(connect.CodeNotFound, errNotFound.Error())
	}

	if errors.Is(e, middleware.ErrMissingRoles) {
		return connect.NewError(connect.CodePermissionDenied, "missing roles")
	}

	if errors.Is(e, middleware.ErrUserMismatchError) {
		return connect.NewError(connect.CodePermissionDenied, "unauthorized user")
	}

	if errors.Is(e, service.ErrExamNotLive) ||
		errors.Is(e, service.ErrExamNotOpen) ||
		errors.Is(e, service.ErrExamNotScheduled) {
		return connect.NewError(connect.CodeFailedPrecondition, e.Error())
	}

	if errors.Is(e, middleware.ErrJwtUserNotInContext) {
		log.Error("internal: jwt user not in context")
	}

	if errors.Is(e, middleware.ErrUserNotInContext) {
		log.Error("internal: user not in context")
	}

	return connect.NewError(connect.CodeInternal, "internal server error")
}

func validateCreateExamRequest(req *examv1.CreateExamRequest) (bool, *connect.ErrorDetail, error) {

	p := util.Problems{}

	if req == nil {
		details, err := p.ToBadRequestViolations()
		return false, details, err
	}

	p.Require(req.StartTime != nil, "start_time", "must not be null")
	p.Require(req.EndTime != nil, "end_time", "must not be null")
	if req.StartTime != nil {
		err := req.StartTime.CheckValid()
		if err != nil {
			p.Require(err != nil, "start_time", err.Error())
		} else {
			p.Require(
				req.StartTime.AsTime().After(time.Now()),
				"start_time",
				"must be in the future",
			)
		}
	}
	if req.EndTime != nil {
		err := req.EndTime.CheckValid()
		if err != nil {
			p.Require(err != nil, "end_time", err.Error())
		}
	}

	if req.StartTime != nil && req.EndTime != nil {
		p.Require(
			req.StartTime.AsTime().Before(req.EndTime.AsTime()),
			"end_time",
			"must be after start_time",
		)
	}

	details, err := p.ToBadRequestViolations()

	return len(p) == 0, details, err
}

func (s *ExamService) CreateExam(ctx context.Context, req *examv1.CreateExamRequest) (*examv1.CreateExamResponse, error) {
	ok, errDetails, err := validateCreateExamRequest(req)

	if !ok && err == nil {
		return nil, connect.NewError(connect.CodeInvalidArgument, "bad request").
			WithDetail(errDetails)
	}
	if err != nil {
		return nil, connect.NewError(connect.CodeInvalidArgument, "bad request")
	}

	idToken, err := middleware.JwtUser(ctx)

	if err != nil {
		return nil, wrapErr(err, s.logger)
	}

	user, err := middleware.User(ctx)

	if err != nil {
		return nil, wrapErr(err, s.logger)
	}

	if err = middleware.RequireUserType(user, db.FrUserTypeTEACHER); err != nil {
		return nil, wrapErr(err, s.logger)
	}

	// TODO: an existing pin will fail with Unique failure, retry on this error

	pin := (int16)(rand.Intn((int)(s.cfg.PinMax-s.cfg.PinMin))) + s.cfg.PinMin

	exam, err := db.InTxV(ctx, s.pool, func(q *db.Queries) (*db.FrExam, error) {
		persistedUser, err := service.PersistedUser(
			ctx,
			q,
			idToken,
			s.cfg,
		)

		if err != nil {
			return nil, err
		}

		preopenTime := s.cfg.DefaultPreopenTimeMinutes
		if req.PreopenTimeMinutes != nil {
			preopenTime = req.GetPreopenTimeMinutes()
		}

		return q.CreateExam(ctx, db.CreateExamParams(db.CreateExamParams{
			TeacherID:          &persistedUser.ID,
			Title:              req.GetTitle(),
			StartTime:          req.GetStartTime().AsTime(),
			EndTime:            req.GetEndTime().AsTime(),
			Pin:                pin,
			PreopenTimeMinutes: preopenTime,
		}))

	})

	if err != nil {
		return nil, wrapErr(err, s.logger)
	}

	protoExam, err := mapDbExamToProtoExam(exam)

	if err != nil {
		return nil, wrapErr(err, s.logger)
	}

	return &examv1.CreateExamResponse{
		Exam: protoExam,
	}, nil
}

func (s *ExamService) FindMyExams(ctx context.Context, _ *examv1.FindMyExamsRequest) (*examv1.FindMyExamsResponse, error) {
	user, err := middleware.User(ctx)

	if err != nil {
		return nil, wrapErr(err, s.logger)
	}

	if err = middleware.RequireUserType(user, db.FrUserTypeTEACHER); err != nil {
		return nil, wrapErr(err, s.logger)
	}

	exams, err := db.InTxV(ctx, s.pool, func(q *db.Queries) ([]*db.FrExam, error) {
		return q.FindExamByTeacherId(ctx, &user.ID)
	})

	if err != nil {
		return nil, wrapErr(err, s.logger)
	}

	protoExams := []*common.Exam{}

	for _, exam := range exams {
		pe, err := mapDbExamToProtoExam(exam)
		if err != nil {
			return nil, wrapErr(err, s.logger)
		}
		protoExams = append(protoExams, pe)
	}

	return &examv1.FindMyExamsResponse{
		Exam: protoExams,
	}, nil
}

func (s *ExamService) FindExamById(ctx context.Context, req *examv1.FindExamByIdRequest) (*examv1.FindExamByIdResponse, error) {

	if req == nil || req.Id == nil {
		return nil, connect.NewError(connect.CodeInvalidArgument, "bad request")
	}

	user, err := middleware.User(ctx)

	if err != nil {
		return nil, wrapErr(err, s.logger)
	}

	if err = middleware.RequireUserType(user, db.FrUserTypeTEACHER); err != nil {
		return nil, wrapErr(err, s.logger)
	}

	exam, err := db.InTxV(ctx, s.pool, func(q *db.Queries) (*db.FrExam, error) {
		return q.FindExamByTeacherIdAndId(ctx,
			db.FindExamByTeacherIdAndIdParams{
				ID:        uuid.MustParse(req.GetId().GetId()),
				TeacherID: &user.ID,
			})
	})

	if err != nil {
		return nil, wrapErr(err, s.logger)
	}

	protoExam, err := mapDbExamToProtoExam(exam)

	if err != nil {
		return nil, wrapErr(err, s.logger)
	}

	return &examv1.FindExamByIdResponse{
		Exam: protoExam,
	}, nil
}

func (s *ExamService) OpenExam(ctx context.Context, req *examv1.OpenExamRequest) (*examv1.OpenExamResponse, error) {
	if req == nil || req.Id == nil {
		return nil, connect.NewError(connect.CodeInvalidArgument, "bad request")
	}

	user, err := middleware.User(ctx)

	if err != nil {
		return nil, wrapErr(err, s.logger)
	}

	if err = middleware.RequireUserType(user, db.FrUserTypeTEACHER); err != nil {
		return nil, wrapErr(err, s.logger)
	}

	updatedExam, err := db.InTxV(ctx, s.pool, func(q *db.Queries) (*db.FrExam, error) {
		return service.OpenExam(ctx, q, false, uuid.MustParse(req.GetId().GetId()), &user.ID)
	})

	if err != nil {
		return nil, wrapErr(err, s.logger)
	}

	protoExam, err := mapDbExamToProtoExam(updatedExam)

	if err != nil {
		return nil, wrapErr(err, s.logger)
	}

	return &examv1.OpenExamResponse{
		Exam: protoExam,
	}, nil
}

func (s *ExamService) StartExam(ctx context.Context, req *examv1.StartExamRequest) (*examv1.StartExamResponse, error) {
	if req == nil || req.Id == nil {
		return nil, connect.NewError(connect.CodeInvalidArgument, "bad request")
	}

	user, err := middleware.User(ctx)

	if err != nil {
		return nil, wrapErr(err, s.logger)
	}

	if err = middleware.RequireUserType(user, db.FrUserTypeTEACHER); err != nil {
		return nil, wrapErr(err, s.logger)
	}

	updatedExam, err := db.InTxV(ctx, s.pool, func(q *db.Queries) (*db.FrExam, error) {
		return service.StartExam(ctx, q, false, uuid.MustParse(req.GetId().GetId()), &user.ID)
	})

	if err != nil {
		return nil, wrapErr(err, s.logger)
	}

	protoExam, err := mapDbExamToProtoExam(updatedExam)

	if err != nil {
		return nil, wrapErr(err, s.logger)
	}

	return &examv1.StartExamResponse{
		Exam: protoExam,
	}, nil
}

func (s *ExamService) EndExam(ctx context.Context, req *examv1.EndExamRequest) (*examv1.EndExamResponse, error) {
	if req == nil || req.Id == nil {
		return nil, connect.NewError(connect.CodeInvalidArgument, "bad request")
	}

	user, err := middleware.User(ctx)

	if err != nil {
		return nil, wrapErr(err, s.logger)
	}

	if err = middleware.RequireUserType(user, db.FrUserTypeTEACHER); err != nil {
		return nil, wrapErr(err, s.logger)
	}

	updatedExam, err := db.InTxV(ctx, s.pool, func(q *db.Queries) (*db.FrExam, error) {
		return service.EndExam(ctx, q, false, uuid.MustParse(req.GetId().GetId()), &user.ID)
	})

	if err != nil {
		return nil, wrapErr(err, s.logger)
	}

	protoExam, err := mapDbExamToProtoExam(updatedExam)

	if err != nil {
		return nil, wrapErr(err, s.logger)
	}

	return &examv1.EndExamResponse{
		Exam: protoExam,
	}, nil

}
