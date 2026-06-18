# Proctor — Agent Conventions

This file is the canonical contract for any agent (human or AI) working in
`proctor/`. Keep it short. If you need long-form context, read
`rewrite.md`.

## 1. What this app is

Proctor is the teacher-facing Vue 3 SPA of Franklyn. It manages exams,
shows live webcam frames from `sentinel` clients during proctoring, and
runs as an authenticated Keycloak client. The GraphQL backend is in
`../graphql`; the WebSocket gateway is in `../ws`. Both are out of scope
for frontend work.

## 2. Project layout

```
src/
  assets/         fonts, global css, images
  components/     reusable view-level components
  components/ui/  primitive wrappers (Reka UI under the hood)
  i18n.ts         vue-i18n bootstrap
  locales/        en.json, de.json — keep in sync, every key in both
  main.ts         app entry; Pinia, Pinia Colada, Villus, i18n, router
  router/         vue-router config and guards
  services/       GraphQL queries/mutations + composables (MVVM layer)
  stores/         Pinia stores — local/UI state only
  types/          TS types that mirror GraphQL response shapes
  views/          route-level components
```

## 3. Data flow (MVVM)

```
view ──> composable (services/*.ts) ──> Villus + Pinia Colada ──> GraphQL
                                                 │
                                                 └─> normalised error
```

Rules:

- **No raw `gql` calls in views or stores.** They live in `services/`.
- **Pinia stores hold only local/UI state** (theme, Keycloak session,
  websocket frame map, dismissed notices). Server data lives in Pinia
  Colada cache.
- **Mutations declare their invalidations** next to themselves
  (`invalidate: ['exams']`). Views don't refetch manually.
- **Errors are normalised** in `services/graphql.ts`. Never
  `error.message.includes('403')`.

## 4. GraphQL specifics

- Schema lives at `http://localhost:5050/api/graphql/schema.graphql`
  (dev). No build-time codegen — write tagged template `gql` strings
  and mirror response shapes by hand in `types/`.
- `Exam.startTime` and `Exam.endTime` are `DateTime!` (never null). Only
  `startedAt` / `endedAt` are nullable.
- `User.theme` is the enum `UserTheme` (`LIGHT | DARK | SYSTEM`); use
  that, not `string`.
- `User.role` (`STUDENT | TEACHER`) plus `roleDetails` is available —
  prefer it over the `OU=Teacher` DN check when wiring guards.
- **Two-layer Cache:** Villus is configured as a no-cache transport (`cachePolicy: 'network-only'` inside `executeQuery`). The only cache layer is Pinia Colada, which gives us stale-while-revalidate by default. Use the default behaviour everywhere; only set `staleTime` / `gcTime` / `refetchOn*` per call when there is a concrete reason.


## 5. Styling

- All colours, sizes, radii, spacing **must** reference CSS custom
  properties defined in `src/assets/main.css` / `assets/styles/*.css`.
- No `rgba(0,0,0,…)` literals. Use `var(--bg-overlay)` etc.
- No backdrop blurs. No `transform: translateY(...)` hover lifts. Hover
  states only change `border-color` / `background`.
- Mono font: `var(--font-mono)`. Never inline `'JetBrains Mono'` strings.
- Buttons that act as rows (cards with `@click`) need `:focus-visible`
  styles.

## 6. i18n

- Every user-facing string goes through `t('namespace.key')`.
- Every date/time goes through `d(value, 'short' | 'long' | 'time' | 'datetime')`.
- New keys land in `en.json` **and** `de.json` in the same commit.
- Locale set: `en`, `de`. No `de_at`.

## 7. Auth

- Keycloak JS stays. The store is `stores/KeycloakStore.ts`.
- Token refresh is debounced inside the GraphQL fetcher — don't call
  `updateToken` from views.
- Role checks: `useRoles()` composable, not raw `kc.keycloak.realmAccess`.

## 8. Notice markdown and video downloads

- Notice-banner content is **trusted markdown** rendered through `utils/noticeMarkdown.ts` and
  sanitised by DOMPurify before rendering via the `v-safe-html` directive. Never bypass this
  directive — never `v-html` notice content directly.
- Video downloads go through `lib/videoDownload.ts` which fetches `/api/videos/{sentinelId}.mp4`
  with a Bearer header. Don't link to the URL directly (it 401s in a new tab).

## 10. WebSocket / protobuf

- WS payloads are **JSON** over `/api/ws/proctor`. Don't change the
  wire format without a separate ticket.
- Protobuf descriptors in `../protobuf/ws/*.proto` are generated into
  `src/proto` by `vite.config.ts` but **intentionally unused** until a
  follow-up ticket flips the wire format. Do **not** delete the
  `bufGenerate()` plugin or `@bufbuild/*` deps as "dead code".

