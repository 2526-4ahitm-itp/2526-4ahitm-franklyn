package middlewares

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"slices"
	"strings"

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

func GetJwtUser(ctx context.Context) (*oidc.IDToken, bool) {
	u, ok := ctx.Value(requestJwtUser).(*oidc.IDToken)

	return u, ok
}

func AuthRequired(h http.Handler, logger *slog.Logger, oidc service.OIDC) http.Handler {
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

		h.ServeHTTP(w, r.WithContext(ctx))
	})
}

func RequireRoles(roles []string, h http.Handler, logger *slog.Logger) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {

		var rolesClaims struct {
			RealmAccess struct {
				Roles []string `json:"roles"`
			} `json:"realm_access"`
		}

		idToken, ok := GetJwtUser(r.Context())

		if !ok {
			_ = util.Encode(w, r, http.StatusUnauthorized, util.ErrorResponse{
				Status: http.StatusUnauthorized,
			})
			return
		}

		err := idToken.Claims(&rolesClaims)

		if err != nil {
			_ = util.Encode(w, r, http.StatusUnauthorized, util.ErrorResponse{
				Status: http.StatusUnauthorized,
			})
			return
		}

		for _, v := range roles {
			if slices.Contains(rolesClaims.RealmAccess.Roles, v) {
				h.ServeHTTP(w, r)
				return
			}
		}

		_ = util.Encode(w, r, http.StatusForbidden, util.ErrorResponse{
			Status:  http.StatusForbidden,
			Message: "You are authenticated but miss certain permissions!",
		})
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
