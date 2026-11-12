package util

import (
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"net/http"

	"github.com/google/uuid"
)

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

// ErrorResponse is an error carrying the HTTP status to answer with.
type ErrorResponse struct {
	Status   int      `json:"status"`
	Message  string   `json:"message"`
	Problems Problems `json:"problems,omitempty"`
}

// Msg returns a copy of the error with a formatted message and the same
// status, e.g. ErrNotFound.Msg("notice %q does not exist", id).
func (e ErrorResponse) Msg(format string, a ...any) ErrorResponse {
	e.Message = fmt.Sprintf(format, a...)
	return e
}

func (e ErrorResponse) Error() string { return e.Message }

// Errors for the common statuses. Use Msg to add a specific message.
var (
	// Create a 404 Error with an entity name and the not found id.
	ErrEntityNotFound = func(entity string, id uuid.UUID) ErrorResponse {
		return ErrorResponse{
			Status:  http.StatusNotFound,
			Message: fmt.Sprintf("Entity `%s` with id `%s` not found!", entity, id),
		}
	}
	ErrNotFound   = ErrorResponse{Status: http.StatusNotFound, Message: "not found"}
	ErrBadRequest = ErrorResponse{Status: http.StatusBadRequest, Message: "bad request"}
)

// Handle adapts a HttpHandler to a http.HandlerFunc and writes its result as
// JSON. Errors become an errorResponse: a ValidationError answers 400 with the
// problems, an error from GeneralError or ErrNotFound/ErrBadRequest answers
// with its own status, anything else answers 500. Only responses with status
// 500 and above are logged.
func Handle(h HttpHandler, logger *slog.Logger) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		res, err := h(r)

		if err != nil {

			var errResponse ErrorResponse

			if validationError, ok := errors.AsType[ValidationError](err); ok {
				errResponse = ErrorResponse{
					Status:   http.StatusBadRequest,
					Message:  "validation failed. see `problems` for more information",
					Problems: validationError.Problems,
				}
			} else if se, ok := errors.AsType[ErrorResponse](err); ok {
				errResponse = ErrorResponse{
					Status:  se.Status,
					Message: se.Message,
				}
			} else if errors.Is(err, DecodeError) {
				errResponse = ErrorResponse{
					Status:  http.StatusBadRequest,
					Message: err.Error(),
				}
			} else {
				errResponse = ErrorResponse{
					Status:  http.StatusInternalServerError,
					Message: "internal server error",
				}
			}

			if errResponse.Status >= 500 {
				logger.Error(
					"request failed",
					"status", errResponse.Status,
					"message", errResponse.Message,
					"method", r.Method,
					"path", r.URL.Path,
					"err", err,
				)
			}

			if err := Encode(w, r, errResponse.Status, errResponse); err != nil {
				logger.Error("sending error response failed with error", "error", err)
			}

			return
		}

		for k, v := range res.ExtraHeaders {
			w.Header().Set(k, v)
		}

		if res.Body == nil {
			w.WriteHeader(res.Status)
			return
		}

		if err := Encode(w, r, res.Status, res.Body); err != nil {
			logger.Error("sending response failed with error", "error", err)
		}
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

type Error string

func (e Error) Error() string { return string(e) }

const DecodeError Error = "decode json"

// Decode reads the JSON request body into T.
func Decode[T any](r *http.Request) (T, error) {
	var v T
	if err := json.NewDecoder(r.Body).Decode(&v); err != nil {
		return v, fmt.Errorf("%w: %w", DecodeError, err)
	}
	return v, nil
}
