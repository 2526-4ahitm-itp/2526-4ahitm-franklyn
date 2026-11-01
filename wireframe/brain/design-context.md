# Design Context — Franklyn Proctor (greenfield rewrite)

Created 2026-11-01. Rewritten 2026-11-01 after the dashboard review rounds.
Companion file: [`feedback-log.md`](feedback-log.md) — the owner's feedback in order, with the
reasoning behind each decision. Read both before touching a wireframe.

---

## ⛔ HARD RULE — DO NOT READ `proctor/`

The existing `proctor/` Vue app is being **rebuilt from scratch**. Its current design is
explicitly rejected by the project owner.

**Never** read, open, grep, screenshot, or take inspiration from anything under
`proctor/` when doing design work. Not `src/views/`, not `src/components/`, not
`src/assets/main.css`. Do not treat it as "the existing design system". Do not use it as the
baseline for an "Option 1: Safe Option" — there is no existing design system to extend. "Safe"
here means *conventional and low-risk*, not *like the old app*.

Same rule for the screenshots in `hugo/static/` (`Teacher-Dashboard.png`, `Proctoring.png`,
`Create-Exam.png`) — those show the old UI. Ignore them.

Allowed sources: `README.md`, `hugo/content/en/docs/**`, `hugo/content/en/guide/**`,
`concept.md`, the `server/` Java models, and whatever the owner says in chat.

Working directory is the worktree `/home/jakki/projects/franklyn.feat-proctor-redesign`
(branch `feat/proctor-redesign`). The wireframes live in `wireframe/`, not in `proctor/`.

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

Primary use case: teachers monitor and revisit student recordings. Do not overfit to that —
see *Future Scope*.

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

- **`title` is one free string.** There is no class field and no subject field. Do not render a
  title as "name + class" — that was explicitly rejected. If a teacher wants the class in there,
  they type it into the title.
- **`pin` is a single integer**, assigned randomly from a configured range — default `1337`–`4200`
  (`application.properties:67-68`, `franklyn.pin.min` / `franklyn.pin.max`, used in
  `ExamResource.java:83`). Four digits. **Not** a formatted code, **not** `1337-4200`. The
  "(1337-4200)" in the websocket docs is the range, and it misled the first wireframe round.
- **State is derived**, not stored as an enum: `startedAt == null` → SCHEDULED,
  `startedAt != null && endedAt == null` → LIVE, `endedAt != null` → FINISHED.
- **Participants and recordings** come from counting `ExamSession` rows per exam;
  `videoFilePath` / `videoStatus` carry the recording.
- **Room does not exist** on the server. It is treated as an optional future field.
- Planned-vs-actual duration = `startTime`/`endTime` against `startedAt`/`endedAt`.
- **Dropouts and gaps are not modelled yet.** They appear in the wireframes as plausible future
  stats; do not promise them.

---

## Exam lifecycle

An exam exists before students can join and must be **manually opened** by the teacher.

Current model for design purposes: **SCHEDULED → LIVE → FINISHED**.

The owner has said the lifecycle is not settled — LIVE may later split into something like
PREPARATION / PREFLIGHT / RUNNING. **Design for the three states only, do not overfit.** When it
splits it affects the state slot and the secondary slot of the card, nothing else.

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

State labels used in the wireframes: `SCHEDULED`, `LIVE`, `FINISHED`.

---

## Target Platform

**Desktop / Web.** Teachers work at a desk watching a grid of student screens. No mobile
wireframes required.

---

## Future Scope (leave room, do not build)

The owner explicitly warned against overfitting — "it will change". Expected later:

- Monitoring student **code changes**, not just screens
- A **built-in chat** between teacher and students
- Live replay during the session (the segment format already allows it)

Structural consequence: the dashboard must absorb a new monitoring type and a new communication
surface without a relayout. In the current wireframes that is the second side-widget slot and, in
the search-scoped layouts, another filter chip.

---

## LAYOUT RULES (settled — do not re-litigate)

### The width rule

One centred container, `max-width: 1300px`, shared by the header and the body. Inside it, a grid:
the list column (`minmax(0, 1fr)`) and the widget column (`300px`).

- Wide viewport: the container is capped and centred; margins fall outside it.
- Narrow viewport: the container fills the viewport, both columns shrink, nothing is centred any
  more and nothing is dropped.
- **No breakpoint, no drawer, nothing hidden.**

1300 is a maximum, not a fixed track. The widget column is **part of main**, not a sidebar hanging
off its side — an earlier version with a separate side region outside the cap was rejected because
main was no longer centred and the header looked detached.

### The header

Header content sits inside the same centred container as the body. Only the rule under it spans
the viewport. Brand, (global search where present), user menu.

### The exam card — four slots, no more

```
┌────────────────────────────────────────────────────┐
│ ┏━━━━━━┓                                           │
│ ┃ 2048 ┃   ITP Test 3                              │
│ ┗━━━━━━┛   18 of 22 connected              LIVE    │
└────────────────────────────────────────────────────┘
```

1. **PIN** — leads the card, the only monospace element, greys out when the exam is finished.
2. **Title** — one string, never split into name + class.
3. **One secondary line**, state-dependent and never a comma-joined pile of facts:
   - SCHEDULED → when it starts
   - LIVE → connected count
   - FINISHED → duration
   - an optional room shares this slot; it never adds a second line
