package middlewares

import (
	"fmt"
	"log/slog"
	"net/http"
	"slices"

	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/db"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/http/util"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/service"
)

func CreateRequireRoles(roles []string) func(h http.Handler) http.Handler {
	return func(h http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {

			var rolesClaims struct {
				RealmAccess struct {
					Roles []string `json:"roles"`
				} `json:"realm_access"`
			}

			idToken, err := GetJwtUser(r.Context())

			if err != nil {
				_ = util.Encode(w, r, http.StatusUnauthorized, util.ErrorResponse{
					Status: http.StatusUnauthorized,
				})
				return
			}

			err = idToken.Claims(&rolesClaims)

			if err != nil {
				_ = util.Encode(w, r, http.StatusUnauthorized, util.ErrorResponse{
					Status:  http.StatusUnauthorized,
					Message: err.Error(),
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
}

func CreateRequireType(userType db.FrUserType, logger *slog.Logger) func(h http.HandlerFunc) http.Handler {
	return func(h http.HandlerFunc) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			user, err := GetFrUser(r.Context())

			if err != nil {
				_ = util.Encode(w, r, http.StatusUnauthorized, util.ErrorResponse{
					Status: http.StatusUnauthorized,
				})
				return
			}

			if err := service.RequireRole(user, userType); err != nil {
				_ = util.Encode(w, r, http.StatusForbidden, util.ErrorResponse{
					Status:  http.StatusForbidden,
					Message: fmt.Sprintf("You (%s) are not allowed to access this resource", user.Role),
				})
				return
			}

			h.ServeHTTP(w, r)
		})
	}
}
