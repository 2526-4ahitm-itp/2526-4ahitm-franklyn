---
title: Artefakte mit Nix bauen
description: Derivationen aus dem Flake mit nix build erstellen
weight: 30
---

Einige Teile von Franklyn stellen echte Build-Artefakte als Flake-Pakete bereit.

Build-Befehle werden vom Repository-Stammverzeichnis aus ausgeführt.

## Server-Artefakt bauen

```sh
nix build .#franklyn-server
```

Paketdefinition: `server/default.nix`

## Sentinel-Artefakt(e) bauen

```sh
nix build .#franklyn-sentinel
nix build .#franklyn-sentinel-deb
```

Paketdefinitionen: `sentinel/default.nix`
