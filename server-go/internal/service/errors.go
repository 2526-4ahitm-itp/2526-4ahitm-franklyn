package service

import (
	"fmt"

	"github.com/google/uuid"
)

type serviceError string

const (
	ErrExamNotScheduled serviceError = "exam is not in scheduled state"
	ErrExamNotOpen      serviceError = "exam is not in open state"
	ErrExamNotLive      serviceError = "exam is not in live state"
)

func (s serviceError) Error() string {
	return string(s)
}

type ErrEntityNotFound struct {
	Name string
	ID   *uuid.UUID
}

func (e *ErrEntityNotFound) Error() string {
	return fmt.Sprintf("Entity `%s` with id `%s` not found!", e.Name, e.ID)
}
