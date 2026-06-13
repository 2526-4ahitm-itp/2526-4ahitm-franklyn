---
title: External Accounts and Envs
date: 2026-06-10
---

Reference for all external services, accounts, environment variables, and GitHub Actions secrets used by the project.

## External Accounts and Services

| Service | URL / Location | Account | Purpose |
|---|---|---|---|
| Keycloak | `https://auth.htl-leonding.ac.at` | — | OIDC authentication for all components |
| Cachix | `https://app.cachix.org` — cache name: `franklyn` | `JakobHuemer` | Nix binary cache to speed up CI builds |
| Codecov | `https://app.codecov.io` | — | Code coverage reports and PR checks |
| GitHub Container Registry | `ghcr.io/2526-4ahitm-itp/` | — | Hosts Docker images for server, proctor, and hugo |
| APT Repository | `franklyn.htl-leonding.ac.at` (aptly) | — | Debian package distribution for Sentinel |
| openSUSE OBS | `https://api.opensuse.org` — project: `home:franklyn` | `franklyn@htl-leonding.ac.at` | RPM/openSUSE package distribution for Sentinel |

## GitHub Actions Secrets

These secrets must be configured in the GitHub repository settings under **Settings → Secrets and variables → Actions**.

| Secret Name | Used In | Description |
|---|---|---|
| `CACHIX_AUTH_TOKEN_V2` | all workflows via `setup-nix` action | Auth token for pushing/pulling from the `franklyn` Cachix cache |
| `CACHIX_AUTH_TOKEN` | _(unused — deprecated)_ | Older Cachix token, superseded by `CACHIX_AUTH_TOKEN_V2` |
| `CODECOV_TOKEN` | `pr-checks.yaml` | Upload token for Codecov coverage reports |
| `BACKPORT_PAT` | `backport.yaml` | Personal access token from a maintainer account used by the backport action |
| `FRANKLYN_APT_REPOSITORY_SECRET` | `release.yaml` (`publish-apt` job) | Password for the APT repository HTTP API; used as `<user>:<secret>`, APT credentials are in cicd/compose of the server |
| `FRANKLYN_OBS_USERNAME` | `release.yaml` (`publish-opensuse` job) | openSUSE OBS account username |
| `FRANKLYN_OBS_PASSWORD` | `release.yaml` (`publish-opensuse` job) | openSUSE OBS account password |


## Application Environment Variables

### Proctor

Configured via `.env` (production) and `.env.development` (local dev) in `proctor/`.

| Variable | Dev Value | Prod Value | Description |
|---|---|---|---|
| `VITE_API_URL` | `//localhost:5050/api` | `//franklyn.htl-leonding.ac.at/api` | Backend API URL |
| `VITE_KCLK_URL` | `https://auth.htl-leonding.ac.at` | `https://auth.htl-leonding.ac.at` | Keycloak URL |
| `VITE_KCLK_REALM` | `franklyn` | `franklyn` | Keycloak realm |
| `VITE_KCLK_CLIENT_ID` | `proctor` | `proctor` | Keycloak client ID for Proctor |

### Server

Configured via `server/src/main/resources/application.properties`. Override with environment variables in Docker/Kubernetes.

| Property / Env Var | Default Value | Description |
|---|---|---|
| `quarkus.oidc.auth-server-url` | `https://auth.htl-leonding.ac.at/realms/franklyn` | Keycloak realm URL for OIDC |
| `quarkus.oidc.client-id` | `backend` | Keycloak client ID for the server |

### Sentinel

Configured via `sentinel/config/default.toml` (production) and `sentinel/config/dev.toml` (local dev).

| Key | Dev Value | Prod Value | Description |
|---|---|---|---|
| `api_url` | `localhost:5050/api` | `franklyn.htl-leonding.ac.at/api` | Backend API URL |
| `oidc_url` | `https://auth.htl-leonding.ac.at` | `https://auth.htl-leonding.ac.at` | Keycloak URL |
| `oidc_realm` | `franklyn` | `franklyn` | Keycloak realm |
| `oidc_client_id` | `sentinel` | `sentinel` | Keycloak client ID for Sentinel |
| `oidc_scopes` | `openid` | `openid` | Requested OIDC scopes |

