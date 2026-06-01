---
title: Nix-Dev-Shell betreten
description: Projekt-Toolchain und fr-Skripte via nix develop erhalten
weight: 10
---

Dieses Projekt definiert Dev-Shells, sodass du mit derselben Toolchain wie CI arbeiten kannst.

## Voraussetzungen

- Nix installieren (offizielle Anleitung): https://nixos.org/download/
- Falls Nix über deaktivierte Flakes klagt, folge dem entsprechenden Abschnitt im Nix-Handbuch zum Aktivieren von Flakes:
  https://nixos.org/manual/nix/stable/

## Standard-Dev-Shell betreten

Vom Repository-Stammverzeichnis aus:

```sh
nix develop
```

Dies kombiniert die Teilprojekt-Shells (siehe `flake.nix`) und ist nützlich, wenn du zwischen Komponenten wechselst.

## Teilprojekt-Dev-Shell betreten

Eine der vom Flake bereitgestellten Shells auswählen:

```sh
nix develop .#server
nix develop .#sentinel
nix develop .#proctor
nix develop .#hugo
```

Sobald du drin bist, sind die `fr-`-Skripte für das jeweilige Teilprojekt im `PATH` verfügbar.

## Optional: direnv-Integration

Dieses Repository enthält `.envrc` mit `use flake`. Mit direnv kann die Flake-Dev-Shell automatisch geladen werden, wenn du das Verzeichnis betrittst.

- direnv-Dokumentation: https://direnv.net/
