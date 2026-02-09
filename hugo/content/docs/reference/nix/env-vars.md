---
title: Environment variables
description: Environment variables used by the Nix setup
weight: 30
---

This page lists environment variables referenced by the Nix configuration.

## Build-time variables

- `FRANKLYN_USE_FAKE_MVN_HASH`
  - Used in `server/default.nix`
  - If set (non-empty), the Maven derivation uses `pkgs.lib.fakeHash` to avoid pinning the real hash.

- `CONTAINER_REGISTRY`
  - Used in `flake.nix` by `packages.manifests`
  - Read via `builtins.getEnv` when building with `nix build .#manifests --impure`.

- `CONTAINER_LOCATION`
  - Used in `flake.nix` by `packages.manifests`
  - Read via `builtins.getEnv` when building with `nix build .#manifests --impure`.

## Dev-shell variables

- `LIBCLANG_PATH`
  - Exported in the Sentinel dev shell (`sentinel/default.nix`) for Rust tooling that needs libclang.

- `HUGO_GITHUB_PROJECT_URL`
  - Exported in the Hugo dev shell (`hugo/default.nix`).
