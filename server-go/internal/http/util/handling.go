package util

import (
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
)

// ErrorResponse is the JSON body sent for every failed request. Problems is
// only set for validation failures.
type ErrorResponse struct {
	Status   int      `json:"status"`
	Message  string   `json:"message"`
	Problems Problems `json:"problems,omitempty"`
}

// HttpResponse is the successful result of a HttpHandler. A nil Body writes
// only the status.
type HttpResponse struct {
	Status       int
	Body         any
	ExtraHeaders map[string]string
}

// HttpHandler is a handler that returns its result instead of writing it.
// Errors are turned into responses by Handle.
type HttpHandler func(*http.Request) (HttpResponse, error)

// statusError is an error carrying the HTTP status to answer with.
type statusError struct {
	status int
	msg    string
}

// Msg returns a copy of the error with a formatted message and the same
// status, e.g. ErrNotFound.Msg("notice %q does not exist", id).
func (e statusError) Msg(format string, a ...any) statusError {
	e.msg = fmt.Sprintf(format, a...)
	return e
}

// GeneralError returns an error that makes Handle answer with the given status
// and message.
func GeneralError(status int, format string, a ...any) statusError {
	return statusError{
		status: status,
		msg:    fmt.Sprintf(format, a...),
	}
}

func (e statusError) Error() string { return e.msg }

// Errors for the common statuses. Use Msg to add a specific message.
var (
	ErrNotFound   = statusError{status: http.StatusNotFound, msg: "not found"}
	ErrBadRequest = statusError{status: http.StatusBadRequest, msg: "bad request"}
)

// Handle adapts a HttpHandler to a http.HandlerFunc and writes its result as
// JSON. Errors become an ErrorResponse: a ValidationError answers 400 with the
// problems, an error from GeneralError or ErrNotFound/ErrBadRequest answers
// with its own status, anything else answers 500. Only responses with status
// 500 and above are logged.
func Handle(h HttpHandler, logger *slog.Logger) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		res, err := h(r)

		var se statusError

		if err != nil {

			var errorResponse ErrorResponse = ErrorResponse{
				Status:  se.status,
				Message: se.msg,
			}

			if validationError, ok := errors.AsType[ValidationError](err); ok {
				errorResponse = ErrorResponse{
					Status:   http.StatusBadRequest,
					Message:  "validation failed. see `problems` for more information",
					Problems: validationError.Problems,
				}
			} else if !errors.As(err, &se) {
				errorResponse = ErrorResponse{
					Status:  http.StatusInternalServerError,
					Message: "internal server error",
				}
			}

			if errorResponse.Status >= 500 {
				logger.Error(
					"request failed",
					"status", se.status,
					"method", r.Method,
					"path", r.URL.Path,
					"err", err,
				)
			}

			Encode(w, r, errorResponse.Status, errorResponse)

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

// Encode writes v as a JSON response with the given status.
func Encode[T any](w http.ResponseWriter, r *http.Request, status int, v T) error {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(v); err != nil {
		return fmt.Errorf("encode json: %w", err)
	}
	return nil
}

// Decode reads the JSON request body into T.
func Decode[T any](r *http.Request) (T, error) {
	var v T
	if err := json.NewDecoder(r.Body).Decode(&v); err != nil {
		return v, fmt.Errorf("decode json: %w", err)
	}
	return v, nil
}
