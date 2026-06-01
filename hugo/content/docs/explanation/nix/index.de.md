---
title: Nix in Franklyn
description: Warum wir Nix verwenden, wie es strukturiert ist und wo man Dinge findet
weight: 10
---

Franklyn verwendet Nix, um Entwicklungsumgebungen und CI-Läufe maschinenübergreifend vorhersehbar zu machen.

Kurz zusammengefasst:

- Wir definieren `fr-`-Skripte, die in CI und beim Arbeiten innerhalb von `nix develop` verwendet werden.
- Build-Abhängigkeiten befinden sich in Nix-Dev-Shells (sodass CI und lokale Entwicklung dieselbe Toolchain verwenden).
- Einige Teile liefern auch Nix-Derivationen, die echte Artefakte bauen (nicht nur eine Entwicklungsumgebung).
- Das Flake ist mit `flake-parts` strukturiert, um die Nix-Logik jedes Teilprojekts modular zu halten.

## Warum wir Nix verwenden

Franklyn umfasst mehrere Toolchains (Maven/Java, Rust, Bun/Node, Hugo/Go). Ohne eine gemeinsame Umgebungsdefinition entstehen typischerweise:

- „Works on my machine"-Unterschiede (Tool-Versionen, Systembibliotheken, fehlende CLI-Tools)
- Abweichendes Verhalten zwischen CI und lokalen Läufen
- Einarbeitungsprobleme für neue Teammitglieder

Nix löst dies, indem Umgebungen und Build-Eingaben deklarativ beschrieben werden. Entwickler betreten dieselbe Umgebung wie CI, und das Projekt kontrolliert die Tool-Versionen.

## Wie wir Nix verwenden (das Muster)

Es gibt zwei Hauptschichten:

1) Dev-Shells (`nix develop`)

- Stellen alle Build-Abhängigkeiten für ein bestimmtes Teilprojekt bereit.
- Stellen die `fr-`-Skripte (die stabilen Einstiegspunkte) bereit.

2) Pakete / Derivationen (`nix build`)

- Bauen Artefakte auf reproduzierbare Weise (für Releases und CI-Verifizierung in einigen Fällen).

Der Kerngedanke ist: lokal und in CI dieselben Befehls-Einstiegspunkte verwenden.

## Wo sich der Nix-Code befindet

- Root-Flake: `flake.nix`
- Nix-Module der Teilprojekte:
  - Hugo: `hugo/default.nix`
  - Sentinel: `sentinel/default.nix`
  - Proctor: `proctor/default.nix`
  - Server: `server/default.nix`

CI-Referenzen:

- PR-Checks: `.github/workflows/pr-checks.yaml`
- Release-Builds: `.github/workflows/release.yaml`
- Docs-Build/Deploy: `.github/workflows/hugo-deploy.yaml`
- Nix + Caches Setup Action: `.github/actions/setup-nix/action.yaml`

## flake-parts in diesem Repository

`flake.nix` verwendet `flake-parts.lib.mkFlake` und importiert die Teilprojekt-Module (`./hugo`, `./sentinel`, `./proctor`, `./server`).

Was das für uns bewirkt:

- Hält Nix-Definitionen nah am jeweiligen Teilprojekt.
- Verwendet `perSystem = { ... }`, sodass Outputs für jede unterstützte Plattform erzeugt werden.
- Stellt gemeinsame Argumente bereit (z. B. `project-version`, `package-meta`, ein `pkgs` mit Overlays und `mkEnvHook`).

Falls du neu bei Flakes und `perSystem` bist, hier das minimale Gedankenmodell:

- Ein Flake exponiert „Outputs" (Dev-Shells, Pakete usw.).
- `perSystem` bedeutet, dass diese Outputs für jedes `system` berechnet werden (z. B. `x86_64-linux`).

Offizielle Dokumentation:

- Nix-Handbuch (Flakes, Befehle): https://nixos.org/manual/nix/stable/
- flake-parts: https://flake.parts/

## Dev-Shells und `fr-`-Skripte

Jedes Teilprojekt definiert eine Dev-Shell (z. B. `devShells.server`, `devShells.sentinel`, ...). In der Shell-Definition sind enthalten:

- die benötigten Toolchain-Pakete für das jeweilige Teilprojekt
- die `fr-`-Skripte, die via `pkgs.writeScriptBin` erstellt werden

Beispiele in diesem Repository:

- Server-Skripte in `server/default.nix`: `fr-server-build-clean`, `fr-server-pr-check`
- Sentinel-Skripte in `sentinel/default.nix`: `fr-sentinel-pr-check`, `fr-sentinel-build`, `fr-sentinel-coverage`
- Proctor-Skripte in `proctor/default.nix`: `fr-proctor-pr-check`, `fr-proctor-build`
- Hugo-Skripte in `hugo/default.nix`: `fr-hugo-build`

Warum Skripte statt „einfach mvn/cargo/bun ausführen"?

- CI kann für jedes Projekt einen stabilen Befehl aufrufen.
- Lokale Entwickler führen exakt dieselben Checks durch.
- Die Skripte dokumentieren den beabsichtigten Workflow an einem Ort.

## Derivationen (Pakete), die wir bauen

Einige Komponenten definieren auch Nix-Pakete (Derivationen), die Artefakte bauen:

- Server: `packages.franklyn-server` in `server/default.nix` (baut ein lauffähiges JAR)
- Sentinel: `packages.franklyn-sentinel` und `packages.franklyn-sentinel-deb` in `sentinel/default.nix` (Binary + Debian-Paket)

Diese werden in CI (`nix build .#...`) verwendet und sind nützlich für die Release-Automatisierung, da sie wohldefinierte Outputs erzeugen.

## Wie CI Nix verwendet

In GitHub Actions:

- Nix installieren
- Caching aktivieren (Cachix) um Builds zu beschleunigen
- In die relevante Dev-Shell eintreten und das `fr-`-Skript ausführen
- Manchmal auch die Derivation bauen, um sicherzustellen, dass das Paket gebaut werden kann (`nix build .#...`)

Siehe `.github/actions/setup-nix/action.yaml` und die zuvor aufgelisteten Workflows.

## Neu bei Nix: Grundlagen (und weiterführende Literatur)

Was ist `nix develop`?

- Es versetzt dich in eine Shell-Umgebung, die vom Projekt definiert wird.
- Die Umgebung enthält die Tools und Skripte, die wir dir empfehlen zu verwenden.

Was ist `nix build`?

- Es baut einen bestimmten Paket-Output aus dem Flake.
- Du verwendest es typischerweise, wenn du ein Artefakt möchtest (ein Binary, ein JAR, eine .deb, generierte Dateien).

Was bedeutet `.#server` oder `.#franklyn-server`?

- `.` bedeutet „dieses Flake" (das aktuelle Repository).
- `#name` wählt einen Output (eine Dev-Shell, ein Paket usw.) nach Namen aus.

Für mehr Details:

- Nix-Handbuch: https://nixos.org/manual/nix/stable/
- nixpkgs-Handbuch (Packaging-Konzepte): https://nixos.org/manual/nixpkgs/stable/
