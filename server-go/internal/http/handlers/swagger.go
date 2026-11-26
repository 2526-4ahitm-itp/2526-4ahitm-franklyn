//go:build dev

package handlers

import (
	"net/http"

	httpSwagger "github.com/swaggo/http-swagger/v2"
)

var SwaggerHandler http.HandlerFunc = httpSwagger.WrapHandler
