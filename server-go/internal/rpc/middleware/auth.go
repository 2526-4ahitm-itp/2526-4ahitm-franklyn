package middleware

import (
	"context"
	"fmt"
	"log/slog"
	"slices"
	"strings"

	"connectrpc.com/connect/v2"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/config"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/db"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/service"
	"github.com/coreos/go-oidc/v3/oidc"
)

type authMiddlewareError string

var (
	ErrJwtUserNotInContext authMiddlewareError = "jwt user not in context"
	ErrUserNotInContext    authMiddlewareError = "user not in context"

	ErrUserMismatchError authMiddlewareError = "user is not the expected type"
	ErrRolesFailed       authMiddlewareError = "failed to get roles from id token"
	ErrMissingRoles      authMiddlewareError = "user does not have the required roles"
)

func (s authMiddlewareError) Error() string {
	return string(s)
}

type requestJwtUserType int
type requestUserType int

var requestJwtUser requestJwtUserType
var requestUser requestUserType

func JwtUser(ctx context.Context) (*oidc.IDToken, error) {
	token, ok := ctx.Value(requestJwtUser).(*oidc.IDToken)
	if token == nil || !ok {
		return nil, ErrJwtUserNotInContext
	}
	return token, nil
}

func User(ctx context.Context) (*db.FrUser, error) {
	token, ok := ctx.Value(requestUser).(*db.FrUser)
	if token == nil || !ok {
		return nil, ErrUserNotInContext
	}
	return token, nil
}

func NewAuthInterceptor(cfg *config.Config, q *db.Queries, logger *slog.Logger, oidc *service.OIDC) connect.ServerInterceptor {
	return func(next connect.ServerFunc) connect.ServerFunc {
		return func(ctx context.Context, spec connect.Spec, stream connect.ServerStream) error {
			info, ok := connect.CallInfoForServerContext(ctx)

			if !ok {
				return connect.NewError(connect.CodeUnauthenticated, "no token")
			}

			authHedaer := info.RequestHeader().Get("Authorization")

			if authHedaer == "" {
				return connect.NewError(connect.CodeUnauthenticated, "no token")
			}

			token, err := bearerToken(authHedaer)

			if err != nil {
				return connect.NewError(connect.CodeUnauthenticated, "no token")
			}

			idToken, err := oidc.TokenVerifier.Verify(ctx, token)

			if err != nil {
				return connect.NewError(
					connect.CodeUnauthenticated,
					"token verification failed",
				)
			}

			nctx := context.WithValue(ctx, requestJwtUser, idToken)

			user, err := service.JwtUser(idToken, cfg)

			if err != nil {
				logger.Error(err.Error() +
					"Consider taking a look at the configuration! " +
					"Make sure that FRANKLYN_ROLE_CLAIM is contained " +
					"in the idToken in Keycloak!")
				return connect.NewError(
					connect.CodeInternal,
					"failed to get valid user from idToken",
				)
			}

			nctx = context.WithValue(nctx, requestUser, user)

			return next(nctx, spec, stream)
		}
	}
}

func RequireUserType(user *db.FrUser, role db.FrUserType) error {
	if user.Role == role {
		return nil
	}
	return ErrUserMismatchError
}

func RequireRole(ctx context.Context, roles []string) error {
	var rolesClaims struct {
		RealmAccess struct {
			Roles []string `json:"roles"`
		} `json:"realm_access"`
	}

	idToken, err := JwtUser(ctx)

	if err != nil {
		return ErrRolesFailed
	}

	err = idToken.Claims(&rolesClaims)

	if err != nil {
		return ErrRolesFailed
	}

	for _, v := range roles {
		if slices.Contains(rolesClaims.RealmAccess.Roles, v) {
			return nil
		}
	}

	return ErrMissingRoles
}

func bearerToken(header string) (string, error) {
	scheme, token, ok := strings.Cut(header, " ")
	if !ok || !strings.EqualFold(scheme, "Bearer") {
		return "", fmt.Errorf("invalid scheme")
	}
	token = strings.TrimSpace(token)
	if token == "" {
		return "", fmt.Errorf("empty token")
	}
	return token, nil
}
