---
title: Flake-Outputs
description: devShells und Pakete, die von diesem Repository bereitgestellt werden
weight: 10
---

Alle Outputs werden durch `flake.nix` und die importierten Module (`hugo/default.nix`, `sentinel/default.nix`, `proctor/default.nix`, `server/default.nix`) definiert.

## devShells

- `devShells.default` (root): fasst Teilprojekt-Shells via `inputsFrom` in `flake.nix` zusammen
- `devShells.server`: `server/default.nix`
- `devShells.sentinel`: `sentinel/default.nix`
- `devShells.proctor`: `proctor/default.nix`
- `devShells.hugo`: `hugo/default.nix`

## packages

- `packages.franklyn-server`: `server/default.nix`
- `packages.franklyn-sentinel`: `sentinel/default.nix`
- `packages.franklyn-sentinel-deb`: `sentinel/default.nix`
