# Phase 9 Handoff — Post-PR Follow-up

You are picking up after Phase 8. The PR for the structural cleanup
(Phases 0–7) has been opened against `main`.

Read these before touching anything:

1. `proctor/rewrite.md` — long-form plan. §8 (Progress Tracker) and §9
   (Deviations) are the source of truth.
2. `proctor/AGENTS.md` — conventions contract.

## Repo state when this hand-off was written

- Branch: `feat/rewrite-proctor`.
- PR: `refactor(proctor): structural cleanup (Phases 0–7)` against `main`.
- Lint, type-check, and build are **green**.
- All phases 0–8 marked done in `rewrite.md §8`.

## What Phase 8 completed

- Ran lint, type-check, and build — all green (Nix not available in
  shell; underlying `bun` commands ran directly and passed).
- Corrected stale forward-references in `rewrite.md §9`:
  - Deviation #3: removed "Still pending (Phase 4 next)" — Phase 4 is done.
  - Deviation #4: corrected "Two items remain" — both landed in Phase 4.
  - Deviation #5: corrected "not yet documented" — AGENTS.md §4 has it.
- Marked Phase 8 done in the progress tracker.
- Opened PR against `main`.

## What to do next (Phase 9)

Phase 9 only exists if review surfaces follow-up work. If the PR merges
cleanly with no requested changes, Phase 9 is a no-op.

If reviewers request changes:

1. Address feedback on the `feat/rewrite-proctor` branch.
2. For each logical fix, commit per `AGENTS.md §11` conventions.
3. Ensure `bun lint:check`, `bun type-check`, and `bun run build` pass
   after each fix.
4. Re-request review once all comments are resolved.

If new follow-up work is identified but out of scope for this PR:

1. Log each item in a new ticket / GitHub issue.
2. Do **not** add out-of-scope changes to this PR.
3. Once the PR is merged, open a `feat/proctor-followup` branch for the
   next batch of work and write `PHASE10_HANDOFF.md`.

## Known deferred items (candidates for follow-up)

These were explicitly out of scope for the cleanup but surfaced during
the phases:

- **WS protocol:** protobuf `bufGenerate()` is wired in `vite.config.ts`
  but unused. A separate ticket should flip the WS protocol to protobuf.
- **Router guards:** `useRoles()` composable centralises role lookup but
  the `User.role` field from GraphQL (`STUDENT | TEACHER`) is still not
  used to replace the `OU=Teacher` DN check in guards — left for a
  follow-up that also adds a `roleDetails` query.
- **Subscription for notices:** `Subscription.noticesSub` exists in the
  schema but notices are still fetched once on boot. A live subscription
  is a future ticket.
- **Tests:** entirely out of scope for the cleanup.

## Gotchas

1. `pinia-plugin-persistedstate` is kept intentionally — see `AGENTS.md §9`.
2. `@bufbuild/*` deps and `bufGenerate()` plugin are kept intentionally —
   see `AGENTS.md §8`.
3. `nix` is not available in the default shell; use `bun lint:check`,
   `bun type-check`, and `bun run build` directly to verify green status.
