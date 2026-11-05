package util

import (
	"errors"
	"net/http"

	"github.com/google/uuid"
)

func GetIdPathParam(r *http.Request) (uuid.UUID, error) {

	pathValue := r.PathValue("id")

	if pathValue == "" {
		return uuid.UUID{}, errors.New(`PathValue "id" not present`)
	}

	id, err := uuid.Parse(r.PathValue("id"))

	if err != nil {
		return uuid.UUID{}, err
	}

	return id, nil
}
