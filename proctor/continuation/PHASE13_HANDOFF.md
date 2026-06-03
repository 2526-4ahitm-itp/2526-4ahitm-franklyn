# PHASE 13 HANDOFF — rebase-plan.md fully executed

## Status: rebase-plan.md is COMPLETE

All steps from `proctor/rebase-plan.md` have been implemented and committed.
The file can be deleted or archived — it is no longer actionable.

---

## 1. Repo state

- **Branch:** `feat/rewrite-proctor`
- **HEAD:** `071049e` — docs(proctor): add PHASE13_HANDOFF.md for post-merge state
- **Merge commit:** `043214c` — chore(proctor): merge origin/main — video downloads and notice markdown
- **Working tree:** clean
- **Checks:** `bun lint:check` ✅  `bun type-check` ✅  `bun run build` ✅

---

## 2. What the merge delivered

### Notice-banner markdown (PR #338 from origin/main)
- `src/utils/noticeMarkdown.ts` — accepted verbatim from main
- `src/components/notice/NoticeBanner.vue` — accepted verbatim from main
- `src/main.ts` — `v-safe-html` DOMPurify directive registered after `app.use(router)`
- `src/App.vue` — inline `<section class="notice-banner">` replaced with `<NoticeBanner>` + `renderNoticeMarkdown`; ~80 lines of inline CSS dropped
- `src/views/AdminNoticeBannersView.vue` — markdown legend (`<details>/<summary>`) + `<NoticeBanner>` live preview added to create/edit forms; `v-safe-html` on notice title in list; `admin.notices.*` keys renamed to `notices.*` (`time_range_required` → `start_end_required`)
- `src/assets/main.css` — `.notice-markdown` block accepted; hardcoded `'JetBrains Mono'` in `.notice-markdown code` replaced with `var(--font-mono)`

### Video generation & download (PR #340 from origin/main)
- `src/services/sessions.ts` — `videoStatus: VideoStatus | null` added to `ExamSession`; `useGenerateSentinelVideo()` mutation added
- `src/lib/videoDownload.ts` — new helper; bearer-auth blob download via `fetch('/api/videos/{sentinelId}.mp4')`
- `src/views/ExamDetailView.vue` — video feature re-implemented on top of services layer:
  - Polling: `setInterval(sessionsQuery.refetch, 2000)` while `hasPendingVideos`; stopped in `onBeforeUnmount`
  - Auto-download: `watch(sessions)` triggers `downloadSentinelVideo` when status flips `PENDING→DONE` and sentinelId is in `pendingDownloads` set
  - Per-row button: "Generate" (null/FAILED), spinner+disabled (PENDING), "Download" (DONE)
  - `downloadAll`: downloads DONE sessions, triggers generation for null/FAILED with 1s stagger

### Locale changes
- `admin.notices.*` subtree dropped from both locales
- Main's `notices.*` namespace adopted (includes `markdown.*`, `preview.*`, `meta.*` subkeys)
- Both `proctoring.close_expanded` (branch) and `proctoring.back_exam` (main) kept
- `detail.generate` and `detail.download_after_exam` added

### package.json
- `dompurify ^3.4.5` added; Apollo-era `graphql`/`install` dropped
- `markdown-it ^14.2.0` was already present on branch

---

## 3. Next step: open the PR

The branch is ready to merge into `main`. Run the smoke tests below, then push and open a PR.

### Smoke tests (manual, no test suite)

| Area | What to check |
|------|--------------|
| Notices | Banners render bold/italic/link/code/strikethrough in the app |
| Notices | Dismiss works for SINGLE and TIMED; ALERT cannot be dismissed |
| Admin notices | Live preview in create/edit form updates as you type |
| Admin notices | Markdown legend (`<details>`) collapses/expands |
| Proctoring | "Back to Exam" button navigates to `/exams/{id}` |
| Exam detail | Session rows show correct button: Generate / spinner / Download |
| Exam detail | "Download all" disabled while exam is not `completed` |
| Exam detail | After triggering generation, status transitions PENDING → DONE and auto-download fires |

### Push and PR

```sh
git push origin feat/rewrite-proctor
gh pr create --title "feat(proctor): rewrite — Pinia Colada + services layer + video + markdown" \
  --base main
```

---

## 4. Known gaps (non-blocking)

| Item | Detail |
|------|--------|
| `detail.copied` locale key missing | `ExamDetailView` references `t('detail.copied')` for clipboard tooltip; key not in `en.json`/`de.json`. Pre-existing gap; tooltip falls back to key name. Add before smoke tests if visible. |
| `notices.errors.forbidden` dropped | FORBIDDEN query errors in `AdminNoticeBannersView` now surface `err.message` directly. Acceptable — the message is descriptive. |
| Component proposals from PHASE12 | `FramePlaceholder.vue`, `UiButton variant="pager"`, `UiButton fullWidth` — still deferred. See PHASE12 notes in git log if needed. |