4. **State** — `SCHEDULED` / `LIVE` / `FINISHED`.

**No action buttons on cards.** The whole card opens the exam detail page; monitor, reschedule,
recordings, copy-PIN all live there. An earlier version with per-card action buttons and a
three-fact footer was rejected as clutter.

More props are coming. A new prop has to **earn** a slot by pushing something out — it does not get
appended.

### Lists

- Infinite scroll with an **IntersectionObserver sentinel** at the end (and at both ends on the
  timelines). **No load-more buttons anywhere.**
- The timelines scroll in two directions from "now", which implies scripted scroll positioning
  rather than the native one — the same mechanism that makes "jump to date" work.

### Side widgets

Each one is a **card in its own right** — own border, own header — not a slice of one tall
sidebar. There is no divider rail. The `LAST EXAM` card is the attention-getter among them.

### Search

- Timeline and list layouts: **filters in place**.
- Week Strip: a **dropdown of small result cards** over the page, like a search suggestion list —
  filtering in place would destroy the week window. Picking a result moves the strip to that
  exam's week.
- In the spine layouts the field sits in the **timeline header** next to `+ NEW EXAM`, not in the
  top bar — a global bar floating above the timeline read as unintegrated.

### Primary action

`+ NEW EXAM` is the single filled block on the page and must never be hard to find. A quiet
"Schedule" button inside a column was explicitly rejected.

### Empty state

The list itself with a placeholder in it — *"Nothing here yet, schedule an exam!"* — **not** a
separate illustrated screen.

### Out of scope for the frontend design

Connection-loss and error states. The frontend only displays what server and sentinel report;
those surfaces are easy to slot in later.

---

## Visual rules for the wireframes

These are **layout study** rules, not a design system. The real colour and type system comes from
`hugo/content/en/docs/reference/design-guidelines/` (`colorspec.pdf`,
`franklyn-designguidelines.pdf`) — the owner considers colour already settled.

- No shadows, no gradients, no decorative strokes, no icon sets.
- Two border weights carry meaning: **2px = region boundary, 1px = item separator**. Keep them.
  (A flattening pass to a single 1px weight was tried and reverted — the hierarchy was lost.)
- Softened palette so it is readable for a long review: ink `#2e2e2e` on paper `#fcfcfc`,
  hairlines `#dcdcdc`, strong rules `2px #5f5f5f`, fill `#efefef`. Not pure black on pure white.
- `--radius: 3px` on boxes. Just enough to be easy on the eyes.
- **Tokens, not magic numbers.** Everything comes from custom properties in
  `wireframe/0111-teacher-dashboard/styles.css`. One card, one button, one badge — never a second
  variant of an element with slightly different padding. This is the discipline the real build
  must inherit.

### Wireframe shell

The page renders full-viewport so the layout gets the whole screen. The review chrome is pushed
out of the way: option tabs fixed bottom-right, title fixed bottom-left, and the UX notes in a
right-edge drawer labelled `UX NOTES` that slides in on hover. Pure CSS, no change to the skill's
inline script.

---

## Current state of the dashboard wireframe

File: `wireframe/0111-teacher-dashboard/index.html` (open it directly in a browser).

Four surviving options plus a Summary tab:

| Tab | Name | Navigation model | How "now" is expressed |
|---|---|---|---|
| 1 | **Rail Classic** | Filter chips over one list | A `LIVE` state on a card |
| 2 | **Spine · Today Band** ★ | Continuous time axis | A bounded `TODAY` band holding today's exams |
| 3 | **Spine · Day Clock** | Continuous time axis | A tick on a real hour scale, cutting the live block |
| 4 | **Week Strip** | Time-window scoping | A highlighted day in the strip |

Options 2 and 3 are **two forks of the same spine**, kept deliberately so they can be compared.

### The "now" problem and the two answers

A `NOW` line drawn between two cards implies now falls in a *gap*, which is false while an exam is
running — exams are long, a line is a point. Two fixes were built:

- **Fork A (Option 2)** widens now into a **region**. `TODAY · MON 2 NOV` is a bounded band
  holding today's exams in clock order, with `NEXT UP · IN 3H 18M` as a marker *between* them. The
  band breaks the time gutter on purpose — it is a region, not an event, so it gets no node on the
  axis. It stays present on an empty day (`TODAY · NO EXAMS`) so the scroll anchor never vanishes.
- **Fork B (Option 3)** gives today a **real hour scale**, so a point marker becomes truthful. The
  `09:42` tick cuts through the live block. Duration becomes visible without being written, and
  back-to-back collisions are obvious. Degrades on a thin day: a tall rail holding one short block.

They are not exclusive — the band could expand into the rail on demand.

### Dropped options (do not resurrect without a reason)

- **Now Bar** — "standard but worse".
- **Two Lanes** (upcoming column + archive column) — too complicated.
- **Command First** (search-as-dashboard) — "a worse Now Bar".

---

## Where this stands

Parked. The owner is sharing the four options with colleagues to decide which to take forward.

**Next page is the exam detail page** — every card points at it and it absorbs everything stripped
off the cards. The owner wants to explain it properly first; **do not start it unsolicited.**

The admin area is a basic CRUD, explicitly out of scope for now.

Pick the surviving spine fork before designing the detail page — it decides the time model the
detail page inherits.
