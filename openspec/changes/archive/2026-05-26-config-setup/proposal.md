## Why

`openspec/config.yaml` has no project context, so every AI-generated artifact receives no domain knowledge — wrong tech stack assumptions, wrong terminology, wrong role names. Setting this up once improves quality across all future spec and change artifacts.

## What Changes

- `openspec/config.yaml` updated with full project context: tech stack, domain vocabulary, roles, per-artifact rules

## Capabilities

### New Capabilities

_None — this is tooling configuration, not a product capability._

### Modified Capabilities

_None._

## Impact

- `openspec/config.yaml` only
- All future `openspec` artifact generation benefits from project context
