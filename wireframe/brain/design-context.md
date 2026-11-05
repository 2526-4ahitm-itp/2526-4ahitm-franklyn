# Design Context — Franklyn Proctor (greenfield rewrite)

The single source of current state for everything under `wireframe/`. Read it before touching a
wireframe and keep it updated as you work.

---

## ⛔ HARD RULE — SOURCES FOR `wireframe/` WORK

`proctor/` is being rebuilt from scratch and carries no authority over the new work. Draw only
from: `README.md`, `hugo/content/en/docs/**`, `hugo/content/en/guide/**`, `concept.md`, the
`server/` Java models, and whatever the owner says in chat.

The old app stays out of scope: everything under `proctor/` and the screenshots in `hugo/static/`
(`Teacher-Dashboard.png`, `Proctoring.png`, `Create-Exam.png`).

"Safe" means conventional and low-risk.

Working directory is the worktree `/home/jakki/projects/franklyn.feat-proctor-redesign`
(branch `feat/proctor-redesign`). The wireframes live in `wireframe/`, not in `proctor/`.

---

## ✅ WORKING MODE — DECIDE AND APPLY

In `wireframe/`: research, decide and apply in the same turn, then show the result. Plan-first
applies to `proctor/`, `server/` and `sentinel/`.

Ask when the request has two readings that lead to genuinely different work, or when a file
outside `wireframe/` would have to change.

---

## App Overview

Franklyn lets a teacher watch student screens live during an exam and revisit the recordings
afterwards.

- **Sentinel** — Rust agent on the student machine. Captures the screen, streams frames to the
  server over WebSocket, and (per `concept.md`) records fragmented MP4 / CMAF segments uploaded
  continuously and replayed later as HLS.
- **Server** — Quarkus/Java. Auth, exams, WebSocket fan-out, PostgreSQL.
- **Proctor** — the teacher-facing web app. This is what we are designing.

The rewrite drops GraphQL for REST so the frontend can be plain MVVM.

Primary use case: teachers monitor and revisit student recordings. Keep it open for the additions
in *Future Scope*.

---

## What the server actually models

Verified against the code, not assumed. Check again before relying on it.

`server/src/main/java/at/ac/htlleonding/franklynserver/repository/exam/model/Exam.java`

```java
record Exam(UUID id, UUID teacherId, String title,
            Instant startTime, Instant endTime,
            Instant startedAt, Instant endedAt,
            Integer pin)
```

`.../repository/exam/model/ExamSession.java`

```java
record ExamSession(UUID studentId, UUID sentinelId, UUID examId,
                   String videoFilePath, String videoStatus)
```

Consequences for design:

- **`title` is one free string** — the server carries no second field for class or subject. Render
  it as one thing. A teacher who wants the class in there types it into the title.
- **`pin` is a single integer**, assigned randomly from a configured range — default `1337`–`4200`
  (`application.properties:67-68`, `franklyn.pin.min` / `franklyn.pin.max`, used in
  `ExamResource.java:83`). Four digits, rendered as a plain number.
- **State is derived**, not stored as an enum: `startedAt == null` → SCHEDULED,
  `startedAt != null && endedAt == null` → LIVE, `endedAt != null` → ENDED.
- **Participants and recordings** come from counting `ExamSession` rows per exam;
  `videoFilePath` / `videoStatus` carry the recording.
- **Room** is an optional future field; the server has no column for it.
- Planned-vs-actual duration = `startTime`/`endTime` against `startedAt`/`endedAt`.
- **Dropouts and gaps** would need a model change first.

---

## Exam lifecycle

Three internal states — **SCHEDULED, LIVE, ENDED** — shown as five on the surface:

| UI state | Internal | When | Primary action |
|---|---|---|---|
| `SCHEDULED` | SCHEDULED | Not opened yet | `OPEN NOW` — state transition |
| `OPEN` | LIVE | Opened, start time still ahead | `START NOW` — writes the actual start, no transition |
| `LIVE` | LIVE | Start time passed (actual, else scheduled) | `OPEN MONITORING` |
| `OVERTIME` | LIVE | Clock past the scheduled end | `OPEN MONITORING` |
| `ENDED` | ENDED | Exam ended | — |

