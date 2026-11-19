---
title: macOS
description: Franklyn Sentinel unter macOS installieren
weight: 2
---

> **Benötigt einen Mac mit Apple Silicon (M1 oder neuer) und macOS 14 (Sonoma) oder neuer.** Intel-Macs werden nicht unterstützt.

## 1. Installieren

Öffne das **Terminal** und führe den Installer aus. Er installiert in dein Home-Verzeichnis, kein `sudo` erforderlich:

```shell
curl -fsSL https://franklyn.htl-leonding.ac.at/scripts/sentinel-install.sh | bash
```

Öffne danach ein neues Terminalfenster, damit `franklyn` im `PATH` ist.

## 2. Einer Prüfung beitreten

```shell
franklyn join <pin>
```

Beim ersten Mal fragt macOS, ob deine Terminal-App den Bildschirm aufnehmen darf:

1. Klicke auf **Systemeinstellungen öffnen** und aktiviere deine Terminal-App (z. B. **Terminal**) unter **Datenschutz & Sicherheit → Bildschirm- & Systemaudioaufnahme**.
2. Lass macOS das Terminal **beenden und erneut öffnen**.
3. Führe `franklyn join <pin>` erneut aus.

Die Berechtigung gehört der Terminal-App, du erteilst sie also nur einmal — Updates behalten sie. Eine andere Terminal-App (z. B. iTerm) braucht eine eigene Berechtigung.

## Aktualisieren

```shell
curl -fsSL https://franklyn.htl-leonding.ac.at/scripts/sentinel-install.sh | bash
```

## Deinstallieren

```shell
curl -fsSL https://franklyn.htl-leonding.ac.at/scripts/sentinel-install.sh | bash -s -- --uninstall
```

Wenn du die Berechtigung zur Bildschirmaufnahme nicht mehr brauchst, deaktiviere deine Terminal-App wieder unter **Systemeinstellungen → Datenschutz & Sicherheit → Bildschirm- & Systemaudioaufnahme**.
