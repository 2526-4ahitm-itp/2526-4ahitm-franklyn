# Design Taste Reference

Read alongside `design-context.md` and `feedback-log.md`.

This file is not a licence to decorate. It is a restraint contract. The owner reviews output by
looking at it and then deleting what they did not ask for, so every unrequested detail costs them a
round. Optimise for a short review, not for a finished-looking page.

---

## The one rule

**No visual property without a named job.**

Before any colour, weight, opacity, border, shadow, radius, tint, size step or motion: name the job
in one short line — what it tells the user that nothing else on screen already tells them. No line,
no property.

Banned specifically because it keeps happening:

- Drawing the same kind of element two different ways by state. If an exam is over, its state label
  says so. The PIN does not also drain, the row does not also tint, the bar does not also shade.
- Two devices for one meaning. One signal, one place.
- Anything the owner would have to ask "where does that come from?" about.

When a property is unspecified, **inherit it**. Same is the default. Different is what needs an
argument.

## Declare every choice

Anything decided that the brief did not name goes in the chat reply as a flat list, max 5 lines,
each `element — what — why`. If a choice needs more than one line to defend, drop it instead of
explaining it.

The owner reads layouts, not CSS. A choice that exists only in the stylesheet is a choice they
cannot review, which makes it a defect however good it looks.

## Creation vs refinement

Two different jobs. Never mix them.

**Creation** (new layout, nothing to preserve) — invention is required, so invent *structure only*:
what is on screen, in what order, what groups with what, what gets the most room. Arrangement is
the deliverable. Finish is not: no detail layer, no accents, no state styling, no motion. A layout
study with zero decoration is correct and finished.

**Refinement / design step** (a layout exists) — the layout is frozen and wins every tie. Apply the
system already specified in `design-context.md`. Do not reorder, do not merge, do not add an
element, a state, or a visual device nobody asked for. Zero new ideas. If the layout looks wrong,
say so in one line and leave it alone.

## Propose, then stop

The owner takes ideas over and refines them in chat. So:

- Few big reversible moves beat many small ones. Three ideas they can react to beat thirty touches
  they have to audit.
- Output is a proposal, not a finish. Stop early and ask.
- Under-designed is one cheap round. Over-designed costs a stripping round every time.
- This is an iterative, specific process, not vibing. Never guess a direction and build it out —
  ask the one question instead.

## Craft floor

Mechanics, not taste. Do these silently; they never pick a direction.

- Text contrast ≥4.5:1 body, ≥3:1 large text.
- Every interactive element has hover, active, focus-visible, disabled. Focus rings never removed.
- One spacing scale (4px base: 4/8/12/16/24/32/48), one type scale, consistent across the page.
- Realistic placeholder content and realistic quantities. Never lorem ipsum.
- An empty state wherever a list can be empty.
- Respect `prefers-reduced-motion`.

## Anti-patterns

Hard no. No brief earns these back.

- Rounded corners, pill shapes and hairline borders as a default look.
- Gradients, glass, blur or glow as decoration.
- Icon + heading + text cards as page structure. Nested cards.
- Kicker or eyebrow labels above headings.
- Centred hero with giant padding.
- Inter + purple-on-white, or any other generic AI-SaaS dashboard tell.
- Emoji or unicode glyphs standing in for an icon system.
- Low-contrast pastel text.
- State communicated by changing a container's border, fill or weight.

## Check before output

1. **Strip test** — would the owner delete this? Then it is already deleted.
2. **Name test** — can every non-default property be named in one line? If not, remove it.
3. **Same test** — are two elements of the same kind drawn differently? Unify, or justify in writing.
4. **Review test** — is every choice visible in the render and listed in the reply?

## Key principle

The owner is the designer. This output exists to inspire and to be taken over, so it carries exactly
what was asked for and nothing else. Restraint is the deliverable; finish is theirs to request.
