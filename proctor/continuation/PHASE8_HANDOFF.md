# Phase 8 Handoff — PR Readiness

You are picking up at the start of Phase 8. All seven cleanup phases are
fully complete. The branch `feat/rewrite-proctor` is clean, lint/type-check/
build are green, and no debug logging remains.

Read these before touching anything:

1. `proctor/rewrite.md` — long-form plan. §8 (Progress Tracker) and §9
   (Deviations) are the source of truth.
2. `proctor/AGENTS.md` — conventions contract.

## Repo state when this hand-off was written

- Branch: `feat/rewrite-proctor`.
- Working tree: clean.
- Lint, type-check, and build are all **green**.
- Phases 0–7 all marked done in `rewrite.md §8`.
- No `console.log` / `console.warn` left in `proctor/src/`.
- `ThemeStore` has no `onMounted`; `useResolvedTheme()` composable handles
  theme resolution.
- `pinia-plugin-persistedstate` kept and documented in `AGENTS.md §9`.

## What to do next (Phase 8 — PR Readiness)

### Step A — Run the Nix PR checks

This is the gate before any PR is opened. From the repo root:

```sh
nix develop .#proctor --command fr-proctor-pr-check
```

Or from inside `proctor/`:

```sh
nix develop ..#proctor --command fr-proctor-pr-check
```

Fix anything that fails. Do **not** skip hooks or bypass checks.

### Step B — Audit `rewrite.md` deviations for stale notes

`rewrite.md §9` still contains some notes referencing "Phase 4 next" that
pre-date Phase 4's completion. Update those stale forward-references to
reflect what actually landed. Do not rewrite history — just correct
references that are now factually wrong (e.g., "still pending" entries that
are done).

### Step C — Open the pull request

Once Nix checks pass:

1. Push the branch:
   ```sh
   git push -u origin feat/rewrite-proctor
   ```
2. Open the PR against `main` with title:
   `refactor(proctor): structural cleanup (Phases 0–7)`
3. PR body should summarise the eight phases and link to `rewrite.md` for
   the full decision log. Include the standard test plan checklist:
   - [ ] Nix PR checks pass
   - [ ] Manual smoke: HomeView, ExamDetailView, ProctoringView, AdminNoticeBannersView, SettingsView
   - [ ] Both locales (`en`, `de`) render correctly in SettingsView
   - [ ] Theme switching (light/dark/system) persists across reload
   - [ ] WebSocket reconnect in ProctoringView works after page refresh

### Step D — Write the continuation prompt for Phase 9 (if needed)

After the PR is merged, if any follow-up work surfaces during review, write
`proctor/continuation/PHASE9_HANDOFF.md` using the same format as this file.
If no follow-up work is identified, Phase 8 is the final phase.

## Gotchas to remember

1. Nix PR check must pass before PR is opened — do not skip.
2. The stale §9 note about "Phase 4 next" (`continuation/PHASE4_HANDOFF.md`)
   is a dead reference — that handoff document exists but the work is done.
3. Every phase **must** produce a `PHASE{N+1}_HANDOFF.md` in `proctor/continuation/`
   before closing — see `AGENTS.md §11`.
