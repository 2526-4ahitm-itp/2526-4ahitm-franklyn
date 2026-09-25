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
  - After changing `server/pom.xml`, run `scripts/update-mvn-hash.sh` to write the new hash for your OS
    (Linux or macOS) into `server/default.nix`. The script finds the hash lines by their `# linux` / `# darwin`
    comments, so keep those comments in place.


## Dev-shell variables

- `LIBCLANG_PATH`
  - Exported in the Sentinel dev shell (`sentinel/default.nix`) for Rust tooling that needs libclang.

- `HUGO_GITHUB_PROJECT_URL`
  - Exported in the Hugo dev shell (`hugo/default.nix`).
