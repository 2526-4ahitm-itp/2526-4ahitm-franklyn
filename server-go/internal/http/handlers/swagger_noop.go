//go:build !dev

package handlers

import "net/http"

var SwaggerHandler http.HandlerFunc = func(w http.ResponseWriter, r *http.Request) {

}