Opening, starting and ending also happen automatically on time; the buttons are the manual early
path. Only opening and ending change the internal state. `EXTEND` moves the scheduled end, which
is what pulls an exam out of OVERTIME.

Everything live-only — monitoring above all — works in OPEN, LIVE and OVERTIME, because all three
are internally LIVE. Students stream from the moment they join, so the student region is identical
across them. Full edit is allowed only in SCHEDULED; the title stays editable in every state;
delete is always available.

**`OVERTIME` is purple** — `--fr-overtime`, the colour specification's accent
(`hsl(265 55% 55%)`), the seventh core in `wireframe/tokens.css`, with `--s-over` (text) and
`--s-over-bg` (the notice fill) per mode.

State colours on the detail page: SCHEDULED `--s-info`, OPEN and LIVE `--s-live` (students stream
from the moment they join, so both are "recording"), OVERTIME `--s-over`, ENDED `--s-ok`.

`--s-live` descends from **`--fr-live`** (`hsl(0 78% 55%)`), its own core. LIVE stays red — the
recording convention — but no longer borrows `--fr-error`: a running exam is not an error, and the
two values are now free to move apart. `--fr-error` is only the current-minute rule and
`DELETE` / `END EXAM`.

**Every state label is a badge**, on both the dashboard cards and the detail head: the state colour
at 16% as the fill, the full value as the label. The light-mode `--s-*` steps are set by the 4.5:1
floor against that fill, which is deeper than the chroma-parity steps they replaced.

---

## Domain Vocabulary

| Term | Meaning |
|---|---|
| **Exam** | A proctored session. One title, a scheduled window, a PIN, participants. |
| **PIN** | Four-digit integer in the configured range. The teacher reads it out loud to the room. |
| **Sentinel** | One student's connected agent. Appears/disappears live (`server.update-sentinels`). |
| **Participant / Student** | The person behind a sentinel. Joins by entering their name. |
| **Frame** | A screen capture pushed every couple of seconds (`sentinel.frame` → `server.frame`). |
| **Profile** | Stream quality the proctor requests: `HIGH` / `MEDIUM` / `LOW`. |
| **Subscription** | Proctor opting in to a specific sentinel's frames. |
| **Recording / Run** | Post-exam playback. A session splits into runs with gaps; the scrub bar is wall-clock, not media time. |
| **Role** | `teacher` and `admin`. Admin reaches an admin area; non-admins hit `/not-allowed`. |

State labels used in the wireframes: `SCHEDULED`, `OPEN`, `LIVE`, `OVERTIME`, `ENDED`. These are the
only spellings — there is no `FINISHED`.

---

## Target Platform

**Desktop / Web only.** Teachers work at a desk watching a grid of student screens.

---

## Future Scope (leave room, build when asked)

Expected later:

- Monitoring student **code changes**, not just screens
- A **built-in chat** between teacher and students
- Live replay during the session (the segment format already allows it)

The dashboard must absorb a new monitoring type and a new communication surface without a
relayout. The room for it is the second side-widget slot and, in the search-scoped layouts,
another filter chip.

---

## MAINTAINING THESE FILES

Update this file in the same turn as the change.

This file is the only place. Layout rules, colour rules, preferences and working agreements go
here, rather than into agent-local memory, a scratchpad or a chat summary.

Write current state and rules only. When something changes, edit the paragraph that describes it
so the file always reads as the present state.

---

## Layout rules

### The width rule

One centred container, `max-width: 1300px`, shared by the header and the body. Inside it a grid:
the list column (`minmax(0, 1fr)`) and the widget column (`300px`).

- Wide viewport: the container is capped and centred, margins fall outside it.
- Narrow viewport: the container fills the viewport and both columns shrink.
- One continuous scale across all widths — every element stays on screen at every size.

1300 is a maximum, not a fixed track. The widget column is part of main.

### The header

Header content sits inside the same centred container as the body; the rule under it spans the
viewport. Brand, user menu, and in the list layout a global search field.

### The exam card — four slots, finalized

```
┌────────────────────────────────────────────────────┐
│ ┏━━━━━━┓                                           │
│ ┃ 2048 ┃   ITP Test 3                              │
│ ┗━━━━━━┛   09:00 – 10:30             SCHEDULED     │
└────────────────────────────────────────────────────┘
```

