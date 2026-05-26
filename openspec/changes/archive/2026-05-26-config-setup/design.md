## Context

`openspec/config.yaml` exists with `schema: spec-driven` but no `context` or `rules` fields. All AI artifact generation runs without domain knowledge of the franklyn project.

## Goals / Non-Goals

**Goals:**
- Add `context` block with tech stack, domain vocabulary, and role definitions
- Add `rules` block with per-artifact constraints for proposal, specs, and tasks

**Non-Goals:**
- Changing the schema (`spec-driven` stays)
- Modifying any application code

## Decisions

**Single context block over per-artifact context**: The tech stack and domain terms are relevant to all artifact types. Per-artifact rules handle the differences.

**German UI / English code noted explicitly**: Prevents AI from generating German identifiers or English UI strings in specs and tasks.

**Implementation status field mandated in specs rules**: Every spec requirement should note `implemented / partial / not-implemented` so gap analysis is built into each spec automatically.

**`[GAP]` label convention for tasks**: Distinguishes FSD requirements not yet implemented from spec-writing tasks (`[SPEC]`). Makes the backlog immediately actionable.

## Risks / Trade-offs

- [Context drift] Config becomes stale as codebase evolves → Mitigation: revisit config when adding new major subsystems
- [Verbosity] Too much context inflates every artifact prompt → Mitigation: keep context under 30 lines, no per-file lists
