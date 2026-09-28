// The service package encapsulates logic between the representation and the
// data layer.
// Users are hidden behind the service functions so complete user operations can
// be guarenteed. In this service, the composition of user and teacher/student
// are safely encapsulated. The entire application should only interact with
// presistent users through this service.
package service

import (
	"context"
	"database/sql"
	"errors"

	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/db"
	"github.com/google/uuid"
)

var ErrUserNotFound = errors.New("student not found")

func LoadUser(ctx context.Context, q *db.Queries, id uuid.UUID) (db.FrUser, error) {
	user, err := q.FindByID(ctx, id)

	if errors.Is(err, sql.ErrNoRows) {
		return db.FrUser{}, ErrUserNotFound
	}

	if err != nil {
		return db.FrUser{}, err
	}

	return user, nil
}

func LoadStudent(ctx context.Context, q *db.Queries, id uuid.UUID) (db.GetStudentRow, error) {

	student, err := q.GetStudent(ctx, id)

	if errors.Is(err, sql.ErrNoRows) {
		return db.GetStudentRow{}, ErrUserNotFound
	}

	if err != nil {
		return db.GetStudentRow{}, err
	}

	return student, nil
}

func LoadTeacher(ctx context.Context, q *db.Queries, id uuid.UUID) (db.GetTeacherRow, error) {

	teacher, err := q.GetTeacher(ctx, id)

	if errors.Is(err, sql.ErrNoRows) {
		return db.GetTeacherRow{}, ErrUserNotFound
	}

	if err != nil {
		return db.GetTeacherRow{}, err
	}

	return teacher, nil
}
