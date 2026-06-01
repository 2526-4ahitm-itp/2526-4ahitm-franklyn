---
title: Umgebungsvariablen
description: Umgebungsvariablen, die von der Nix-Konfiguration verwendet werden
weight: 30
---

Diese Seite listet Umgebungsvariablen auf, die von der Nix-Konfiguration referenziert werden.

## Build-Zeit-Variablen

- `FRANKLYN_USE_FAKE_MVN_HASH`
  - Verwendet in `server/default.nix`
  - Falls gesetzt (nicht leer), verwendet die Maven-Derivation `pkgs.lib.fakeHash`, um das Pinnen des echten Hashes zu vermeiden.


## Dev-Shell-Variablen

- `LIBCLANG_PATH`
  - In der Sentinel-Dev-Shell exportiert (`sentinel/default.nix`) für Rust-Tooling, das libclang benötigt.

- `HUGO_GITHUB_PROJECT_URL`
  - In der Hugo-Dev-Shell exportiert (`hugo/default.nix`).
