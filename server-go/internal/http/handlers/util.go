package handlers

import (
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"net/http"

	"github.com/google/uuid"
)

type ErrorResponse struct {
	Status  int    `json:"status"`
	Message string `json:"message"`
}

type ErrHandler func(http.ResponseWriter, *http.Request) error

func Handle(h ErrHandler, logger *slog.Logger) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if err := h(w, r); err != nil {
			logger.WithGroup("handle").Error("request failed", "path", r.URL.Path, "err", err)
			http.Error(w, "internal server error", 500)
		}
	}
}

func encode[T any](w http.ResponseWriter, r *http.Request, status int, v T) error {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(v); err != nil {
		return fmt.Errorf("encode json: %w", err)
	}
	return nil
}

func decode[T any](r *http.Request) (T, error) {
	var v T
	if err := json.NewDecoder(r.Body).Decode(&v); err != nil {
		return v, fmt.Errorf("decode json: %w", err)
	}
	return v, nil
}

func getIdPathParam(r *http.Request) (uuid.UUID, error) {

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
