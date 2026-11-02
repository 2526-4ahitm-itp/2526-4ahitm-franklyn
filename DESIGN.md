---
name: Franklyn Proctor
description: Dark-grounded, borderless dashboard for teachers invigilating programming exams.
colors:
  primary: "hsl(185 72% 45%)"
  primary-ink: "hsl(185 72% 32%)"
  primary-hover: "hsl(185 72% 27%)"
  primary-press: "hsl(185 72% 23%)"
  on-primary: "hsl(0 0% 100%)"
  info: "hsl(200 85% 45%)"
  success: "hsl(145 55% 45%)"
  error: "hsl(0 78% 55%)"
  error-deep: "hsl(0 78% 38%)"
  on-error: "hsl(0 0% 100%)"
  focus: "hsl(210 85% 55%)"
  neutral: "hsl(222 16% 13%)"
  bg: "hsl(222 16% 13%)"
  surface: "hsl(222 14% 18%)"
  raise: "hsl(222 12% 24%)"
  band: "hsl(222 15% 16%)"
  text-1: "hsl(222 0% 97%)"
  text-2: "hsl(222 14% 82%)"
  text-3: "hsl(222 11% 69%)"
  axis: "hsl(222 10% 34%)"
  state-info: "hsl(200 85% 64%)"
  state-success: "hsl(145 55% 65%)"
  bg-light: "hsl(222 16% 95%)"
  surface-light: "hsl(0 0% 100%)"
  raise-light: "hsl(222 14% 92%)"
  band-light: "hsl(222 14% 97%)"
  text-1-light: "hsl(222 18% 18%)"
  text-2-light: "hsl(222 11% 26%)"
  text-3-light: "hsl(222 10% 34%)"
  axis-light: "hsl(222 12% 74%)"
  state-info-light: "hsl(200 85% 38%)"
  state-success-light: "hsl(145 55% 34%)"
typography:
  brand:
    fontFamily: "Libre Franklin, -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif"
    fontSize: "22px"
    fontWeight: 800
    letterSpacing: "0.04em"
  pin:
    fontFamily: "Chivo Mono, ui-monospace, SFMono-Regular, Menlo, Consolas, monospace"
    fontSize: "24px"
    fontWeight: 500
    lineHeight: 1.1
    letterSpacing: "0em"
  title:
    fontFamily: "Libre Franklin, -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif"
    fontSize: "18px"
    fontWeight: 500
    lineHeight: 1.35
  head:
    fontFamily: "Libre Franklin, -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif"
    fontSize: "14px"
    fontWeight: 700
    letterSpacing: "0.09em"
  body:
    fontFamily: "Libre Franklin, -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.5
  meta:
    fontFamily: "Libre Franklin, -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif"
    fontSize: "13px"
    fontWeight: 400
  state:
    fontFamily: "Libre Franklin, -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif"
    fontSize: "13px"
    fontWeight: 700
    letterSpacing: "0.06em"
  label:
    fontFamily: "Libre Franklin, -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif"
    fontSize: "11px"
    fontWeight: 700
    letterSpacing: "0.09em"
rounded:
  md: "6px"
  none: "0px"
  full: "50%"
spacing:
  sm: "8px"
  md: "12px"
  lg: "16px"
  xl: "24px"
  2xl: "32px"
components:
  button-primary:
    backgroundColor: "{colors.primary-ink}"
    textColor: "{colors.on-primary}"
    rounded: "{rounded.md}"
    padding: "12px 24px 12px 16px"
    typography: "{typography.body}"
  button-primary-hover:
    backgroundColor: "{colors.primary-hover}"
  button-primary-active:
    backgroundColor: "{colors.primary-press}"
  input-search:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.text-1}"
    rounded: "{rounded.md}"
    padding: "12px 16px"
    typography: "{typography.body}"
  card-exam:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.text-1}"
    rounded: "{rounded.md}"
    padding: "16px 24px"
  card-exam-hover:
    backgroundColor: "{colors.raise}"
  region-head:
    backgroundColor: "{colors.primary-ink}"
    textColor: "{colors.on-primary}"
    rounded: "{rounded.none}"
    padding: "12px 20px"
    typography: "{typography.head}"
  nav-bar:
    backgroundColor: "{colors.primary-ink}"
    textColor: "{colors.on-primary}"
    rounded: "{rounded.none}"
    padding: "16px 20px"
---

# Design System: Franklyn Proctor

<!-- Scope: the teacher dashboard, Day Clock · stripped, Panel skin, Libre Franklin.
     Other wireframe options and the Ledger skin are not part of this system. -->

## Overview

