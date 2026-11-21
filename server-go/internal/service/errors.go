package service

import (
	"fmt"

	"github.com/google/uuid"
)

type ErrEntityNotFound struct {
	Name string
	ID   *uuid.UUID
}

func (e *ErrEntityNotFound) Error() string {
	return fmt.Sprintf("Entity `%s` with id `%s` not found!", e.Name, e.ID)
}
