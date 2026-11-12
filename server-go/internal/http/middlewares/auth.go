package middlewares

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"slices"
	"strings"

	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/config"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/db"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/http/util"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/service"
	"github.com/coreos/go-oidc/v3/oidc"
)

var (
	ErrNoAuthHeader  = errors.New("missing authorization header")
	ErrInvalidScheme = errors.New("authorization scheme is not bearer")
	ErrEmptyToken    = errors.New("empty bearer token")
)

var authBlacklist = []string{
	"/health",
}

type requestJwtUserType int

var requestJwtUser requestJwtUserType

func GetJwtUser(ctx context.Context) (*oidc.IDToken, error) {
	u, ok := ctx.Value(requestJwtUser).(*oidc.IDToken)

	if !ok {
		return u, errors.New("jwt user missing from context")
	}

	return u, nil
}

type requestFrUserType int

var requestFrUser requestFrUserType

func GetFrUser(ctx context.Context) (db.FrUser, error) {
	u, ok := ctx.Value(requestFrUser).(db.FrUser)

	if !ok {
		return u, errors.New("franklyn user missing from context")
	}

	return u, nil
}

func AuthRequired(h http.Handler, logger *slog.Logger, oidc service.OIDC, cfg *config.Config) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if slices.Contains(authBlacklist, r.URL.Path) {
			h.ServeHTTP(w, r)
			return
		}
		token, err := bearerToken(r)

		if err != nil {
			_ = util.Encode(w, r, http.StatusUnauthorized, util.ErrorResponse{
				Status:  http.StatusUnauthorized,
				Message: err.Error(),
			})
			return
		}

		idToken, err := oidc.TokenVerifier.Verify(r.Context(), token)

		if err != nil {
			_ = util.Encode(w, r, http.StatusUnauthorized, util.ErrorResponse{
				Status:  http.StatusUnauthorized,
				Message: "Token could not be verified!",
			})
			return
		}

		ctx := context.WithValue(r.Context(), requestJwtUser, idToken)

		user, err := service.JwtUser(idToken, cfg)

		if err != nil {
			_ = util.Encode(w, r, http.StatusBadRequest, util.ErrorResponse{
				Status:  http.StatusBadRequest,
				Message: "failed to get a valid user from idToken",
			})
			return
		}

		ctx = context.WithValue(ctx, requestFrUser, user)

		h.ServeHTTP(w, r.WithContext(ctx))
	})
}

func bearerToken(r *http.Request) (string, error) {
	h := r.Header.Get("Authorization")
	if h == "" {
		return "", ErrNoAuthHeader
	}
	scheme, token, ok := strings.Cut(h, " ")
	if !ok || !strings.EqualFold(scheme, "Bearer") {
		return "", ErrInvalidScheme
	}
	token = strings.TrimSpace(token)
	if token == "" {
		return "", ErrEmptyToken
	}
	return token, nil
}
