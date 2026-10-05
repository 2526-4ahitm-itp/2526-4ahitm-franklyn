// The service package encapsulates logic between the representation and the
// data layer.
// Users are hidden behind the service functions so complete user operations can
// be guarenteed. In this service, the composition of user and teacher/student
// are safely encapsulated. The entire application should only interact with
// presistent users through this service.
package service

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/config"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/db"
	"github.com/coreos/go-oidc/v3/oidc"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
)

type UserMismatchError struct {
	Want db.FrUserType
	Got  db.FrUserType
}

func (u UserMismatchError) Error() string {
	return fmt.Sprintf(
		"Required user of type `%s` but got `%s`.",
		u.Want, u.Got,
	)
}

type jwtUserClaims struct {
	/*
	   "scope": "openid email profile",
	   "email_verified": true,
	   "name": "Tina Teacher",
	   "distinguished_name": "CN=Tina Teacher,OU=Teachers,DC=htl-leonding,DC=ac,DC=at",
	   "preferred_username": "teacher",
	   "given_name": "Tina",
	   "family_name": "Teacher",
	   "email": "teacher@franklyn.test"
	*/
	Sub               string      `json:"sub"`
	Name              string      `json:"name"`
	DistinguishedName string      `json:"distinguished_name"`
	PreferredUsername string      `json:"preferred_username"`
	GivenName         pgtype.Text `json:"given_name"`
	FamilyName        pgtype.Text `json:"family_name"`
	Email             string      `json:"email"`
}

func lookup(claims map[string]any, path string) (any, bool) {
	var cur any = claims
	for seg := range strings.SplitSeq(path, ".") {
		m, ok := cur.(map[string]any)
		if !ok {
			return nil, false
		}
		cur, ok = m[seg]
		if !ok {
			return nil, false
		}
	}
	return cur, true
}

func getJwtUserRole(t *oidc.IDToken, cfg *config.Config) (uType db.FrUserType, err error) {
	var claims map[string]any

	err = t.Claims(&claims)

	if err != nil {
		return
	}

	raw, ok := lookup(claims, cfg.RoleClaim)

	if !ok {
		err = errors.New("failed to lookup claim in the idToken")
		return
	}

	var checkClaim []string

	switch v := raw.(type) {
	case string:
		if cfg.RoleClaimSeparator == "" {
			checkClaim = []string{v}
		} else {
			checkClaim = strings.Split(v, cfg.RoleClaimSeparator)
		}
	case []any:
		checkClaim = []string{}

		for _, e := range v {
			switch vv := e.(type) {
			case string:
				checkClaim = append(checkClaim, vv)
			}
		}
	default:
		err = errors.New("claim is not type of string")
		return
	}
	for _, e := range checkClaim {
		switch strings.TrimSpace(e) {
		case cfg.RoleStudent:
			uType = db.FrUserTypeSTUDENT
		case cfg.RoleTeacher:
			uType = db.FrUserTypeTEACHER
		}
		if uType != "" {
			break
		}
	}

	if uType == "" {
		err = errors.New("user failed to classify as either STUDENT or TEACHER")
	}
	return
}

func JwtUser(t *oidc.IDToken, cfg *config.Config) (user db.FrUser, err error) {
	var claims jwtUserClaims

	err = t.Claims(&claims)

	if err != nil {
		return
	}

	userType, err := getJwtUserRole(t, cfg)

	if err != nil {
		return
	}

	userUUID, err := uuid.Parse(claims.Sub)

	if err != nil {
		return
	}

	user = db.FrUser{
		ID:                userUUID,
		PreferredUsername: claims.PreferredUsername,
		Email:             claims.Email,
		GivenName:         claims.GivenName,
		FamilyName:        claims.FamilyName,
		Role:              userType,
	}

	return
}

func PersistedUser(ctx context.Context, q *db.Queries, t *oidc.IDToken, cfg *config.Config) (user db.FrUser, err error) {
	jwtUser, err := JwtUser(t, cfg)

	if err != nil {
		return
	}

	provisionedUser, err := q.ProvisionUser(ctx, db.ProvisionUserParams{
		ID:                jwtUser.ID,
		Email:             jwtUser.Email,
		PreferredUsername: jwtUser.PreferredUsername,
		GivenName:         jwtUser.GivenName,
		FamilyName:        jwtUser.FamilyName,
		Role:              jwtUser.Role,
	})

	if err != nil {
		return
	}

	user = db.FrUser(provisionedUser)

	return
}

func RequireRole(u db.FrUser, want db.FrUserType) error {
	if u.Role != want {
		return UserMismatchError{Want: want, Got: u.Role}
	}
	return nil
}
