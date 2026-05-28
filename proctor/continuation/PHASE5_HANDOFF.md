# Phase 5 Handoff — Router and Access Control Refactoring

You are picking up the proctor cleanup at the start of Phase 5. Phase 4 is fully completed: all view-level dialogs, filters, rows, icons, and helper libraries have been extracted, and the stores are fully robustified and green.

Read these before touching anything:

1. `proctor/rewrite.md` — the long-form plan. The Progress Tracker (§8) and the Deviations log (§9) are the source of truth.
2. `proctor/AGENTS.md` (and root `AGENTS.md`) — the conventions contracts.

## Repo state when this hand-off was written

- Branch: `feat/rewrite-proctor`.
- Working tree: clean.
- Lint, type-check, and build are all **green**.
- Subcomponents extracted: `Dialog`, `ConfirmDialog`, `NewExamDialog`, `ExamStatusFilter`, `ExamRow`, and `UiIcon`.
- Helpers extracted: `datetime.ts` and `examStatus.ts`.

## What to do next (in order)

### Step A — Centralize Role Checks (`useRoles`)
- Create a `useRoles()` composable in `src/services/user.ts` (or a dedicated roles service).
- Centralize checking roles (e.g. `franklyn-admin` / DN matching `OU=Teacher`) so both the router guards and settings/nav views call this composable instead of directly accessing `kc.keycloak.tokenParsed` or `keycloakStore.keycloak.realmAccess`.

### Step B — Router Guard Cleanups (`src/router/index.ts`)
- Collapse the guard's two `/not-allowed` redirect branches into one unified decision tree.
- Eliminate duplicate role checks. Use the centralized `useRoles()` helper.

### Step C — Optional Param & Lazy-Loading Router Config
- Drop the duplicate routes for `/proctoring` and `/proctoring/:id`; define a single route with an optional parameter.
- Transition all view components to lazy imports (e.g. `component: () => import('@/views/HomeView.vue')`) to shrink the initial JavaScript entry bundle.

## Gotchas to remember
1. Always run `bun run lint:check` and `bun run type-check` before committing your code.
2. Be careful when redirecting inside router guards to avoid infinite navigation loops.
