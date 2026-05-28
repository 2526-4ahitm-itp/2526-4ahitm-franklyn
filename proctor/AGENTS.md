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

## 8. WebSocket / protobuf

- WS payloads are **JSON** over `/api/ws/proctor`. Don't change the
  wire format without a separate ticket.
- Protobuf descriptors in `../protobuf/ws/*.proto` are generated into
  `src/proto` by `vite.config.ts` but **intentionally unused** until a
  follow-up ticket flips the wire format. Do **not** delete the
  `bufGenerate()` plugin or `@bufbuild/*` deps as "dead code".

## 9. Code style

- `<script setup lang="ts">` only.
- Explicit return types on exported functions (enforced by eslint).
- No `any`. No `@ts-ignore`.
- Prettier is authoritative for formatting; never disable it locally.

## 10. Workflow

- Branch from `main`. Commit per logical change.
- Conventional commits, kept short:
  `fix(proctor): …`, `feat(proctor): …`, `chore(proctor): …`,
  `docs(proctor): …`, `style(proctor): …`, `refactor(proctor): …`.
- Each commit must pass `bun lint:check` and `bun type-check`.
- For UI changes, manually verify the affected view in a browser before
  marking work done.
