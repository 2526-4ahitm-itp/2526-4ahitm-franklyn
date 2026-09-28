package handlers

import (
	"fmt"
	"net/http"
)

func HandleTest() http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "hello world")
	}
}
