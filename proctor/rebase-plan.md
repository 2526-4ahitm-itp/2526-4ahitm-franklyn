# Rebase / Merge Plan — `feat/rewrite-proctor` ⇆ `origin/main`

## TL;DR

- **Branch is far ahead** of `origin/main`: 60 commits past the merge base
  (`9995b2f`). Apollo is gone, Villus + Pinia Colada is in, services /
  composables / UI primitives are extracted.
- **`origin/main` shipped two product features** since the merge base
  that the branch does not have:
  1. **Notice-banner markdown rendering** (new util, new component, new
     directive, new locale namespace).
  2. **Video generation + download for exam sessions** (new schema
     field, new mutation, new REST endpoint, polling state machine in
     `ExamDetailView`).
- **Use `git merge origin/main`, not rebase.** Both features land in
  files we already rewrote, so a rebase would replay every one of our
  60 commits against the same conflicting hunks — one resolution per
  conflict at best, 60 at worst. A single merge commit gives us one
  resolution pass.
- **No conflict is structural.** Both features are additive on top of
  Apollo-era code; we have to re-implement them on top of our service
  layer and primitives. Plan below has the exact mappings.

---

## 1. Inventory of `origin/main` changes since the merge base

Merge base: `9995b2f Merge pull request #332 from 2526-4ahitm-itp/feat/i18n`.

### 1.1 Feature: notice-banner markdown (PR #338)

| Commit  | Effect on proctor |
|---------|---------|
| `8f78ca9 feat(proctor): add markdown render utility` | Adds `src/utils/noticeMarkdown.ts` with `renderNoticeMarkdown()` and `noticeSanitizeConfig`. Adds deps `markdown-it`, `dompurify`, `@types/dompurify`. |
| `e19f553 feat(proctor): add notice banners modal markdown preview` | Adds live markdown preview pane to the admin create/edit form. |
| `38115d1 feat(proctor): add notice banners ui styling` | Adds `.notice-markdown` CSS in `main.css` (link, code, strong, em, s rules). |
| `509c8f1 fix(proctor): fix linter errors` | Registers a global `v-safe-html` directive in `main.ts` (DOMPurify-backed). Touches `main.ts`, `package.json`, `App.vue`, the admin view. |
| `50dc76c feat(proctor): improve styling of the notice banner form with a legend` | Adds a `<legend>` markdown-help block inside the admin form. |
| `6931b2a feat(proctor): make notice banners a component and reuse it in the preview` | Extracts `src/components/notice/NoticeBanner.vue` (takes `contentHtml: string`, `type: NoticeType`, `dismissible?: boolean`). App.vue and the admin preview both render through it. |
| `b32f4a0 feat(proctor): add translations for admin notice banners panel` | Replaces hardcoded English in the admin view with `t(...)` calls under the **`notices.*`** top-level namespace. |

### 1.2 Feature: video generation & download (PR #340)

| Commit  | Effect on proctor |
|---------|---------|
| `8a96350 feat(proctor): add video generation and download for exam sessions` | Adds `videoStatus` field to the `ExamSession` selection; adds `generateSentinelVideo($sentinelId)` mutation; polls `allStudents` every 2s while any session is `PENDING`; auto-downloads on `DONE`; "Download all" triggers generation for missing videos and downloads any `DONE` ones; fetches `/api/videos/{sentinelId}.mp4` via blob with `Bearer` token. Touches `ExamDetailView.vue` and both locale files. |
| `87af001 fix(proctor): auto-download generated videos when using download all` | Bug-fix on the above. |
| `ae21322 fix(proctor): fix type-check and lint errors in ExamDetailView` | TS/eslint cleanups on the same file. |

Server-side companion changes that affect what the frontend can query:
- `ExamSession.videoStatus: String` (nullable)
- `Mutation.generateSentinelVideo(sentinelId: String!): Void`
- `Query.videoStatus(sentinelId): VideoStatus { state: VideoState!, link: String }`
- `GET /api/videos/{sentinelId}.mp4` (Bearer auth, returns `video/mp4`)

### 1.3 Other (no proctor impact, but in the range)

- `783905c docs: add ai section to pr template` — `.github/`, ignore.
- `5ebe1df` CI nix-cache migration — ignore.
- Server-side video-gen commits, version bumps, release notes — ignore for the frontend rebase.

---

## 2. Conflict map

Generated with `git diff --name-status 9995b2f origin/main -- proctor/` and
`git diff --name-status 9995b2f HEAD -- proctor/`. "Branch" means
`feat/rewrite-proctor` at `85af945`.

