# Phase 7 Handoff — Final Pass

You are picking up at the start of Phase 7. Phase 6 is fully completed: `UiBadge`, `UiTextField`, and `UiCard` have been extracted, wired into `ExamRow`, `AdminNoticeBannersView`, `NewExamDialog`, and `ExamDetailView`, and the missing `--bg-subtle` CSS token has been defined in `main.css`.

Read these before touching anything:

1. `proctor/rewrite.md` — the long-form plan. The Progress Tracker (§8) and the Deviations log (§9) are the source of truth.
2. `proctor/AGENTS.md` (and root `AGENTS.md`) — the conventions contracts.

## Repo state when this hand-off was written

- Branch: `feat/rewrite-proctor`.
- Working tree: clean (after committing Phase 6 changes).
- Lint, type-check, and build are all **green**.
- `src/components/ui/` now contains: `Badge.vue`, `Button.vue`, `Card.vue`, `Dialog.vue`, `DropdownSelect.vue`, `Icon.vue`, `TextField.vue`, `ThemeSwitcher.vue`.
- Form spacing regression in `NewExamDialog` fixed (`.form-body` flex gap added).

## What to do next (Phase 7 — Final Pass)

### Step A — Remove `pinia-plugin-persistedstate` if redundant

Check `proctor/src/stores/ThemeStore.ts`. The question from §4.2 is still open:
- `onMounted` inside the store factory should be removed — factories may be called outside component setup.
- A `useResolvedTheme()` composable should consolidate the theme resolution rule (§6.2): backend user.theme wins, fallback to persisted store, fallback to SYSTEM.
- Once `useResolvedTheme()` is in place, check if `pinia-plugin-persistedstate` is still needed. If not, remove it and the dep.
- If it stays, add a comment in AGENTS.md explaining the "local seeds first paint, backend overwrites on login" rule.

### Step B — Zero-warning lint pass

Run `bun run lint:check` (already passes). Verify `--max-warnings=0` is achievable:
```
cd proctor && bun run lint:check
```

### Step C — Console log/warn sweep

Scan for any remaining `console.log` or `console.warn` left behind:
```
grep -r "console\.\(log\|warn\)" proctor/src/ --include="*.vue" --include="*.ts"
```
Remove any found (unless they are in error handlers that you want to keep as `console.error`).

### Step D — README update

`proctor/README.md` already has project content from Phase 0. Check if it needs a screenshot or any updated links.

## Gotchas to remember

1. Always run `bun run lint:check` and `bun run type-check` before committing your code.
2. Ensure you run the Nix PR checks (`nix develop .#proctor --command fr-proctor-pr-check` or from the `proctor/` directory `nix develop ..#proctor --command fr-proctor-pr-check`) before submitting PR/handoff.
3. Phase 4.2 items for `ThemeStore` are still pending — see above in Step A.
