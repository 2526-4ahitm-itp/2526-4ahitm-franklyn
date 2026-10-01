package util

import (
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
)

type ErrorResponse struct {
	Status  int    `json:"status"`
	Message string `json:"message"`
}

type HttpResponse struct {
	Status       int
	Body         any
	ExtraHeaders map[string]string
}

type HttpHandler func(*http.Request) (HttpResponse, error)

type statusError struct {
	status int
	msg    string
}

func (e statusError) Msg(format string, a ...any) statusError {
	e.msg = fmt.Sprintf(format, a...)
	return e
}

func GeneralError(status int, format string, a ...any) statusError {
	return statusError{
		status: status,
		msg:    fmt.Sprintf(format, a...),
	}
}

func (e statusError) Error() string { return e.msg }

var (
	ErrNotFound   = statusError{status: http.StatusNotFound, msg: "not found"}
	ErrBadRequest = statusError{status: http.StatusBadRequest, msg: "bad request"}
)

func Handle(h HttpHandler, logger *slog.Logger) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		res, err := h(r)

		var se statusError

		if err != nil {

			if !errors.As(err, &se) {
				se = statusError{
					status: http.StatusInternalServerError,
					msg:    "internal server error",
				}
			}

			if se.status >= 500 {
				logger.Error(
					"request failed",
					"status", se.status,
					"method", r.Method,
					"path", r.URL.Path,
					"err", err,
				)
			}

			response := ErrorResponse{
				Status:  se.status,
				Message: se.msg,
			}

			Encode(w, r, se.status, response)

			return
		}

		for k, v := range res.ExtraHeaders {
			w.Header().Set(k, v)
		}

		if res.Body == nil {
			w.WriteHeader(res.Status)
			return
		}

		Encode(w, r, res.Status, res.Body)
	}
}

func Encode[T any](w http.ResponseWriter, r *http.Request, status int, v T) error {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(v); err != nil {
		return fmt.Errorf("encode json: %w", err)
	}
	return nil
}

func Decode[T any](r *http.Request) (T, error) {
	var v T
	if err := json.NewDecoder(r.Body).Decode(&v); err != nil {
		return v, fmt.Errorf("decode json: %w", err)
	}
	return v, nil
}
