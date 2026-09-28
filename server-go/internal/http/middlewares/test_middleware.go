package middlewares

import (
	"math/rand/v2"
	"net/http"
)

func FiftyFifty(h http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if rand.IntN(2) > 0 {
			http.NotFound(w, r)
			return
		}
		h.ServeHTTP(w, r)
	})
}