**Creative North Star: "The Invigilator's Desk"**

This is the surface a teacher glances at while standing in front of a room of people. They are not reading it; they are checking it between laps, from a few feet away, with a PIN they have just read out loud still in their head. Everything here follows from that: the ground is dark and quiet so nothing competes, the typography is sized for a glance rather than a session, and the two things that matter right now — what is running today, and what happened last — are the only loud objects on the page.

The system has no decorative lines. Stylistically there are none at all: every boundary is a step in fill, and anything that needs emphasis becomes a filled block rather than a bordered one. This is the single mechanic the whole surface runs on, and it is what keeps a dense screen from reading as a grid of cells. A line is drawn only when it does work no fill can do and beats the fill outright — a measured scale, a marked minute — never to style, enclose or separate. Colour is rationed hard — the ground, the text ramp and the structure are neutral, and the only saturated things on screen are the brand bar, the one primary action, the two region heads, the exam-state labels, and the red rule marking the current minute.

The anti-reference is explicit and was named by the owner: the generic AI-SaaS dashboard — hairline borders on every container, pill-shaped badges, soft radii, one blue accent scattered everywhere. Also rejected: anything that reads as "elegant". This is an educational platform for a technical secondary school, not a luxury brand, and undersized type with wide tracking was identified as the tell.

**Key Characteristics:**
- Borderless: separation is tonal, never ruled
- Dark-grounded on a desaturated navy, with a light mode of equal semantic weight
- Colour only where it carries meaning; neutral everywhere else
- One monospaced element on the whole page, and it is the PIN
- Emphasis is always a filled block, never an added edge
- Full-viewport; the page never scrolls, only the timeline does

## Colors

A desaturated navy ground carrying one teal brand voice and three functional signals. Six literal values exist in the entire system; every other colour is derived from one of them by overriding lightness only.

### Primary
- **primary** (`hsl(185 72% 45%)`): Java Beach, from the brand colour specification. Used at full brightness only on marks that carry no text — the calendar's per-exam dots and the text caret. Nothing else.
- **primary-ink** (`hsl(185 72% 32%)`): the step primary takes whenever it has to carry text. Fills the brand bar, the NEW EXAM button, the TODAY region head, the LAST EXAM head, and the calendar's today cell. 32% is a hard ceiling: white on it is 4.53:1, and 33% drops to 4.29 and fails.
- **primary-hover** (`hsl(185 72% 27%)`) / **primary-press** (`hsl(185 72% 23%)`): pointer states on the primary action and on the LAST EXAM card. These exist for interaction only and appear nowhere at rest.

### Secondary
None. The system has one brand voice. The colour specification also defines Earth Blue, Fuchsia and a warning amber; none of them earned a job on this surface and none are declared.

### Tertiary
- **info** (`hsl(200 85% 45%)`): the SCHEDULED state.
- **success** (`hsl(145 55% 45%)`): the FINISHED state.
- **error** (`hsl(0 78% 55%)`): the now-rule crossing the hour rail. **error-deep** (`hsl(0 78% 38%)`) carries the clock label on it.
- **focus** (`hsl(210 85% 55%)`): Bleu de France, the focus ring. Never used as a surface.

### Neutral
- **bg** (`hsl(222 16% 13%)`): the page ground. This is the system's neutral seed; both ramps are cut from it.
- **surface** (`hsl(222 14% 18%)`): exam cards, the TODAY region, the side blocks, the search field.
- **raise** (`hsl(222 12% 24%)`): hover state, hour-rail blocks, the month-nav buttons.
- **band** (`hsl(222 15% 16%)`): alternating hour bands inside the rail.
- **text-1 / text-2 / text-3** (`97% / 82% / 69%`): titles and figures, body, metadata and labels.
- **axis** (`hsl(222 10% 34%)`): the timeline spine and its nodes.

### Named Rules

**The Core-Only Rule.** Six colour literals exist: primary, info, success, error, focus, neutral. Every other colour in the system is written `hsl(from var(--core) h s <lightness>%)`. A new colour that cannot be expressed as a lightness step off one of the six does not belong in the system.

**The One Job Rule.** Full-brightness primary never carries text. The moment a teal surface needs a label on it, it drops to `primary-ink`. There is no third option.

**The Chroma Parity Rule.** The light and dark state colours are matched on OKLCH chroma (.122/.121 blue, .123/.125 green), not on contrast ratio. Matching ratios produces a dark navy label on white that reads as ink rather than signal. Both state pairs keep their core hue *and* core saturation; only lightness moves per mode.

## Typography

