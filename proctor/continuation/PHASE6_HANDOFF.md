# Phase 6 Handoff — Component Library Skeleton

You are picking up the proctor cleanup at the start of Phase 6. Phase 5 is fully completed: role checks are centralized into `useRoles()`, router guards are collapsed and cleaned up, view components are lazily imported, and duplicate proctoring routes are merged into a single route with an optional parameter.

Read these before touching anything:

1. `proctor/rewrite.md` — the long-form plan. The Progress Tracker (§8) and the Deviations log (§9) are the source of truth.
2. `proctor/AGENTS.md` (and root `AGENTS.md`) — the conventions contracts.

## Repo state when this hand-off was written

- Branch: `feat/rewrite-proctor`.
- Working tree: clean (after committing Phase 5 changes).
- Lint, type-check, and build are all **green** and pass successfully.
- Role helper extracted: `useRoles()` in `src/services/user.ts`.
- Routing configuration updated in `src/router/index.ts`.

## What to do next (in order)

### Step A — Extract/Implement UI Components (`src/components/ui/`)
- Audit current usage of custom input forms, overlays, dialogs, badges, and card repetition.
- Propose and build missing UI primitives using Reka UI where applicable.
- Make sure components are self-contained `.vue` files.

### Step B — Clean Up Remaining Unused Dependencies
- Verify if any package in `package.json` can be cleaned up or marked as devDependency.

## Gotchas to remember
1. Always run `bun run lint:check` and `bun run type-check` before committing your code.
2. Ensure you run the Nix PR checks (`nix develop .#proctor --command fr-proctor-pr-check` or from the `proctor/` directory `nix develop ..#proctor --command fr-proctor-pr-check`) before submitting PR/handoff.
