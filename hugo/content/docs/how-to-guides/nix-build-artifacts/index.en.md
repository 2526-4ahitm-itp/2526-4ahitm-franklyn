---
title: Build artifacts with Nix
description: Build derivations from the flake with nix build
weight: 30
---

Some parts of Franklyn expose real build artifacts as flake packages.

Build commands are run from the repository root.

## Build the server artifact

```sh
nix build .#franklyn-server
```

Package definition: `server/default.nix`

## Build the sentinel artifact(s)

```sh
nix build .#franklyn-sentinel
nix build .#franklyn-sentinel-deb
```

Package definitions: `sentinel/default.nix`
