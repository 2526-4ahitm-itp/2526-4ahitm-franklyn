---
title: Run the CI checks locally (via Nix)
description: Use the same fr- scripts as CI by running them inside nix develop
weight: 20
---

CI runs project checks via `fr-` scripts inside the corresponding Nix dev shell. You can run the exact same commands locally.

## Proctor

```sh
cd proctor
nix develop .#proctor --command fr-proctor-pr-check
```

Defined in `proctor/default.nix` and invoked by `.github/workflows/pr-checks.yaml`.

## Server

```sh
cd server
nix develop .#server --command fr-server-pr-check
```

Defined in `server/default.nix` and invoked by `.github/workflows/pr-checks.yaml`.

## Sentinel

```sh
cd sentinel
nix develop .#sentinel --command fr-sentinel-pr-check
```

Defined in `sentinel/default.nix` and invoked by `.github/workflows/pr-checks.yaml`.

## Hugo (docs)

```sh
cd hugo
nix develop .#hugo --command fr-hugo-build
```

Defined in `hugo/default.nix` and invoked by `.github/workflows/hugo-deploy.yaml`.