**Body Font:** Libre Franklin (with `-apple-system`, `BlinkMacSystemFont`, `Segoe UI`, sans-serif)
**Mono Font:** Chivo Mono (with `ui-monospace`, `SFMono-Regular`, Menlo, Consolas, monospace)

**Character:** Libre Franklin is a Franklin Gothic revival — an American grotesque with signage heritage, high x-height and flat sides. It carries the brand's own wordmark lineage and is mandated by the Franklyn styleguide for all UI text. Chivo Mono is its monospaced counterpart: grotesque rather than the usual coding-font geometry, so the PIN reads as part of the same family rather than as pasted-in code.

### Hierarchy
- **brand** (800, 22px, 0.04em): the FRANKLYN wordmark in the bar. Tight tracking is deliberate — wide tracking on a heavy caps wordmark reads as a fashion house, which this is not.
- **pin** (Chivo Mono 500, 24px, 1.1): the exam PIN. 17px inside an hour-rail block.
- **title** (500, 18px, 1.35): exam titles and side-block titles.
- **head** (700, 14px, 0.09em, uppercase): the two filled region heads, TODAY and LAST EXAM.
- **body** (400, 14px, 1.5): search field, button label, user chip, hour-rail block titles.
- **meta** (400, 13px): times, dates, figures, calendar days.
- **state** (700, 13px, 0.06em, uppercase): SCHEDULED / LIVE / FINISHED.
- **label** (700, 11px, 0.09em, uppercase): day gutter, scroll sentinels, side-block headings.

### Named Rules

**The Spoken Number Rule.** The PIN is the only monospaced element on the page. It is a code a teacher reads out loud to a room and a student types into a terminal; the fixed advance is what makes the digits scannable. Monospace anywhere else is a costume.

**The Dashboard Density Rule.** The styleguide's 16px body-text floor is written for document copy. UI labels sit below it on purpose — scaling the whole page to 16px reads as a browser zoomed to 120%. Only the state label was ever genuinely undersized for the room it occupies.

## Layout

One centred container capped at **1300px**, shared by the brand bar and the body. Inside it a two-column grid: the timeline column (`minmax(0, 1fr)`) and a fixed **300px** side column, separated by a 32px gap. No breakpoints — the container fills the viewport when narrow and caps when wide, and nothing is ever dropped or reflowed.

The page is **full-viewport and never scrolls**. The app is a flex column at `100vh` with `overflow: hidden`; the timeline is its own scroll container and is the only thing that moves. It opens scrolled so the TODAY region is centred in the visible rect, and re-centres on resize.

The timeline sits in a **150px left gutter**. The axis runs at x=120 as a 2px local-background gradient so it scrolls with the content rather than staying pinned to the viewport; day labels occupy x=0–100 and the nodes are centred on the axis. The TODAY region deliberately bleeds back across the gutter to full main width.

**Spacing** is a 4px scale: 8 / 12 / 16 / 24 / 32. Exams on the same day sit 8px apart; separate days sit 32px apart, and the TODAY region takes the day gap on both sides. Cards are padded 16px vertical / 24px horizontal; side blocks 16px. Geometry locked to the spine gutter (the axis offset, the node position, the calendar dot offsets) stays literal and is exempt from the scale.

## Elevation & Depth

Tonal, with the shadow held at detail strength. Depth comes from the fill steps — `bg` → `surface` → `raise` — and a card lifts on hover by moving one step up that ramp, not by growing a shadow. There is exactly one shadow token and it is a 1px separation, not a halo; it exists so a surface does not merge into the ground, and it is the same value on every surface that gets one.

### Shadow Vocabulary
- **lift** (`box-shadow: 0 1px 2px hsl(222 40% 4% / .24)`): cards, side blocks, the TODAY region, the brand bar. The only shadow in the system.

### Named Rules

**The Whisper Rule.** A detail that becomes prominent stops being a detail. The shadow is 1px with a 2px blur and never grows — not on hover, not on focus, not for emphasis. Elevation is communicated by fill.

## Shapes

One radius token, **6px**, on every container that has corners: cards, the search field, the button, side blocks, the TODAY region, calendar cells, the month-nav buttons. Three deliberate exceptions: the PIN has no container and therefore no radius, the avatar is a full circle, and the now-rule's clock label is rounded on its right edge only, because its left edge runs off the rail.

**No borders.** In this skin no container draws an edge — not a hairline, not a keyline, not a left accent stripe. A line appears only where it beats a fill outright, not where it merely works; the hour scale inside the TODAY rail is one such place, ruled on hairlines in `line`.

### Named Rules

