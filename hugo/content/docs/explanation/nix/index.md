---
title: Nix in Franklyn
description: Why we use Nix, how it is structured, and where to find things
weight: 10
---

Franklyn uses Nix to make developer environments and CI runs predictable across machines.

The short version:

- We define `fr-` scripts that are used in CI and when working inside `nix develop`.
- Build dependencies live in Nix dev shells (so CI and local development use the same toolchain).
- Some parts also ship Nix derivations that build real artifacts (not just a dev environment).
- The flake is structured with `flake-parts` to keep each subproject's Nix logic modular.

## Why we use Nix here

Franklyn spans multiple toolchains (Maven/Java, Rust, Bun/Node, Hugo/Go). Without a shared environment definition you typically get:

- "works on my machine" differences (tool versions, system libraries, missing CLI tools)
- CI behaving differently from local runs
- onboarding friction for a new team

Nix addresses this by describing environments and build inputs declaratively. Developers enter the same environment CI uses, and the project controls the tool versions.

## How we use Nix (the pattern)

There are two main layers:

1) Dev shells (`nix develop`)

- Provide all build dependencies for a given subproject.
- Provide the `fr-` scripts (the stable entrypoints).

2) Packages / derivations (`nix build`)

- Build artifacts in a reproducible way (for releases and CI verification in some cases).

The key idea is: use the same command entrypoints locally and in CI.

## Where to find the Nix code

- Root flake: `flake.nix`
- Subproject Nix modules:
  - Hugo: `hugo/default.nix`
  - Sentinel: `sentinel/default.nix`
  - Proctor: `proctor/default.nix`
  - Server: `server/default.nix`

CI references:

- PR checks: `.github/workflows/pr-checks.yaml`
- Release builds: `.github/workflows/release.yaml`
- Docs build/deploy: `.github/workflows/hugo-deploy.yaml`
- Nix + caches setup action: `.github/actions/setup-nix/action.yaml`

## flake-parts in this repository

`flake.nix` uses `flake-parts.lib.mkFlake` and imports the subproject modules (`./hugo`, `./sentinel`, `./proctor`, `./server`).

What this does for us:

- Keeps Nix definitions close to each subproject.
- Uses `perSystem = { ... }` so outputs are produced for each supported platform.
- Provides shared arguments (for example `project-version`, `package-meta`, a `pkgs` with overlays, and `mkEnvHook`).

If you are new to flakes and `perSystem`, this is the minimal mental model:

- A flake exposes "outputs" (dev shells, packages, etc.).
- `perSystem` means those outputs are computed for each `system` (for example `x86_64-linux`).

Official docs:

- Nix manual (flakes, commands): https://nixos.org/manual/nix/stable/
- flake-parts: https://flake.parts/

## Dev shells and `fr-` scripts

Each subproject defines a dev shell (for example `devShells.server`, `devShells.sentinel`, ...). Inside the shell definition we include:

- the toolchain packages needed for that subproject
- the `fr-` scripts created via `pkgs.writeScriptBin`

Examples in this repo:

- Server scripts in `server/default.nix`: `fr-server-build-clean`, `fr-server-pr-check`
- Sentinel scripts in `sentinel/default.nix`: `fr-sentinel-pr-check`, `fr-sentinel-build`, `fr-sentinel-coverage`
- Proctor scripts in `proctor/default.nix`: `fr-proctor-pr-check`, `fr-proctor-build`
- Hugo scripts in `hugo/default.nix`: `fr-hugo-build`

Why scripts instead of "just run mvn/cargo/bun"?

- CI can call one stable command per project.
- Local developers run the exact same checks.
- The scripts document the intended workflow in one place.

## Derivations (packages) we build

Some components also define Nix packages (derivations) that build artifacts:

- Server: `packages.franklyn-server` in `server/default.nix` (builds a runnable JAR)
- Sentinel: `packages.franklyn-sentinel` and `packages.franklyn-sentinel-deb` in `sentinel/default.nix` (binary + Debian package)
- Manifests: `packages.manifests` in `flake.nix` (processes Kubernetes YAML and can read env vars when built with `--impure`)

These are used in CI (`nix build .#...`) and are useful for release automation because they produce well-defined outputs.

## How CI uses Nix

In GitHub Actions we:

- install Nix
- enable caching (Cachix) to speed up builds
- enter the relevant dev shell and run the `fr-` script
- sometimes also build the derivation to ensure the package builds (`nix build .#...`)

See `.github/actions/setup-nix/action.yaml` and the workflows listed earlier.

## New to Nix: a few basics (and where to read more)

What is `nix develop`?

- It drops you into a shell environment defined by the project.
- The environment contains the tools and scripts we want you to use.

What is `nix build`?

- It builds a specific package output from the flake.
- You typically use it when you want an artifact (a binary, a JAR, a .deb, generated files).

What does `.#server` or `.#franklyn-server` mean?

- `.` means "this flake" (the current repository).
- `#name` selects one output (a dev shell, package, etc.) by name.

If you want to go deeper:

- Nix manual: https://nixos.org/manual/nix/stable/
- nixpkgs manual (packaging concepts): https://nixos.org/manual/nixpkgs/stable/
