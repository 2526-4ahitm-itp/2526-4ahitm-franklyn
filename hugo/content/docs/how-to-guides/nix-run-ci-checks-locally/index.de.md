---
title: CI-Checks lokal ausführen (via Nix)
description: Dieselben fr-Skripte wie CI innerhalb von nix develop verwenden
weight: 20
---

CI führt Projekt-Checks via `fr-`-Skripte innerhalb der entsprechenden Nix-Dev-Shell aus. Du kannst exakt dieselben Befehle lokal ausführen.

## Proctor

```sh
cd proctor
nix develop .#proctor --command fr-proctor-pr-check
```

Definiert in `proctor/default.nix` und aufgerufen von `.github/workflows/pr-checks.yaml`.

## Server

```sh
cd server
nix develop .#server --command fr-server-pr-check
```

Definiert in `server/default.nix` und aufgerufen von `.github/workflows/pr-checks.yaml`.

## Sentinel

```sh
cd sentinel
nix develop .#sentinel --command fr-sentinel-pr-check
```

Definiert in `sentinel/default.nix` und aufgerufen von `.github/workflows/pr-checks.yaml`.

## Hugo (Docs)

```sh
cd hugo
nix develop .#hugo --command fr-hugo-build
```

Definiert in `hugo/default.nix` und aufgerufen von `.github/workflows/hugo-deploy.yaml`.
