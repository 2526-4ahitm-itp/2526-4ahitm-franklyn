# PHASE 11 HANDOFF — Cleanup Audit Implementation

## 1. Repo State

- **Branch:** `feat/rewrite-proctor`
- **HEAD:** `722c310` — `style(proctor): replace hardcoded color literals with semantic tokens`
- **Working tree:** clean (only `proctor/cleanup.md` untracked — intentionally not committed)
- **Build status:** `bun run lint:check` ✅  `bun run type-check` ✅

## 2. What Was Completed in This Phase

All actionable issues from `proctor/cleanup.md` were addressed in 7 atomic commits:

### `4a350dd` — `style(proctor): add missing tokens and merge orphaned theme blocks`
- Added `--space-7` (1.75rem) and `--space-12` (3rem) to `:root` spacing scale
- Added `--nav-fg`, `--color-on-primary`, `--color-on-status` semantic tokens to both light/dark blocks
- Merged the two orphaned `--bg-overlay`/`--hover-tint` blocks into the main light/dark palette blocks (cleanup §7.4)

### `0b082ec` — `fix(proctor): remove duplicated toDate helpers and move them to lib/datetime`
- `App.vue`: removed local `toDate()` copy; now imports from `lib/datetime` (§5.2)
- `AdminNoticeBannersView.vue`: same deduplication (§5.3)
- `lib/datetime.ts`: extracted `formatDateLocal` and `formatTime` from `ExamDetailView` (§5.1)
- `services/theme.ts`: fixed media query listener leak by adding `onUnmounted` cleanup (§5.5)
- `stores/KeycloakStore.ts`: `sessionStorage.stored_session =` → `sessionStorage.setItem(...)` (§8.3)
- `services/notices.ts`: moved `NoticeInputPayload`/`NoticePatchPayload` before their usage (§8.4)

### `149d5bb` — `fix(proctor): consolidate duplicate /exams route as alias of /`
- Router had two routes for `HomeView`. Collapsed to one route with `alias: '/exams'` (§5.9)

### `4068e79` — `refactor(proctor): normalize Button import name to UiButton throughout`
- `HomeView.vue`, `ExamDetailView.vue`, `ProctoringView.vue`: renamed import alias `Button` → `UiButton` (§4)
- Also: fixed ExamDetailView back button to use `router.back()` instead of hardcoding `/exams` (§5.8)
- Also: made clipboard copy `<i>` keyboard-accessible with `tabindex="0"`, `role="button"`, `@keydown.enter/space` (§6.5)
- Also: replaced `var(--space-0.5)` with `var(--space-1)` (§2 — undefined variable)
- Also: removed `max-width: 1200px` from HomeView and ExamDetailView (§3.7)

### `846fd56` — `fix(proctor): expose prevPage/nextPage store actions, stop direct ref mutation`
- `WebsocketStore.ts`: added `prevPage()` and `nextPage()` actions
- `ProctoringView.vue`: template now calls these actions instead of mutating `currentPage` directly (§5.10)

### `d8bfc43` — `fix(proctor): accessibility improvements across multiple components`
- `ExamRow.vue`: `examStatus` computed once instead of calling `getExamStatus()` twice per render (§5.11)
- `ExamStatusFilter.vue`: added `role="tablist"` to `.filter-pills` container (§6.1)
- `NotAllowedView.vue`: replaced `<a href="#">` logout with `<button>` (§6.4); replaced `40px`/`4px` gaps with `--space-10`/`--space-1` (§1.9)

### `722c310` — `style(proctor): replace hardcoded color literals with semantic tokens`
- `Badge.vue`: `color: white` → `var(--color-on-status)` (§3.10)
- `Button.vue`: `color: white` → `var(--color-on-primary)` (§3.9)
- `DropdownSelect.vue`: same for checked item state
- `NavComponent.vue`: all `#fff` and `hsla(0, 0%, 100%, *)` literals → `var(--nav-fg)` + `color-mix()` (§1.1)
- `SettingsView.vue`: `#fff` → `var(--color-on-primary)`, removed `max-width: 1200px` (§3.7, §1.4)
- `ExamDetailView.vue`: status pill/badge `color: white` → `var(--color-on-status)`, glow literals → token-based (§1.3)
- `AdminNoticeBannersView.vue`: removed `max-width: 1200px` (§3.7)

## 3. Items from cleanup.md NOT Implemented (Deferred/Out-of-scope)

The following were reviewed and intentionally deferred as they require larger architectural changes or new component proposals:

| # | Issue | Reason deferred |
|---|---|---|
| 3.1 | `.modal-actions` CSS duplication across 3 files | Requires UiDialog slot redesign |
| 3.2 | `.frame-placeholder` duplication in Proctoring/Overlay | Requires new `FramePlaceholder.vue` component proposal |
| 3.3/3.4 | ExamDetailView re-implements Badge status styles | Requires UiBadge usage refactor and template changes |
| 3.5/3.6 | AdminNoticeBannersView raw `<select>` + `.form-group` duplication | Requires UiDropdownSelect integration |
| 3.8 | SettingsView re-implements ThemeSwitcher | Requires ThemeSwitcher API extension (@change emit) |
| 5.4 | Silent validation errors in HomeView/ExamDetailView | Requires new reactive error state + template additions |
| 5.6 | WebsocketStore reconnect race condition | Complex async guard; needs dedicated fix ticket |
| 5.7 | copyUuid no user feedback | Requires toast/notification system |
| 5.12 | SettingsView selectedLanguage stale initialization | Minor; existing watch already re-syncs |
| 6.2 | ExamRow div role=button, no keyboard handler | Keyboard handler lives in HomeView parent; needs prop/emit refactor |
| 6.3 | ExpandedSentinelOverlay not a proper modal | Requires UiDialog migration |
| 7.1 | ProctoringView deep-overrides UiButton internals | Requires new UiButton `variant="pager"` or bare button |
| 7.2 | DropdownSelect `!important` in :deep() | Upstream Reka UI portal issue; needs investigation |
| 7.3 | ExamDetailView `:deep(button)` coupling | Requires `fullWidth` prop on UiButton |
| 8.1 | saveEdit no UI error state in modal | Requires reactive `editError` ref wiring |
| 8.2 | WebsocketStore unsafe JSON.parse cast | Requires type guard or zod schema |

## 4. Gotchas / Open Decisions

- **`color-mix()` usage in NavComponent:** Used to generate semi-transparent variants of `--nav-fg` since CSS doesn't support `hsla(var(--nav-fg), 0.7)`. `color-mix(in srgb, ...)` is supported in all modern browsers (Chromium 111+, Firefox 113+, Safari 16.2+). If older browser support is required, fallback to explicit literal colors.
- **`--space-7` not previously in scale:** Added to fill a gap in the 4px-base scale. No existing components use it yet, but it's available for future use.
- **`ExamDetailView` `loading-state` still uses `var(--space-12)`:** This is now valid since `--space-12` was added to `main.css`.
