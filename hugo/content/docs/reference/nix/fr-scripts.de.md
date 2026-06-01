---
title: fr-Skripte
description: Stabile Befehls-Einstiegspunkte für CI und Dev-Shells
weight: 20
---

Die `fr-`-Skripte sind bewusst das „öffentliche" Interface zum Ausführen von Checks und Builds auf konsistente Weise.

## Server

- `fr-server-build-clean` (definiert in `server/default.nix`): führt `mvn clean package` aus
- `fr-server-pr-check` (definiert in `server/default.nix`): führt `mvn clean verify` mit projektspezifischen Flags aus

## Sentinel

- `fr-sentinel-pr-check` (definiert in `sentinel/default.nix`): führt `cargo fmt`, `cargo clippy` und Coverage aus
- `fr-sentinel-build` (definiert in `sentinel/default.nix`): führt `cargo build --release` aus
- `fr-sentinel-coverage` (definiert in `sentinel/default.nix`): führt `cargo tarpaulin ...` aus

## Proctor

- `fr-proctor-pr-check` (definiert in `proctor/default.nix`): Dependencies installieren, Type-Check, Lint, Build
- `fr-proctor-build` (definiert in `proctor/default.nix`): Dependencies installieren, Build mit übergebenen Argumenten

## Hugo

- `fr-hugo-build` (definiert in `hugo/default.nix`): führt `hugo --gc --minify` mit übergebenen Argumenten aus
