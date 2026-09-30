package handlers

import (
	"fmt"
	"log/slog"
	"net/http"
)

func HandleThis(logger *slog.Logger) http.HandlerFunc {
	return Handle(func(w http.ResponseWriter, r *http.Request) error {
		fmt.Fprint(w, "This is a response")

		return nil
	}, logger)
}
