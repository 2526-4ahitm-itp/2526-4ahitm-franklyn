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

## Build generated Kubernetes manifests

```sh
nix build .#manifests
```

If you want Nix to read external environment variables during the build (see the comments in `flake.nix`), build with `--impure`:

```sh
CONTAINER_REGISTRY=ghcr.io CONTAINER_LOCATION=example-org nix build .#manifests --impure
```

Package definition: `flake.nix`
