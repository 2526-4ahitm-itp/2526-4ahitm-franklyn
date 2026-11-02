# Product

<!-- impeccable:product-schema 1 -->

Scope: **Franklyn Proctor**, the teacher-facing web app. Sentinel (student agent) and the
Quarkus server appear here only as operating context, not as design surfaces.

## Platform

web

## Users

**Primary: teachers at HTL Leonding**, at a desk in or next to a computer room, during a
programming exam they are invigilating. The job is twofold and splits by time:

- **During the exam** — watch a room's worth of student screens at once and notice the one that
  needs attention, without leaving the desk or walking the room.
- **After the exam** — revisit a specific student's recording to check what happened.

Secondary: **admins** (`franklyn-admin`). They reach an admin area and manage system-wide
notices. Basic CRUD, deliberately out of design scope.

Students never use Proctor. They run Sentinel from a terminal (`franklyn join <pin>`) and see
only a connection/status indication.

## Product Purpose

Franklyn streams student screens to the teacher's screen live during tests and exams, and keeps
the recordings so the exam can be reviewed afterwards. Success is a teacher who can supervise a
full room from one screen and can answer, afterwards, what a given student had on screen at a
given minute.

## Positioning

Franklyn is **school-operated and on-prem**: the school runs the server, Keycloak holds the
identities, and the recordings sit on the school's own disk under a 30-day retention. It
observes and records; it never blocks an application, URL, or process, and it offers no remote
control of a student machine. A teacher sees and replays; that is the whole power it grants.

Self-hosting is a first-class path — the student agent is pointed at a server by configuration
(`franklyn config set api_url ...`), so a second school running its own `franklynN` instance is
an expected deployment, not a special case.

## Operating Context

The exam ritual, in the order it happens:

1. Teacher logs in to Proctor (Keycloak), creates an exam, or picks one already scheduled.
2. Teacher **manually opens** the exam. An exam is never auto-started by its scheduled time.
3. The server assigns a **four-digit PIN**. The teacher **reads it out loud to the room**.
4. Students run Sentinel and join with that PIN, entering their name.
5. Sentinels appear and disappear live as machines connect and drop.
6. Teacher subscribes to the screens they want and watches a grid, zooming into one when needed.
7. Teacher ends the exam. Recordings become playable.

Factual environment details that shape the work:

- Desktop browsers on the school network. Teacher and students are on the same school network
  during an exam.
- The teacher is in front of a room of people while using this. The PIN gets spoken; the grid
  gets glanced at between walking the room.
- Proctor is served under a path on the same host as the API (e.g.
  `https://franklyn3.htl-leonding.ac.at/proctor/exams/` against `franklyn3.htl-leonding.ac.at/api`).
  Teachers are told to read the server they are on off the browser URL.
- Recordings are purged automatically 30 days after an exam ends (`FRANKLYN_RETENTION_DAYS`,
  nightly at 03:00 Europe/Vienna). Anything a teacher needs to keep must be acted on inside that
  window.

## Capabilities and Constraints

Verified against `server/`, the websocket reference docs, and the README. `proctor/`'s current
UI is deliberately excluded as a source — Proctor is a from-scratch rebuild and the old
interface carries no authority.

**Exam** — `Exam(id, teacherId, title, startTime, endTime, startedAt, endedAt, pin)`.

- `title` is **one free string**. The server has no separate class, subject, or room field. A
  teacher who wants the class in the title types it into the title.
- `pin` is a **single integer**, randomly assigned from a configured range, default `1337`–`4200`
  (`franklyn.pin.min` / `.max`). Four digits. Unique across that teacher's exams.
- **State is derived, never stored**: `startedAt == null` → SCHEDULED;
  `startedAt != null && endedAt == null` → LIVE; `endedAt != null` → FINISHED. Design for these
  three.
- Teacher operations: list own exams, look up by id, look up by PIN, create, start, end, reschedule
  (start/end time only), delete. A teacher reaches only their own exams.
- Delete is a hard delete.
- `startTime`/`endTime` are the plan; `startedAt`/`endedAt` are what happened. Planned-vs-actual
  duration is derivable; nothing else about the run is.

**Participants and recordings** — `ExamSession(studentId, sentinelId, examId, videoFilePath, videoStatus)`.

- Participant and recording counts come from counting sessions per exam. There is no roster
  separate from who actually joined.
- A recording is fetched as MP4 at `/videos/{sentinelId}.mp4`, and only once `videoStatus` is
  `DONE`. Any other status means **not ready** — a state the UI has to carry, not hide.

**Live monitoring** — JSON over WebSocket (`hugo/content/en/docs/reference/websocket-comm/`).

- The proctor registers, then **sets one PIN** as a filter; it sees only sentinels on that PIN.
- `server.update-sentinels` is the authoritative live roster: `{sentinelId, name}`. Anyone absent
  from the list is dead or on another PIN. Presence is push, not poll.
- Frames are **opt-in per sentinel**: subscribe, revoke, multiple at once. Frames arrive batched
  as base64 JPEG with an index.
- Stream quality is requested as a **profile** — `HIGH` / `MEDIUM` / `LOW`. The proctor asks for a
  profile; the server decides the actual resolution. The proctor never names pixels.
