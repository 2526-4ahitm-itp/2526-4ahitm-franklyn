package util

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"strings"

	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/db"
	"github.com/coreos/go-oidc/v3/oidc"
	"github.com/google/uuid"
)

func GetIdPathParam(r *http.Request) (uuid.UUID, error) {

	pathValue := r.PathValue("id")

	if pathValue == "" {
		return uuid.UUID{}, errors.New(`PathValue "id" not present`)
	}

	id, err := uuid.Parse(r.PathValue("id"))

	if err != nil {
		return uuid.UUID{}, err
	}

	return id, nil
}

func CreatedBody(r *http.Request, entity any, id uuid.UUID) *HttpResponse {
	return &HttpResponse{
		Status: http.StatusCreated,
		Body:   entity,
		ExtraHeaders: map[string]string{
			"Location": r.URL.Path + "/" + id.String(),
		},
	}
}

type requestJwtUserType int

var RequestJwtUser requestJwtUserType

func GetJwtUser(ctx context.Context) (*oidc.IDToken, error) {
	u, ok := ctx.Value(RequestJwtUser).(*oidc.IDToken)

	if !ok {
		return u, errors.New("jwt user missing from context")
	}

	return u, nil
}

type requestFrUserType int

var RequestFrUser requestFrUserType

func GetFrUser(ctx context.Context) (*db.FrUser, error) {
	u, ok := ctx.Value(RequestFrUser).(*db.FrUser)

	if !ok {
		return u, errors.New("franklyn user missing from context")
	}

	return u, nil
}

func CollectArrToValids[T ~string](list []T) string {
	var valids []string
	for _, e := range list {
		valids = append(valids, fmt.Sprintf("`%s`", string(e)))
	}
	return strings.Join(valids, ", ")
}
