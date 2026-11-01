# Design Context — Franklyn Proctor (greenfield rewrite)

Generated: 2026-11-01

## ⛔ HARD RULE — DO NOT READ `proctor/`

The existing `proctor/` Vue app is being **rebuilt from scratch**. Its current design is
explicitly rejected by the project owner.

**Never** read, open, grep, screenshot, or take inspiration from anything under
`/home/jakki/projects/franklyn/proctor/` when doing design work. Not `src/views/`, not
`src/components/`, not `src/assets/main.css`. Do not treat it as "the existing design system".
Do not use it as the baseline for an "Option 1: Safe Option" — there is no existing design
system to extend. "Safe" here means *conventional and low-risk*, not *like the old app*.

Same rule for the screenshots in `hugo/static/` (`Teacher-Dashboard.png`, `Proctoring.png`,
`Create-Exam.png`) — those show the old UI. Ignore them.

Sources that ARE allowed: `README.md`, `hugo/content/en/docs/**`, `hugo/content/en/guide/**`,
`concept.md`, and whatever the owner says in chat.

## App Overview

Franklyn lets a teacher watch student screens live during an exam, and revisit the recordings
afterwards. Three parts:

- **Sentinel** — Rust agent on the student machine. Captures the screen, streams frames to the
  server over WebSocket, and (per `concept.md`) records fragmented MP4 / CMAF segments that are
  uploaded continuously and replayed later as HLS.
- **Server** — Quarkus/Java. Auth, exams, WebSocket fan-out, PostgreSQL.
- **Proctor** — the teacher-facing web app. This is what we are designing.

The rewrite drops GraphQL for REST so the frontend can be plain MVVM.

## Domain Vocabulary (use these words in wireframes)

| Term | Meaning |
|---|---|
| **Exam** | A proctored session. Has a PIN, a class, a subject, a scheduled time, participants. |
| **PIN** | Join code, format `1337-4200`. Teacher shares it; students' sentinels register with it. |
| **Sentinel** | One student's connected agent. Appears/disappears live (`server.update-sentinels`). |
| **Participant / Student** | The person behind a sentinel. Joins by entering their name. |
| **Frame** | A screen capture pushed every couple of seconds (`sentinel.frame` → `server.frame`). |
| **Profile** | Stream quality the proctor requests: `HIGH` / `MEDIUM` / `LOW`. |
| **Subscription** | Proctor opting in to a specific sentinel's frames. |
| **Recording / Run** | Post-exam playback. A session splits into runs with gaps between them; the scrub bar is wall-clock, not media time. |
| **Role** | `teacher` and `admin`. Admin reaches an admin area; non-admins hit `/not-allowed`. |

## Target Platform

**Desktop / Web.** Teachers work at a desk watching a grid of student screens. No mobile
wireframes required.

## Future Scope (design for it, do not build it)

Owner explicitly warned against overfitting. Expected later:

- Monitoring student **code changes**, not just screens
- A **built-in chat** between teacher and students
- Live replay during the session (the segment format already allows it)

Leave structural room: the dashboard should tolerate a new monitoring type and a new
communication surface without a relayout.

## Layout Patterns

- Desktop, centered content, generous max-width.
- Top navigation bar — not a left sidebar. Holds global search and the user menu.
- The **exam list is the primary object** on the dashboard. Everything else is support.
- Secondary widgets (next/last exam summary, calendar or activity grid) live in a side rail or a
  band, never competing with the list for attention.

## Navigation

- **Top bar**: product mark, global search, user avatar + name.
- **User dropdown**: Profile, Settings, Admin (role-gated), Docs, Log out.
- Dashboard → Exam detail → Live monitoring grid → Single-student detail.
- Dashboard → Past exam → Recording playback (wall-clock scrub bar, gap markers).

## Page Types

### Dashboard (this wireframe)
- Structure: top bar + content region
- Key elements: exam list (dominant), next/last exam summary, calendar or activity widget,
  global search, user menu, create/start-exam action

### Live Monitoring (later)
- Structure: grid of student frames, click to expand one
- Key elements: PIN display, participant count, quality profile switch

### Recording Playback (later)
- Structure: player + wall-clock scrub bar with gap markers, run list

## Interaction Patterns

- Dropdown menus (user menu, filters) — Reka UI primitives in the real build.
- Search with filter chips.
- Live state must be visible without a refresh: connected/disconnected sentinels change count.
- Inline row actions over hidden detail pages where possible (reschedule, copy PIN).

## Content Hierarchy

1. Is an exam **running right now**? (highest urgency — must be unmissable)
2. What is the **next** exam, and can I start / reschedule it?
3. Where are my **past** exams and their recordings?
4. Ambient: calendar / activity.

## Owner Constraints (from chat, 2026-11-01)

- The hand sketch supplied is an **element inventory, not a layout**. Reproducing it 1:1 is a
  failure. Similar is fine; identical is not.
- Non-technical teachers must find "reschedule a future exam" without help.
- Two separate lists (upcoming / past) are considered **bold** — allowed, but only if executed
  cleanly. Worth exploring as one option among several, not as the default.
- Colour is already specified elsewhere (`hugo/content/en/docs/reference/design-guidelines/
  color-specification/colorspec.pdf` and `design-rules/franklyn-designguidelines.pdf`).
  Wireframes stay black and white.

## UX Conventions

- Tokens, not magic numbers. Spacing, radii, borders come from CSS custom properties; a button is
  one component, not re-styled per screen.
- Status is a badge with a consistent shape and vocabulary (`LIVE`, `SCHEDULED`, `DONE`).
- Wall-clock time everywhere a teacher reads time.
