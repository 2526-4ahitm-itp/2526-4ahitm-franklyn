package middlewares

import (
	"context"
	"log/slog"
	"net/http"
)

type requestJwtUserType struct{}

var RequestJwtUser = &requestJwtUserType{}

var authBlacklist = []string{
	"/health",
}

func AuthRequired(h http.Handler, logger *slog.Logger) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// if slices.Contains(authBlacklist, r.URL.Path) {
		// 	h.ServeHTTP(w, r)
		// }

		ctx := context.WithValue(r.Context(), RequestJwtUser, 2)

		h.ServeHTTP(w, r.WithContext(ctx))
	})
}