**The No-Line Rule.** Every boundary on this surface is a step in fill. If two regions need separating, one of them changes tone, and a border added to solve a separation problem is the wrong fix. The rule yields only to a higher bar: when a line is so clearly the better drawing that its being out of place still reads better than any fill, take the line. "A fill would also work here" is not that bar. Measured scales are where this keeps happening — an hour grid divides on lines because divisions are what a scale is made of, where tonal banding turns a continuous axis into stacked blocks.

**The Filled Block Rule.** A highlight is a filled block of primary, never an extra line added to something that already has edges. The system uses this device exactly twice — the TODAY region head and the LAST EXAM head — and a third would dilute both.

## Components

### Buttons
- **Shape:** softly squared (6px radius)
- **Primary:** `primary-ink` fill with white label, asymmetric padding (16px left / 24px right) because the icon sits on the left and needs less optical space than the text edge. Icon and label are a flex row with an 8px gap; the Bootstrap Icons glyph is sized at 1.05em off the label's cap height and nudged -1px onto the text's optical centre.
- **Hover / Focus:** fill steps to `primary-hover`, then `primary-press` on active. Focus is a 2px `focus` ring at 2px offset. No transform, no shadow change.
- **Ghost:** the month-nav arrows — 28px square, `raise` fill, no border, glyph at 15px.

### Cards / Containers
- **Corner Style:** 6px
- **Background:** `surface`, stepping to `raise` on hover
- **Shadow Strategy:** the single `lift` shadow; see Elevation
- **Border:** none
- **Internal Padding:** 16px / 24px on exam cards, 16px on side blocks

### Inputs / Fields
- **Style:** `surface` fill, no stroke, 6px radius, 12px vertical / 16px left padding. Matches the primary button's height exactly via a shared control-padding token.
- **Focus:** 2px `focus` ring at 2px offset. The caret is full-brightness `primary`.
- **Placeholder:** `text-3`.

### Navigation
- **Style:** a full-bleed `primary-ink` bar with the single `lift` shadow. The wordmark sits at 22px/800 in white with 0.04em tracking; the user chip is 14px/600 white with a 26px circular avatar.
- The brand's own Firefly (`hsl(195 57% 11%)`) is **not** used here. It sits at the same lightness as the navy ground and disappears into it; Firefly remains the logo and favicon ground, owned by the asset, not by the UI.

### Exam Card (signature)
A four-slot row: PIN, then a title-and-time stack, then the state label hard right. The PIN leads because it is what gets spoken aloud. A finished exam drains — its PIN drops to `text-3` and its state turns green — but the card itself is drawn exactly like every other card. No card ever changes its border, fill or weight to signal state.

### Now-Layer (signature)
A 2px `error` rule across the hour rail at the current minute, with its clock label in `error-deep` carrying white. It rides *over* the page and restyles nothing beneath it: the live exam's block is drawn identically to every other block, and what marks it as live is the rule crossing it.

### Calendar (signature)
Days holding exams carry one 4px dot per exam under the number, in full-brightness `primary`. Multiple dots are offset via box-shadow from a single pseudo-element. The cell itself is never outlined, filled or weighted to indicate exams — only today is filled, in `primary-ink`.

## Do's and Don'ts

### Do:
- **Do** derive every new colour from one of the six core values by overriding lightness: `hsl(from var(--fr-primary) h s 40%)`.
- **Do** separate regions by stepping tone: `bg` → `surface` → `raise`.
- **Do** drop primary to `primary-ink` the moment a teal surface carries text.
- **Do** match light and dark on chroma when a colour's job is to signal, not on contrast ratio.
- **Do** keep the 4px spacing scale (8/12/16/24/32) for anything that is rhythm.
- **Do** use Bootstrap Icons, per the styleguide, sized off the adjacent label's cap height.
- **Do** let geometry locked to the 150px spine gutter stay literal, and comment why.

### Don't:
- **Don't** add a border to any container. Not a hairline, not a keyline, not a coloured left edge. Drawing a line because it is genuinely the better mark is not covered by this; adding one to separate things is.
- **Don't** add a second highlight device. A filled block of primary is the only one, and it is already spent on TODAY and LAST EXAM.
- **Don't** let the now-layer restyle what sits under it.
- **Don't** use monospace for anything but the PIN.
- **Don't** put full-brightness primary under text — it is 2.41:1 against white.
- **Don't** scale UI labels up to the styleguide's 16px document floor; the page reads as browser-zoomed.
- **Don't** grow the shadow for emphasis. It is 1px and stays 1px.
- **Don't** reach for pill radii, soft 8–12px corners, or status badges in chip form.