1. **PIN** — leads the card, the only monospace element. Drawn identically in every state: it used
   to grey out on a finished exam, which was variance the state badge beside it already carried.
2. **Title** — the one string from the server, rendered whole.
3. **Time** — the clock range on the day. The day itself comes from the timeline gutter.
4. **State** — `SCHEDULED` / `LIVE` / `ENDED`, as a badge.

The whole card is the link to the exam detail page, so these four slots are all it carries. A new
prop has to earn a slot by pushing one of them out.

### Lists

Infinite scroll, driven by an `IntersectionObserver` sentinel at each end of the timeline. The
timeline opens anchored on today, which needs a scripted scroll position — the same mechanism that
makes "jump to date" work.

### Time direction

Everything on the page runs **oldest at the top, newest at the bottom** — the spine and the hour
rail agree. `LOADING FURTHER BACK` sits above the first card, `LOADING FURTHER AHEAD` below the
last.

### Side widgets

Each one is a card in its own right — own border, own header. Two of them:

- **Calendar** — month navigation (`‹ NOVEMBER 2026 ›`), weekday row, today marked, days holding
  exams marked. Picking a day moves the timeline to it.
- **LAST EXAM** — exactly four lines: title, `Mon 19 Oct · 08:00`, `Actual 1h 48m`,
  `Recordings 22`.

### Search

- Timeline and list layouts: filters in place. In the spine layouts the field sits in the timeline
  header next to `+ NEW EXAM`.
- Week Strip: a dropdown of small result cards over the page. Picking a result moves the strip to
  that exam's week.

### Primary action

`+ NEW EXAM` is the single filled block on the page.

### Empty state

The list itself with a placeholder in it — *"Nothing here yet, schedule an exam!"*

### Error states

The frontend displays what server and sentinel report. Connection-loss handling itself belongs to
the server and the sentinel.

---

## Content rule — only signed-off elements

Every element on screen has been asked for by name. When a new element seems needed, propose it
and wait for sign-off.

Dividers earn their place the same way: they exist where they carry layout — region borders, the
header rule, the hour lines, card borders.

---

## Colours

Values come from tokens, so a colour decision is made once in one place and every component reads
it. There is one card, one button and one badge, each defined once.

### Colorways — `wireframe/0111-teacher-dashboard/colorways.css`

Three independent controls: **design option × colorway × light/dark**. Colorway and mode are
`data-colorway` and `data-mode` on `.page-wrapper`, switched by the panel above the option tabs.

The file has three layers, each written once:

1. **Palette** `--p-*` — raw values, per colorway × mode. The only place a colour literal appears.
   Where two roles share a value, the second references the first.
2. **Semantic** `--color-*` — one block for all colorways: `primary` / `-hover` / `-active` /
   `on-primary`, `secondary`, `accent`, `bg` / `surface` / `input`, `text` / `-secondary` /
   `-tertiary` / `-disabled`, `border` / `-strong` / `focus`, `success` / `error` / `warning` /
   `info`. The older `--ink` / `--paper` / `--fill` / `--rule` names in `styles.css` are aliases
   onto these.
3. **Mapping** — component rules read semantic names.

A new colorway is one palette block per mode. A new component is one rule in layer 3.

**Colorways:** `bw` (the layout study), `franklyn` (the colour specification), `open`
(Open Color, MIT). The page opens on option 3, `franklyn`, `dark`.

**Base colour values are cited.** Every base value comes from a named source — the Franklyn colour
specification at `hugo/content/en/docs/reference/design-guidelines/color-specification/colorspec.pdf`,
or a palette published for reuse — named in a comment next to the palette block.

**Derived values are code.** Steps, ramps and state variants are computed in the stylesheet from
those cited base values — `oklch()` off a base hue is fine — so the derivation stays readable
instead of being flattened into fresh literals.

**Assignment:**

| Role | Where it lands |
|---|---|
| `primary` | top bar, `TODAY` region bar, `+ NEW EXAM`, today in the calendar, exam-day outlines |
| `primary-hover` / `-active` | pointer states on `+ NEW EXAM` only |
| `on-primary` | text and the search field's border on primary surfaces |
| `info` | `SCHEDULED` |
| `success` | `ENDED` |
| `live` | `OPEN`, `LIVE` |
| `error` | the now tick, `DELETE`, `END EXAM` |
| `accent` | `OVERTIME` |

