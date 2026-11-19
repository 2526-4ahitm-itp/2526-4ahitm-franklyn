package service

import (
	"encoding/json"
	"errors"
	"fmt"

	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/apperr"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/config"
	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/db"
	"github.com/coreos/go-oidc/v3/oidc"
	"github.com/google/uuid"
)

const (
	CodeEntityNotFound        = "ENTITY_NOT_FOUND"
	CodeExamStateMismatch     = "EXAM_STATE_MISMATCH"
	CodeUserTypeMismatch      = "USER_TYPE_MISMATCH"
	CodeClaimNotString        = "CLAIM_NOT_STRING"
	CodeCannotClassifyUser    = "CANNOT_CLASSIFY_USER"
	CodeRoleClaimLookupFailed = "ROLE_CLAIM_LOOKUP_FAILED"
)

type RoleClaimLookupError struct {
	Token     *oidc.IDToken
	RoleClaim string
}

var safeClaims = map[string]bool{
	"iss": true, "aud": true, "azp": true, "exp": true, "iat": true,
}

func (cle RoleClaimLookupError) Error() string {
	var claimsJSON = "{failed to read claims}"

	var claims map[string]any
	if err := cle.Token.Claims(&claims); err == nil {
		for k := range claims {
			if !safeClaims[k] {
				claims[k] = "REDACTED"
			}
		}
		if b, err := json.MarshalIndent(claims, "", "  "); err == nil {
			claimsJSON = "\n" + string(b)
		}
	}

	return fmt.Sprintf(
		// TODO: how to log the token claims only and not the entire token
		// TODO: just make it not leak creds in any way
		"failed to lookup roles claim '%s' in the given idToken: %s",
		cle.RoleClaim, claimsJSON,
	)
}

var (
	ErrEntityNotFound = func(name string, id uuid.UUID, err error) *apperr.AppErr {
		return apperr.New(
			CodeEntityNotFound,
			"entity not found",
			err,
		)
	}

	ErrExamStateMismatch = func(expected db.FrExamStateType) *apperr.AppErr {
		return apperr.New(
			CodeExamStateMismatch,
			"exam state does not match expected state",
			fmt.Errorf("Exam is not in expected state `%s`", expected),
		)
	}

	ErrUserTypeMismatch = func(expected db.FrUserType, got db.FrUserType) *apperr.AppErr {
		return apperr.New(
			CodeUserTypeMismatch,
			"user is not of expected type",
			fmt.Errorf("Required user of type `%s` but got `%s`.", expected, got),
		)
	}

	ErrClaimNotString = apperr.New(
		CodeClaimNotString,
		"claim is not of type string",
		errors.New("claim is not of type string"),
	)

	ErrCannotClassifyUser = func(
		actualClaims []string,
		cfg *config.Config,
	) *apperr.AppErr {
		return apperr.New(
			CodeCannotClassifyUser,
			"cannot classify user as STUDENT or TEACHER",
			fmt.Errorf("cannot classify user as STUDENT or TEACHER: "+
				"claim '%s' has value(s) %#q, expected one of %#q",
				cfg.RoleClaim, actualClaims, []string{cfg.RoleStudent, cfg.RoleTeacher}),
		)
	}

	ErrRoleClaimLookup = func(err RoleClaimLookupError) *apperr.AppErr {
		return apperr.New(
			CodeRoleClaimLookupFailed,
			"failed to lookup roles claims",
			err,
		)
	}
)
