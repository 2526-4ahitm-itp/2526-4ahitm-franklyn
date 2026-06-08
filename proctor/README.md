# Proctor

The teacher-facing Vue 3 SPA for **Franklyn**, the open-source exam
proctoring platform. Proctor manages exams, surfaces live webcam frames
from `sentinel` clients during proctoring, and runs as an authenticated
Keycloak client against the Franklyn GraphQL backend.

For Franklyn as a whole see the repo root. The other workspaces:

- `../graphql` — Java/Quarkus GraphQL API (exam, user, notice domain)
- `../ws` — WebSocket gateway for live frames
- `../sentinel` — the student-side client that produces frames

## Project documents

- [`AGENTS.md`](./AGENTS.md) — short, canonical conventions for any
  agent (human or AI) modifying this workspace.
- [`rewrite.md`](./rewrite.md) — long-form cleanup plan with phased
  task list and decision log.

## Setup

```sh
bun install
```

## Develop

```sh
bun dev
```

The dev server proxies `/api/*` to `http://localhost:5050` (see
`vite.config.ts`). The GraphQL backend and Keycloak must be running —
see the repo root for the docker-compose stack.

Required env (see `.env.development`):

```
VITE_API_URL=//localhost:5050/api
VITE_KCLK_URL=…
VITE_KCLK_REALM=franklyn
VITE_KCLK_CLIENT_ID=proctor
```

## Build

```sh
bun run build      # type-check, then vite build
bun preview        # serve the built bundle locally
```

## Quality gates

```sh
bun lint:check     # eslint (no fixes)
bun lint           # eslint with --fix
bun type-check     # vue-tsc --build
bun format         # prettier --write src/
bun licensee       # third-party licence audit
```

## IDE

VS Code + the official Vue extension (Volar). Disable Vetur.

## Browser dev-tools

- Chromium: [Vue.js devtools](https://chromewebstore.google.com/detail/vuejs-devtools/nhdogjmejiglipccpnnnanhbledajbpd)
- Firefox: [Vue.js devtools](https://addons.mozilla.org/en-US/firefox/addon/vue-js-devtools/)
