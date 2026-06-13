---
title: fr- scripts
description: Stable command entrypoints used in CI and dev shells
weight: 20
---

The `fr-` scripts are intentionally the "public" interface for running checks and builds in a consistent way.

## Server

- `fr-server-build-clean` (defined in `server/default.nix`): runs `mvn clean package`
- `fr-server-pr-check` (defined in `server/default.nix`): runs `mvn clean verify` with project-specific flags

## Sentinel

- `fr-sentinel-pr-check` (defined in `sentinel/default.nix`): runs `cargo fmt`, `cargo clippy`, and coverage
- `fr-sentinel-build` (defined in `sentinel/default.nix`): runs `cargo build --release`
- `fr-sentinel-coverage` (defined in `sentinel/default.nix`): runs `cargo tarpaulin ...`

## Proctor

- `fr-proctor-pr-check` (defined in `proctor/default.nix`): install deps, type-check, lint, build
- `fr-proctor-build` (defined in `proctor/default.nix`): install deps, build with passed args

## Hugo

- `fr-hugo-build` (defined in `hugo/default.nix`): runs `hugo --gc --minify` with passed args
