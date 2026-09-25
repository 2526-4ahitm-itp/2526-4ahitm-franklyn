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
  - The pinned hashes live in `server/mvn-hash.json`. After changing `server/pom.xml`, run
    `server/scripts/update-mvn-hash.sh` to refresh the entry for your OS. On pull requests that change
    `server/pom.xml`, the `Update Maven Hash` workflow refreshes both the Linux and macOS hashes and commits them.


## Dev-shell variables

- `LIBCLANG_PATH`
  - Exported in the Sentinel dev shell (`sentinel/default.nix`) for Rust tooling that needs libclang.

- `HUGO_GITHUB_PROJECT_URL`
  - Exported in the Hugo dev shell (`hugo/default.nix`).