Primary surfaces carry two colours, `primary` and `on-primary`. The hover and active steps serve
pointer states.

In `bw` the top bar is the page colour.

### Wireframe shell

The page renders full-viewport. The review chrome is pushed out of the way: colorway panel and
option tabs fixed bottom-right, title fixed bottom-left, UX notes in a right-edge drawer labelled
`UX NOTES` that slides in on hover. Pure CSS, so the skill's inline script stays untouched.

---

## Current state of the dashboard wireframe

File: `wireframe/0111-teacher-dashboard/index.html` — open it directly in a browser.

| Tab | Name | Navigation model | How "now" is expressed |
|---|---|---|---|
| 1 | **Rail Classic** | Filter chips over one list | A `LIVE` state on a card |
| 2 | **Day Clock · current** | Continuous time axis | A tick on a real hour scale |
| 3 | **Day Clock · stripped** ★ | Continuous time axis | A tick on a real hour scale |
| 4 | **Week Strip** | Time-window scoping | A highlighted day in the strip |

Tab 2 is a reference copy with every element it has ever had. **Tab 3 is the live one** and holds
only signed-off elements. Tab 5 is a Summary.

### Option 3 — the current direction

Top bar: brand, user chip. Timeline header: search, `+ NEW EXAM`, `Timeline` heading.

The spine runs oldest to newest with a day label in the gutter, a node on the axis and an exam card
per event. Today is drawn as an hour rail inside a bordered region headed `TODAY`: hour labels down
the side, each exam a block positioned and sized by its real time, and a now tick with its clock
label cutting through the live block. Exam blocks on the rail carry PIN and title only.

Side column: the calendar, then the `LAST EXAM` card.

## Current state of the exam detail wireframe

File: `wireframe/0411-exam-detail/index.html`. One option only — **Exam Detail** — plus a Summary
tab. Stacked Classic was dropped by the owner; do not bring it back.

The dashboard's design system (DESIGN.md) is applied unchanged, bound in `styles.css` straight to
`../tokens.css`. Head = the exam card enlarged: PIN (Chivo Mono, 40px) · title · state as coloured
text. The info row and run bar share one surface card; the run bar is a measured scale with its
times always visible and the dashboard's now-rule. Then the action row, then students as grid or
list (icon toggle).

**Info segments** sit in the head, right of PIN and title, as joined tiles: status · students ·
start · end. The state is never written in them; it only decides how each one phrases its figure,
so the teacher reads the answer instead of computing it:

| | status | students | start | end |
|---|---|---|---|---|
| SCHEDULED | `2 d` until open | — | `09:00` starts | `10:30` ends |
| OPEN | `8 min` until start | `8` joined | `09:00` starts | `10:30` ends |
| LIVE | `45 min` left | `21 / 22` connected | `09:03 ~~09:00~~` started | `10:30` ends |
| OVERTIME | `12 min` over (purple) | `21 / 22` connected | `09:03 ~~09:00~~` started | `10:30` was due (purple) |
| ENDED | `1 h 49 min` ran | `22` students | `09:03 ~~09:00~~` started | `10:52 ~~10:30~~` ended |

Start and end show the scheduled value until the actual exists; then the actual takes its place and
the scheduled value stays beside it, grey and struck through. EXTEND rewrites the scheduled end and
the end segment simply follows. Every student has a recording — there is no "not ready" case.

ENDED's primary action is **DOWNLOAD ALL VIDEOS**.

**No restating labels.** A heading that only names what is plainly visible does not get drawn —
STUDENTS, CONTROL, DETAILS, EXTEND TO and a LIVE stamp on every tile were all removed. A tile only
speaks when something is wrong (*No signal*, *Not ready*). Labels that carry information stay:
the times and captions on the run bar, "since 08:46", "left 09:38".

## Where this stands

The options are with the owner's colleagues for a decision on which to take forward.

**Next page is the exam detail page** — every card points at it and it absorbs everything stripped
off the cards. Start it when the owner asks.

The admin area is a basic CRUD, out of scope.
