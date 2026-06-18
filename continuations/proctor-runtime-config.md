# Continuation: Proctor Runtime Config

**Every agent working on this branch must write their continuation into `continuations/` when done, including this sentence.**

## What Was Done (2026-06-18, Claude Sonnet 4.6)

Implemented all 3 phases of `proctor/docs/runtime-config-plan.md`.

### Commits

| Commit | Message |
|--------|---------|
| `0afe624` | `feat(proctor): load keycloak config at runtime via typed config object` |
| `f7ff065` | `feat(proctor): inject runtime keycloak config via docker entrypoint` |
| `86941b1` | `docs(self-hosting): document proctor runtime env vars` |

### Phase 1 — App-side config (TypeScript)

- Created `proctor/src/config.ts`: `AppConfig` interface, `loadConfig()` (DEV branch reads `VITE_KCLK_*`; prod fetches `config.json`), `getConfig()` accessor.
- `proctor/src/main.ts`: added `await loadConfig()` before `useKeycloakStore()`.
- `proctor/src/stores/KeycloakStore.ts`: replaced `import.meta.env.VITE_KCLK_*` reads with `getConfig()`.
- `proctor/src/env.d.ts`: replaced stale `VITE_API_URL` with Keycloak trio.
- `proctor/.env.development`: removed `VITE_API_URL` line.
- `proctor/.env`: **deleted** — prod values belong in deployment, not repo.

Lint and type-check both passed clean.

### Phase 2 — Docker runtime injection

- Created `proctor/docker/entrypoint.sh`: POSIX sh, fail-fast on missing vars, writes `config.json` to `/usr/share/nginx/html/`, then `exec nginx`.
- `proctor/docker/Dockerfile.ci`: added `COPY`/`chmod`/`ENTRYPOINT` for the script.
- `proctor/docker/nginx.conf`: added exact-match `location = /proctor/config.json` with `Cache-Control: no-store` before the generic `/proctor` block.

Phase 2 was not Docker-verified (no tarball in context at time of implementation — entrypoint logic is straightforward and matches the plan exactly). Verify with:
```
docker build -f proctor/docker/Dockerfile.ci -t proctor-test .
docker run --rm -e PROCTOR_KEYCLOAK_URL=https://kc.example/ \
  -e PROCTOR_KEYCLOAK_REALM=franklyn -e PROCTOR_KEYCLOAK_CLIENT_ID=proctor \
  -p 8080:80 proctor-test
curl -s localhost:8080/proctor/config.json
docker run --rm proctor-test   # should exit 1, print "<VAR> is required"
```

### Phase 3 — Docs

- `hugo/content/en/guide/self-host/environment-variables.md`: added `## Proctor` section with the three required env vars, matching server table format, with browser-reachability note on `PROCTOR_KEYCLOAK_URL`.

## What's Next

- **No-leak verification** (plan §Phase 1 / Verification): run prod build and grep for in-house Keycloak URL / `VITE_KCLK` vars:
  ```
  nix develop .#proctor --command fr-proctor-build --base=/proctor/
  grep -rE "auth\.htl-leonding|VITE_KCLK|franklyn" proctor/dist/
  ```
  Expect zero matches.
- **CI parity**: `nix develop .#proctor --command fr-proctor-pr-check`.
- **Docker smoke test** (see Phase 2 above).
- **PR**: once checks pass, open against `main`.

## Known State

- `proctor/docs/runtime-config-plan.md` is the authoritative spec; all phases now implemented.
- The title of `hugo/content/en/guide/self-host/environment-variables.md` still says "Server Environment Variables" — updating it to cover both server and proctor is a reasonable follow-up.
