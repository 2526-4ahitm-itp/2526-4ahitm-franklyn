# Feedback Log — Teacher Dashboard wireframe

Every round of owner feedback on `wireframe/0111-teacher-dashboard/`, in order, with what changed
and why. The settled rules are consolidated in [`design-context.md`](design-context.md) — this
file is the history, so a later session can tell a deliberate decision from an accident.

Session date: 2026-11-01. Branch `feat/proctor-redesign`.

---

## Round 0 — the brief

- Proctor is being rebuilt greenfield. GraphQL → REST so MVVM makes sense.
- The owner supplied a hand sketch of the dashboard: search bar, user chip, large calendar or
  GitHub-style activity grid, a column of exam rows, a "summary about last/next test" box, a small
  calendar.
- **The sketch is an element inventory, not a layout.** Quote: *"if i see the exact layout in the
  wireframe you'll show me i do not want to see that. it can be similar yes but one to one is not
  desired because why would i need you then?"*
- **Do not seed anything from the old `proctor/` app**, even indirectly. The owner refused to
  supply screenshots of it on purpose.
- Use case: teachers monitor and revisit student recordings. Later: code-change monitoring, chat.
  *"just so you don't overfit this project. it will change."*
- Wanted consistency like a real project: CSS variables and components, not the same button
  re-typed with slightly different pixel values each time.

Answers given at the start:
- Scope: **wireframes only**, no colour variants — colour is already specified in the design
  guidelines PDFs.
- Platform: **Desktop / Web**.
- Exam list: owner unsure between past-heavy and future-heavy. *"the user should easily get to past
  exams and to the next to be live exam, but if a future exam needs a reschedule or smth it should
  also be easy for a non technical teacher to find that. maybe even 2 lists?? ... 2 lists are bold
  though and if must be executed perfectly."* → explored as one option among five.

**Produced:** five options — Rail Classic, Now Bar, Day Spine, Two Lanes, Command First.

---

## Round 1 — declutter, and it is layout not design

Feedback:

1. **Too cluttered and overwhelming for teachers**, even for a dashboard. *"The devil is in the
   details and there are too much."*
2. **Date + students + room as a card footer is way too much.**
3. **Title must be one thing**, not title plus class rendered separately.
4. **PIN is more important than you think** — must lead the card, highlighted.
5. **Overbadging at the end of the card is crazy.** State is fine; `Recordings`, `Reschedule` and
   other actions must go entirely. Exams get their own detail page.
6. **"I hope this is actually just layout and not design"** — called out "typical AI slop rounded
   corners, thin lines". This is UX and rough layout, not a design comp.
7. **`+ NEW EXAM` must be prominent.** The quiet "Schedule" button inside the Two Lanes column was
   a bad call.
8. Wanted a **main region ~1300px with side content outside it**, so large screens are not weird.
9. Asked whether the review chrome could get out of the way so the layout gets the full screen.

Per-option verdicts:

| Option | Verdict |
|---|---|
| Rail Classic | *"the classic safe option i would be fine settling on"* — keep |
| Now Bar | *"looks like standard but worse. leave it"* — **dropped** |
| Day Spine | *"a really nice idea ... looks nice and intuitive"* — keep, expand |
| Two Lanes | *"looks to complicated, scrap it"* — **dropped** |
| Command First | *"looks like a worse Now Bar"* — **dropped** |

Asked for one new third option.

**Changed:** card reduced to four slots with PIN leading and no actions; all radii removed;
`+ NEW EXAM` became a solid block; wireframe shell went full-viewport with tabs as a fixed bar and
UX notes as a hover drawer; third option **Week Strip** added (time-window scoping — the past is a
step backwards, not a filter).

---

## Round 2 — decisions taken by question

- **Card density: 4 slots.** PIN · title · one state-dependent secondary · state. Framed as
  *slots, not fields* at the owner's request: *"with the exam cards feedback i just wanted less
  clutter, there will be more props on the exam, don't be too specific."*