| Path | On main | On branch | Conflict severity | Strategy |
|------|---------|-----------|---|---|
| `proctor/package.json` | + `markdown-it`, `dompurify`, `@types/dompurify` | + `villus`, `@pinia/colada`; − `install`, `rxjs` | Trivial textual | Take both sets of additions; keep our removals |
| `proctor/bun.lock` | regenerated | regenerated | Trivial | After resolving `package.json`, run `bun install` to regenerate |
| `proctor/src/main.ts` | Adds `v-safe-html` directive, imports `DOMPurify` + `noticeSanitizeConfig` | Adds `installVillus(app)`, `app.use(PiniaColada)`, `initTheme()` | Easy | Combine: keep our Pinia/Villus/Colada wiring; insert main's `safeHtmlDirective` after `app.use(router)` |
| `proctor/src/App.vue` | Adds `NoticeBanner` reuse, `renderNoticeMarkdown` per active notice | Switched to `useNotices()` + `useDismissedNotices()` + `useResolvedTheme()` composables | Major | Take **our** script. In template, replace the inline `<section class="notice-banner">` with `<NoticeBanner :content-html="renderNoticeMarkdown(notice.content)" :type="notice.type" @dismiss="dismissNotice(notice)"/>`. Drop the inline notice CSS — it now lives in the component. |
| `proctor/src/components/notice/NoticeBanner.vue` | New file | Absent | None | Accept main verbatim. |
| `proctor/src/utils/noticeMarkdown.ts` | New file | Absent | None | Accept main verbatim. |
| `proctor/src/views/AdminNoticeBannersView.vue` | Markdown preview + `<legend>` + NoticeBanner reuse + `notices.*` i18n keys + uses `useNoticeStore` (Apollo era) | MVVM rewrite using `useNotices`/`useCreateNotice`/`useUpdateNotice`/`useDeleteNotice` + `<Dialog>` + `<ConfirmDialog>` + `<TextField>` + `admin.notices.*` i18n keys | Major | Take **our** script + dialog structure as the base. Layer in: (a) the markdown preview pane (uses `renderNoticeMarkdown(content)`), (b) the formatting-help `<legend>` block, (c) `<NoticeBanner>` reuse for the preview. Rename our i18n keys from `admin.notices.*` to `notices.*` to match main. |
| `proctor/src/views/ExamDetailView.vue` | Video state machine on top of Apollo `client.query` | MVVM rewrite using `useExam` / `useExamSessions` / `useUpdateExamSchedule` / `useStartExam` / `useEndExam` / `useDeleteExam` + `<NewExamDialog>` + `<ConfirmDialog>` | **Most invasive.** | Keep **our** view as the base. Re-implement main's video feature on top of our services. See §3.4 below. |
| `proctor/src/locales/en.json`, `de.json` | + `detail.generate`, `detail.download_after_exam`, full `notices.*` namespace (incl. `notices.markdown.*`, `notices.preview.*`) | + `common.*`, `nav.*`, full `admin.notices.*` namespace, `exams.errors.*`, others | Big text conflict | Use main's `notices.*` namespace as the canonical name. Merge our `common.*`/`nav.*`/`exams.*` extras in. Add main's video keys. Add main's markdown/preview subkeys. See §3.5. |
| `proctor/src/assets/main.css` | + `.notice-markdown` rules (link/code/em/strong/s) | + token blocks, dark/light overlay tokens, layout fixes | Likely textual conflict at end of file | Take both. Main's `.notice-markdown` block goes near the bottom; replace its hard-coded `'JetBrains Mono', …` with `var(--font-mono)`. |
| `proctor/src/services/sessions.ts` | n/a (file doesn't exist on main) | Selection set is `{ studentId sentinelId examId videoFilePath user { … } }` | Schema gap | Branch must add `videoStatus` to the selection (per §3.4). |

### Files only on the branch (no conflict; they survive the merge as-is)

`AGENTS.md`, `README.md`, `continuation/PHASE*.md`, `rewrite.md`,
`src/components/ConfirmDialog.vue`, `ExamRow.vue`, `ExamStatusFilter.vue`,
`ExpandedSentinelOverlay.vue`, `NewExamDialog.vue`, `ui/Badge.vue`,
`ui/Card.vue`, `ui/Dialog.vue`, `ui/Icon.vue`, `ui/TextField.vue`,
`lib/datetime.ts`, `lib/examStatus.ts`, all `services/*` files,
the deletions of `stores/{ApolloClientStore,ExamStore,NoticeStore,UserStore}.ts`.

### Files only on main (no conflict; accept as new)

`src/components/notice/NoticeBanner.vue`, `src/utils/noticeMarkdown.ts`.

---

## 3. Step-by-step plan

Do the merge on a worktree or a copy first if you're nervous; nothing here
is irreversible.

```sh
# from the proctor branch with a clean working tree
git fetch origin
git merge --no-ff --no-commit origin/main
# expected: a bunch of conflict markers in the files listed above
```

Resolve in this order — each step keeps lint/type-check able to advance.

### 3.1 Trivial dependency + bun.lock merge

In `proctor/package.json`, accept both sides' additions:

```jsonc
"dependencies": {
  // existing branch deps
  "@pinia/colada": "1.3.0",
  "villus": "3.5.2",
  // additions from main:
  "dompurify": "^3.4.5",
  "markdown-it": "^14.2.0"
},
"devDependencies": {
  // existing devDeps
  "@types/dompurify": "^3.2.0"
}
```

Then:

```sh
git checkout --theirs proctor/bun.lock          # take main's lockfile
cd proctor && bun install                       # regenerate consistently
```

### 3.2 `main.ts`

Combine: keep our pinia → keycloak.init → villus → colada → i18n → router
order. Append main's directive registration after `app.use(router)`:

```ts
import type { Directive } from 'vue'
import DOMPurify from 'dompurify'
import { noticeSanitizeConfig } from '@/utils/noticeMarkdown'

const safeHtmlDirective: Directive<HTMLElement, string> = {
  beforeMount(el, binding) {
    el.innerHTML = DOMPurify.sanitize(binding.value, noticeSanitizeConfig)
  },
  updated(el, binding) {
    if (binding.value === binding.oldValue) return
    el.innerHTML = DOMPurify.sanitize(binding.value, noticeSanitizeConfig)
  },
}

// … after app.use(router):
app.directive('safe-html', safeHtmlDirective)
```

### 3.3 New files from main

Resolve as `git checkout --theirs`:

```sh
git checkout --theirs proctor/src/components/notice/NoticeBanner.vue
git checkout --theirs proctor/src/utils/noticeMarkdown.ts
git add proctor/src/components/notice/NoticeBanner.vue \
        proctor/src/utils/noticeMarkdown.ts
```

In `NoticeBanner.vue`, after the merge, edit its `<style>` to use our
tokens (`var(--font-mono)`, etc.) rather than the hard-coded font
families that landed on main. This is a one-pass cleanup; the structure
of the component stays.

### 3.4 `ExamDetailView.vue` — re-implement video feature on top of services

Keep our `<script setup>` (services-based) as the trunk. Apply these
deltas:

1. **Add `videoStatus` to the sessions selection.** In
   `src/services/sessions.ts`, edit the GraphQL selection set:

   ```graphql
   allStudents(examId: $examId) {
     studentId
     sentinelId
     examId
     videoFilePath
     videoStatus           # NEW
     user { … }
   }
   ```

   Add `videoStatus: string | null` to the local `ExamSession` type. The
   server returns the string form of the `VideoState` enum (`PENDING`,
   `DONE`, etc.).

2. **Add `useGenerateSentinelVideo()` to `services/sessions.ts`:**

   ```ts
   const GENERATE_VIDEO_MUTATION = /* GraphQL */ `
     mutation GenerateSentinelVideo($sentinelId: String!) {
       generateSentinelVideo(sentinelId: $sentinelId)
     }
   `

   export function useGenerateSentinelVideo(examId: string): UseMutationReturn<…> {
     const queryCache = useQueryCache()
     return useMutation<null, string, NormalizedError>({
       mutation: async (sentinelId) => {
         await executeMutation(GENERATE_VIDEO_MUTATION, { sentinelId })
         return null
       },
       onSettled: () => queryCache.invalidateQueries({ key: ['examSessions', examId] }),
     })
   }
   ```

3. **Polling.** Pinia-colada exposes per-query refresh. Either:
   - **(preferred)** Set `refetchInterval` on `useExamSessions(examId)`
     conditionally — `refetchInterval: computed(() => hasPending.value ? 2000 : false)`. Check pinia-colada's option name in your installed
     version; if it's not present, fall back to:
   - A `setInterval(() => sessionsQuery.refetch(), 2000)` started in
     `onMounted` when `hasPending` flips true and cleared when it flips
     false or in `onBeforeUnmount`.

4. **Pending-download tracking.** Keep a local `Map<sentinelId, boolean>`
   ref (`pendingDownloads`). The previous values come from
   user-initiated downloads; clear an entry on auto-download.

5. **Blob download with bearer token.** Lives in a small helper —
   put it in `src/lib/videoDownload.ts`:

   ```ts
   import { useKeycloakStore } from '@/stores/KeycloakStore'

   export async function downloadSentinelVideo(
     sentinelId: string,
     filename: string,
   ): Promise<void> {
     const { keycloak } = useKeycloakStore()
     await keycloak.updateToken(30).catch(() => keycloak.login())
     const res = await fetch(`/api/videos/${sentinelId}.mp4`, {
       headers: { Authorization: `Bearer ${keycloak.token}` },
     })
     if (!res.ok) throw new Error(`Download failed: ${res.status}`)
     const blob = await res.blob()
     const url = URL.createObjectURL(blob)
     const a = document.createElement('a')
     a.href = url
     a.download = filename
     document.body.appendChild(a)
     a.click()
     a.remove()
     URL.revokeObjectURL(url)
   }
   ```

6. **Filename format.** Mirror main:
   `${lastname}_${firstname}_(${sessionIndex})_${examTitle}.mp4`,
   sanitised to ASCII-safe chars. Session index is derived by sorting
   sessions by `sentinelId` (UUID v7 → deterministic) and counting
   duplicates per (firstname, lastname).

7. **"Download all" guard.** Disable the button unless
   `examStatus === 'completed'`. Tooltip pulls from
   `t('detail.download_after_exam')`. Stagger the loop by 1s
   (`await sleep(1000)`) between sessions when triggering generation.

8. **Button states.** Three visual modes:
   - No video yet (`videoStatus` is `null` and `videoFilePath` is
     `null`) → dashed-outline "Generate" button.
   - `PENDING` → spinner inside the button, disabled.
   - `DONE` → primary-coloured "Download" button.

   Wrap this in a small `<DownloadButton>` if it pulls its weight; in
   the first cut just inline it in the row of `<ExamRow>` /
   `ExamDetailView`'s session list.

### 3.5 Locale files — pick **one** namespace and consolidate

Main uses `notices.*` (top-level). The branch uses `admin.notices.*`.
Convention from rewrite.md §6 says new keys must mirror across
`en.json` and `de.json`; main's choice is cleaner because admin is
only one consumer of notices. **Adopt `notices.*` as the canonical
name** and adapt the branch.

Concrete steps:

1. In `en.json` and `de.json`, **delete** the entire `admin.notices.*`
   subtree. Take main's `notices.*` block verbatim — it already covers
   create/edit/delete dialogs, types, errors, plus the new
   `markdown.*`, `preview.*`, and `meta.*` subkeys.
2. **Keep our own additions** that don't exist on main:
   - `common.*` (cancel, save, etc.)
   - `nav.*` (open_settings, open_admin, admin, logo_alt)
   - `exams.errors.*`
   - `settings.role_admin`, `settings.role_teacher`, `settings.role_user`
   - `common.dismiss_notice`
3. **Add main's video keys** under `detail.*`:
   ```json
   "generate": "Generate",
   "download_after_exam": "Downloads are available after the exam has ended."
   ```
   in both locales (German strings live in the de_DE side of the same
   commit on main; copy them).
4. In `AdminNoticeBannersView.vue` (after our MVVM rewrite is the
   surviving copy), rename every `t('admin.notices.X')` to
   `t('notices.X')`. Mapping is 1:1 except where main introduced
   subtler key names — diff `admin.notices.errors.*` against
   `notices.errors.*` to make sure the keys match (main has
   `start_end_required`; we had `time_range_required` — rename ours).

### 3.6 `App.vue`

Take our `<script setup>` (composables) verbatim. In the template,
replace the inline `<section class="notice-banner">` block with:

```vue
<NoticeBanner
  v-for="notice in activeNotices"
  :key="notice.id"
  :content-html="renderNoticeMarkdown(notice.content)"
  :type="notice.type"
  :dismissible="notice.type !== 'ALERT'"
  @dismiss="dismissNotice(notice)"
/>
```

Drop the inline notice CSS (`.notice-banner`, `.notice-inner`, etc.).
Keep the `.notice-stack` wrapper for the transition group.

### 3.7 `assets/main.css`

Three textual conflicts likely:
1. The token block (light/dark `:root[data-theme=…]`). Take ours.
2. `.notice-markdown` rules. Take main's. Replace its hard-coded
   `'JetBrains Mono', …` font-family with `var(--font-mono)`.
3. Bottom-of-file additions. Append both.

After resolving, grep for stale `'JetBrains Mono'` / `'Libre Franklyn'`
literals; the AGENTS.md §5 rule forbids them.

### 3.8 `AGENTS.md`

After the merge, add a short subsection to **§8 WebSocket / protobuf**
or a new **§4.x GraphQL** sub-bullet:

> The notice-banner content is **trusted markdown** rendered through
> `utils/noticeMarkdown.ts` and sanitised by DOMPurify before
> rendering via the `v-safe-html` directive. Never bypass this
> directive — never `v-html` notice content directly.

> Video downloads go through `lib/videoDownload.ts` which fetches
> `/api/videos/{sentinelId}.mp4` with a Bearer header. Don't link to
> the URL directly (it 401s in a new tab).

### 3.9 Finalise

```sh
cd proctor
bun lint:check                  # must pass with no warnings
bun type-check                  # must pass
bun run build                   # must succeed
# manual smoke:
#   - notices render with markdown (bold/italic/link/code)
#   - dismiss works for SINGLE and TIMED
#   - admin form preview reflects content as you type
#   - exam detail page shows session list
#   - video buttons reflect status (none / pending / done)
#   - "Download all" stagger works
git commit -m "$(cat <<'EOF'
chore(proctor): merge origin/main — video downloads and notice markdown

Re-implement main's video generation/download feature on top of the
services layer (useGenerateSentinelVideo, lib/videoDownload). Pull in
the NoticeBanner component and renderNoticeMarkdown utility; rewire
App.vue and AdminNoticeBannersView to render through them.

Adopt main's top-level "notices" i18n namespace; drop our
"admin.notices" copy. Keep our common/nav/exams.errors additions.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## 4. Risks and watch-outs

1. **Lockfile re-resolution may bump unrelated packages.** Run
   `bun install` once after the `package.json` resolution, then verify
   `bun lint:check && bun type-check && bun run build` all still pass
   *before* you touch the views. If a bump breaks something, pin the
   bumped package back.

2. **`renderNoticeMarkdown` is sync.** It returns a string. Don't
   pipe it through `computed` per notice in `App.vue` — render in the
   template (`:content-html="renderNoticeMarkdown(notice.content)"`)
   or compute the map up-front. Either way avoid re-rendering for
   every reactive tick.

3. **Pinia-colada `refetchInterval` API.** Confirm the exact option
   name in the installed version (`1.3.0`); the docs use
   `refetchInterval` but plugins may differ. If absent, use a manual
   `setInterval`.

4. **`videoStatus` may be `null` initially.** The polling-start
   predicate `hasPending` should treat `null` as "no pending"; only
   `PENDING` triggers polling.

5. **Schema enum-as-string.** `videoStatus` arrives as a `String` on
   the wire even though the server uses a `VideoState` enum. Compare
   against literal strings (`'PENDING'`, `'DONE'`, `'FAILED'`), or
   define a local `type VideoStatus = 'PENDING' | 'DONE' | …` in
   `services/sessions.ts`.

6. **Keycloak `updateToken` order in `downloadSentinelVideo`.** Call
   it *before* `fetch`; the fetch is going to a REST endpoint outside
   the Villus pipeline so the auth plugin won't help.

7. **`v-safe-html` global directive name collision.** None expected,
   but if a future migration adds a "safe-html" plugin or wraps the
   directive in a component, leave a TODO so the merge is documented.

8. **Locale namespace rename is mechanical but easy to miss.** After
   bulk-renaming `admin.notices` → `notices` in
   `AdminNoticeBannersView.vue`, grep the rest of `src/` for any other
   reference. There should be none.

---

## 5. Why merge, not rebase

The 60 commits on the branch include several that hit the same files
multiple times (`ExamDetailView` was modified in ~6 commits,
`AdminNoticeBannersView` in ~4, `App.vue` in ~5). A rebase replays each
commit against main; main's video feature lives in a single hunk in
`ExamDetailView.vue`, but every one of our 6 commits to that file
would have to be conflict-resolved against it. Same for the markdown
feature in `AdminNoticeBannersView.vue`.

A merge gives us **one** conflict resolution per file, with both
parent trees visible (`--ours` / `--theirs`), and preserves the linear
history of the rewrite work on the branch. If `main` is squash-merging
back later anyway, the rewrite branch's individual commits will
collapse — losing the cleanup story is the same either way, but
merging keeps it intact until then.

If a strict linear history on `main` is mandatory, the alternative is:

```sh
git rebase --interactive --rebase-merges origin/main
# squash the 60 commits down to ~10 logical chunks first,
# THEN rebase. Don't rebase 60 commits one-by-one.
```

But the default and recommendation here is **merge**.