## 11. Persistence

`pinia-plugin-persistedstate` is intentionally kept. `ThemeStore` uses
`persist: true` so the user's last theme choice survives a hard reload and
seeds the first paint before the Villus user query returns. `initTheme()`
in `services/theme.ts` reads the same localStorage key synchronously in
`main.ts` to apply the correct `data-theme` attribute before Vue mounts,
avoiding a flash. Once the user query resolves, `useResolvedTheme()` lets
the backend value overwrite the local one. Do **not** remove the plugin or
the `persist` option on `ThemeStore`.

## 12. Runtime env var contract — keep all locations in sync

Keycloak config is injected at container start via env vars. **If you add, rename, or remove a Keycloak env var, you must update every location below in the same PR:**

| Location | What to change |
|---|---|
| `proctor/docker/entrypoint.sh` | `for var in ...` loop (validation) **and** the `cat > config.json` heredoc |
| `proctor/src/config.ts` | `AppConfig` interface fields + JSON key names in the `fetch` branch |
| `proctor/src/env.d.ts` | `ImportMetaEnv` declarations (dev branch only, but must be declared) |
| `proctor/.env.development` | Dev defaults used by `bun run dev` and tests |
| `hugo/content/en/guide/self-host/environment-variables.md` | Proctor table in the self-host guide |

The JSON keys written by the entrypoint (`keycloakUrl`, `keycloakRealm`, `keycloakClientId`) must exactly match the `AppConfig` field names in `config.ts` — they are deserialized directly. Rename one → rename both.

`PROCTOR_KEYCLOAK_URL` is the **browser-facing** Keycloak URL, distinct from the server's `KEYCLOAK_SERVER_URL` (token-verification URL). Do not merge them.

## 13. Code style

- `<script setup lang="ts">` only.
- Explicit return types on exported functions (enforced by eslint).
- No `any`. No `@ts-ignore`.
- Prettier is authoritative for formatting; never disable it locally.

## 14. Workflow

- Branch from `main`. Commit per logical change.
- Conventional commits, kept short:
  `fix(proctor): …`, `feat(proctor): …`, `chore(proctor): …`,
  `docs(proctor): …`, `style(proctor): …`, `refactor(proctor): …`.
- Each commit must pass `bun lint:check` and `bun type-check`.
- For UI changes, manually verify the affected view in a browser before
  marking work done.

## 15. Continuation prompts (mandatory)

### Writing a handoff

Every phase must end with a written handoff **before** stopping work or marking the phase done.
File: `proctor/continuation/PHASE{N+1}_HANDOFF.md`.

Required sections:
1. **Status line** — one sentence: complete / partial / blocked.
2. **Repo state** — branch, HEAD commit, working-tree status, build/lint/type-check results.
3. **What was done** — concise bullets; enough for a cold reader to skip re-reading git log.
4. **Next step** — concrete, ordered instructions. If nothing remains, say so explicitly.
5. **Known gaps** — gotchas, deferred items, open decisions.

### Phase planning (do this first)

Before starting any non-trivial task, estimate scope and split into phases. **Present the phase
plan to the user and wait for approval before writing any code.**

Rules for sizing phases:
- One phase = one focused concern that fits comfortably in a single context window (~60–70k tokens).
  If unsure, err smaller — a two-phase split is cheaper than a mid-phase context reset.
- Name phases by what they deliver, not by number alone (e.g. "Phase 1 — service layer",
  "Phase 2 — views + i18n").
- Each phase must be independently committable and leave the build green.
- If the task is small enough to finish in one session without risk of context overflow, say so
  and proceed without splitting.

Present format (before starting work):

```
Proposed phases:
  Phase 1 — [what it delivers] (~N files, estimated M commits)
  Phase 2 — [what it delivers] (~N files, estimated M commits)
  ...
Proceed with Phase 1?
```

### Lifecycle rules

- **One active handoff at a time.** When writing PHASE{N}, delete PHASE{N-1} in the same commit.
  The directory should never hold more than one file.
- **Delete when the next agent starts.** The agent that reads a handoff deletes it at the top of
  its first commit, so the directory is empty while work is in progress.
- **When a plan is fully executed** (no next steps), the handoff must say so clearly at the top
  (`Status: COMPLETE — no further work required`), tell the user what happened, and list only
  any known non-blocking gaps. Do **not** invent more work to fill the file.
- **If a phase is interrupted mid-work**, write a partial handoff that says exactly where to
  resume and what was already committed. Do not re-do completed commits.
- **Inform the user** at the end of every session whether a handoff was written and what the
  next step is. Don't leave the user guessing.
