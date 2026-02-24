---
title: Flake outputs
description: devShells and packages exposed by this repository
weight: 10
---

All outputs are defined by `flake.nix` and the imported modules (`hugo/default.nix`, `sentinel/default.nix`, `proctor/default.nix`, `server/default.nix`).

## devShells

- `devShells.default` (root): aggregates subproject shells via `inputsFrom` in `flake.nix`
- `devShells.server`: `server/default.nix`
- `devShells.sentinel`: `sentinel/default.nix`
- `devShells.proctor`: `proctor/default.nix`
- `devShells.hugo`: `hugo/default.nix`

## packages

- `packages.franklyn-server`: `server/default.nix`
- `packages.franklyn-sentinel`: `sentinel/default.nix`
- `packages.franklyn-sentinel-deb`: `sentinel/default.nix`