- **Third option: Week Strip.**
- **Width:** 1300 is a **max, not a fixed value**. *"if viewport is narrow then in an abstract way
  main basically becomes just a section with main being the whole screen with submain and the
  calendar. the inner main would then not be centered."* Supplied two sketches: wide = main +
  calendar centred as a pair with margins outside; narrow = the pair fills the viewport, flush.
  → one grid, no breakpoint, nothing dropped.

---

## Round 3 — PINs, scrolling, and the "now" problem

1. **PINs are plain numbers**, not ranges, not formatted codes. *"not sure how you come to this
   solution anyways"* — the `(1337-4200)` in the websocket docs is the configured **range**
   (`franklyn.pin.min` / `.max`), and it had been misread as a format. Verified in
   `ExamResource.java:83` and `application.properties:67-68`.
2. **Lists must scroll infinitely** — observers, no load-more buttons. The timeline therefore has
   no native scroll in the normal sense: it is JS-driven so it can page up and down from "now".
3. **The NOW strip is wrong.** *"now must be between exams but exams are long and now is a
   point."* A line between two cards claims now falls in a gap, which is false while an exam runs.
   Asked for a more intuitive fix, suggesting a section like "today".
4. **Week Strip: drop the empty day slots** — the strip already covers the days.
5. **Spine: want a next-up indicator** for the next exam today, integrated with the now strip.
6. **Want a last-exam card** next to the calendar with real stats: actual time taken, etc.
7. **Fork the spine into two** so the two answers can be compared.

**Changed:** PINs became four-digit integers; load-more buttons became observer sentinel rows;
spine forked into **Today Band** (now as a bounded region) and **Day Clock** (today drawn to an
hour scale so a point tick is truthful); `LAST EXAM` stats card added to every option; header
content constrained to the main column; Week Strip empty-day groups removed.

---

## Round 4 — structure fix

*"the structure got messed up, there is main and side but main is not in the center so the navbar
also is scuffed and not in the center. just include the widgets in main and make the entire thing
be main, it looks better anyways."*

The previous attempt had main capped and the side region hanging outside the cap, which left main
off-centre. **Changed:** one centred container at `max-width: 1300px` holding both columns; the
header shares the same container.

---

## Round 5 — widgets, search placement, calendar

1. **Side widgets must be proper cards** — at minimum the last-exam one. *"currently it looks
   connected as if it is just a big sidebar."*
2. *"I really like the section with a true timeplan of the spine fork"* — the Day Clock hour rail
   landed.
3. **The search bar is not integrated in the spine** — it just sat at the top. Moved into the
   timeline header next to `+ NEW EXAM`.
4. **Copy the Week Strip calendar's current-week highlight** to the other options.

Answers to the "what is missing" checklist:

- **Empty state** → the list itself with a placeholder: *"Nothing here yet, schedule an exam!"*
- **Search** → in place in the timeline and list layouts; in Week Strip a Google-style popup with
  little result cards.
- **Connection / error states** → *"not of concern now ... the work of the backend and sentinel,
  the frontend just displays."*
- **Exam detail page** → next, but *"i would have to explain it better so don't do it yet, only
  when i start."*
- **Admin area** → basic CRUD, out of scope.

---

## Round 6 — contrast, and one revert

Asked to turn the contrast down and make it easier on the eyes — small radii allowed, *"but don't
make it look good in the way you would design"*.

**Kept:** softened palette (`#2e2e2e` ink on `#fcfcfc` paper, `#dcdcdc` hairlines, `2px #5f5f5f`
strong rules), `--radius: 3px` on boxes.

Then: *"there are weird stylish choices like having 2 borders on a 4 side card etc. remove all
those specific stylish choices as those are just visual clutter and confuse when wanting to make
sense of the layout."* A flattening pass followed — single 1px border weight everywhere, cards
separated by gaps instead of shared edges, no inverted header bars, no 2px emphasis.

**The owner reverted that pass.** The two-weight system (2px region boundary / 1px item separator)
is back and is the current state. Do not flatten it again without being asked.

---

## Still open

- **Which option wins.** Being reviewed with colleagues. Nothing should be built until that lands.
- **Exam detail page** — next, on the owner's cue, with their explanation first.
- Whether the Today Band and the Day Clock merge (band by default, expanding into the rail on
  demand).
