package util

import (
	"context"
	"crypto/rand"
	"crypto/rsa"
	"encoding/json"
	"maps"
	"net/http"
	"net/http/httptest"
	"time"

	"charm.land/log/v2"
	"github.com/go-jose/go-jose/v4"
)

type KCProvider struct {
	Server *httptest.Server
	signer jose.Signer
	key    *rsa.PrivateKey
}

func CreateProvider(ctx context.Context) (KCProvider, error) {
	mux := http.NewServeMux()
	var handler http.Handler = mux

	server := httptest.NewServer(handler)

	url := server.URL

	key, _ := rsa.GenerateKey(rand.Reader, 2048)

	signer, err := jose.NewSigner(
		jose.SigningKey{Algorithm: jose.RS256, Key: key},
		(&jose.SignerOptions{}).WithType("JWT").WithHeader("kid", "test"),
	)

	if err != nil {
		return KCProvider{}, err
	}

	provider := KCProvider{
		Server: server,
		signer: signer,
		key:    key,
	}

	provider.addHandlers(mux, url)

	return provider, nil
}

func (p KCProvider) Token(claims map[string]any) string {
	c := map[string]any{
		"iss": p.Server.URL,
		"aud": "server",
		"iat": time.Now().Unix(),
		"exp": time.Now().Add(time.Hour).Unix(),
	}
	maps.Copy(c, claims)
	b, _ := json.Marshal(c)
	jws, _ := p.signer.Sign(b)
	s, _ := jws.CompactSerialize()
	return s
}

func (p KCProvider) addHandlers(mux *http.ServeMux, url string) {

	mux.HandleFunc(
		"GET /.well-known/openid-configuration",
		func(w http.ResponseWriter, r *http.Request) {

			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(200)

			_ = json.NewEncoder(w).Encode(map[string]any{
				"issuer":   url,
				"jwks_uri": url + "/certs",
			})
		},
	)

	mux.HandleFunc(
		"GET /certs",
		func(w http.ResponseWriter, r *http.Request) {
			// JWKS handler
			_ = json.NewEncoder(w).Encode(jose.JSONWebKeySet{Keys: []jose.JSONWebKey{
				{Key: p.key.Public(), KeyID: "test", Algorithm: "RS256", Use: "sig"},
			}})
		},
	)

	mux.HandleFunc(
		"/",
		func(w http.ResponseWriter, r *http.Request) {
			log.Info("Catch All", "url", r.URL, "header", r.Header, "body", r.Body)
		},
	)

}