- Registration can be **rejected with a reason**, and the proctor is expected to close on it.

**Identity and roles** — Keycloak (JWT/OIDC).

- Keycloak roles in use: `teacher` and `franklyn-admin`. Server-side `UserRole` is `TEACHER` /
  `STUDENT`, resolved from the LDAP `distinguishedName` claim (`OU=Teachers` / `OU=Students`).
- A user carries `preferredUsername`, `email`, and optional `givenName` / `familyName`. Display
  names can be missing — plan for the fallback.
- Non-permitted users are routed to a `/not-allowed` outcome rather than a blank failure.

**User settings** — persisted server-side per user: `theme` (`DARK` / `LIGHT` / `SYSTEM`) and
`language`.

- **Both themes ship.** Theme is a stored user preference with a system option, not a
  nice-to-have, so every surface is designed in light and dark.
- **i18n is live** and stays. Teacher-facing strings are translated; layouts must survive a
  longer German string.

**Notices** — `Notice(id, type, startTime, endTime, content)` with type `ALERT` / `TIMED` /
`SINGLE`. Admins write them; teachers read them. System-wide messages have a place in the
teacher's view.

**Explicitly undecided / not modelled:**

- **Room** — no column. Future field.
- **Dropouts, gaps, and connection history** — not modelled. Showing a session's gaps as history
  needs a server change first.
- **API protocol for the rebuild** — the server today exposes GraphQL for exams/sessions/users
  and REST for video. Moving Proctor onto REST has been discussed; treat the protocol as an open
  decision and do not design around either answer.
- **Violation detection, AI-usage alarms, file/code diffs, alarm acknowledgement, multi-monitor,
  audio** — none of this exists in the server. `spec/fsd.md` describes them; that file is
  unsigned scratch and carries no authority. Do not design to it and do not imply these features
  exist.
- **Live replay during a session** — the segment format allows it; it is not built.
- **Monitoring code changes** and an in-app **teacher–student chat** are expected eventually. The
  dashboard should be able to absorb a new monitoring type and a new communication surface without
  a relayout.

## Brand Commitments

- Name: **Franklyn**; the teacher web app is **Franklyn Proctor**, the student agent is
  **Franklyn Sentinel**.
- Banner/logo asset: `images/banner.png`.
- Binding design references, both published in the docs site:
  - `hugo/content/en/docs/reference/design-guidelines/color-specification/colorspec.pdf` — the
    Franklyn colour specification. Base colour values come from here and are cited where used.
  - `hugo/content/en/docs/reference/design-guidelines/design-rules/franklyn-designguidelines.pdf`
    — the design guidelines, with a mockup prototype linked from the same page.
- Docs voice is plain, instructional, second-person ("Log in to Franklyn Proctor, …"). Proctor's
  own copy should not be louder than that.

## Evidence on Hand

- **Real server contract**: `server/src/main/java/.../repository/exam/model/`, `ExamResource`,
  `ExamSessionResource`, `VideoRestResource`, `NoticeResource`, `UserResource`.
- **Protocol reference**: `hugo/content/en/docs/reference/websocket-comm/` (server↔proctor,
  server↔sentinel, lifecycle) and `hugo/content/en/docs/reference/media-spec/` (segments,
  container, encoding, storage).
- **Teacher-facing documentation**: `hugo/content/en/guide/teachers/` — proctor access, running an
  exam, preparing students.
- **Design authority**: the two PDFs named under Brand Commitments.
- **Prior wireframe exploration**: `wireframe/0111-teacher-dashboard/` with its own current-state
  record at `wireframe/brain/design-context.md`.
- **Named team and supervisors** in `README.md`.

Absences future work must not fabricate: no testimonials, no customer list beyond HTL Leonding,
no pricing or licensing claims beyond MIT, no usage or performance numbers, no SLA. Screenshots
in `hugo/static/` (`Teacher-Dashboard.png`, `Proctoring.png`, `Create-Exam.png`) document the
**old** Proctor UI and are not a reference for the rebuild.

## Product Principles

1. **Observe, never intervene.** The product's whole offer is seeing and replaying. No blocking,
   no remote control, no reaching into a student machine — and the interface should never look
   like it could.
2. **The room is the real context.** A teacher is standing in front of people, reading a PIN
   aloud and glancing at a screen between laps. Whatever matters at that moment has to be legible
   at a glance from a few feet away.
3. **Derive state; don't invent fields.** Exam state, participant counts, and durations all fall
   out of what the server stores. A new thing on screen needs a real field behind it or it is a
   lie with a nice border.
4. **One exam, one title, one PIN.** The data model is deliberately thin. Design that renders the
   thin truth well beats design that implies structure the server does not have.
5. **Leave room at the seams.** Code monitoring, chat, and live replay are coming. They should
   land as an added surface, not a redesign.

## Accessibility & Inclusion

- **Desktop web only.** No tablet or mobile layout. Teachers work at a desk watching a grid of
  screens.
- No formal standard is mandated, but a working floor holds: every control reachable and
  operable by keyboard, and readable contrast in **both** light and dark themes (both are
  shipping user preferences, so neither is an afterthought).
- Teacher-facing copy is translated; German strings run longer than English and must not break
  layouts.
