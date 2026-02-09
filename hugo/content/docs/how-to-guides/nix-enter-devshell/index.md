---
title: Enter a Nix dev shell
description: Get the project toolchain and fr- scripts via nix develop
weight: 10
---

This project defines dev shells so you can work with the same toolchain as CI.

## Prerequisites

- Install Nix (official instructions): https://nixos.org/download/
- If your Nix complains about flakes being disabled, follow the Nix manual section on enabling flakes:
  https://nixos.org/manual/nix/stable/

## Enter the default dev shell

From the repository root:

```sh
nix develop
```

This combines the subproject shells (see `flake.nix`) and is useful if you switch between components.

## Enter a subproject dev shell

Pick one of the shells exposed by the flake:

```sh
nix develop .#server
nix develop .#sentinel
nix develop .#proctor
nix develop .#hugo
```

Once inside, the `fr-` scripts for that subproject are on your `PATH`.

## Optional: direnv integration

This repository contains `.envrc` with `use flake`. If you use direnv, it can automatically load the flake dev shell when you enter the directory.

- direnv documentation: https://direnv.net/
