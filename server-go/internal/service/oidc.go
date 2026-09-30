package service

import (
	"context"

	"github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/server/internal/infrastructure"
	"github.com/coreos/go-oidc/v3/oidc"
)

type OIDC struct {
	Provider      *oidc.Provider
	TokenVerifier *oidc.IDTokenVerifier
}

func CreateOIDC(cfg infrastructure.Config, ctx context.Context) (OIDC, error) {
	provider, err := oidc.NewProvider(ctx, cfg.KCProviderURL)

	if err != nil {
		return OIDC{}, err
	}

	idTokenVerifier := provider.Verifier(&oidc.Config{ClientID: cfg.KCClientId})

	return OIDC{
		Provider:      provider,
		TokenVerifier: idTokenVerifier,
	}, nil
}
