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

## Aktualisieren und deinstallieren

Führe den Installer erneut aus, um zu **aktualisieren**. Zum **Deinstallieren**:

```shell
curl -fsSL https://franklyn.htl-leonding.ac.at/scripts/sentinel-install.sh | bash -s -- --uninstall
```

<details>
<summary>Manueller Download</summary>

{{< callout type="warning" >}}
Verwende bevorzugt den Installer oben. macOS verweigert den Start dieses Builds, wenn er mit einem Webbrowser heruntergeladen wurde, bis du die Download-Markierung wie unten gezeigt entfernst.
{{< /callout >}}

Lade `franklyn-sentinel-[VERSION]-aarch64-darwin-portable.tar.gz` von unseren [Releases](https://github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/releases) herunter, entpacke es außerhalb von `Downloads` und entferne die Download-Markierung des Browsers:

```shell
cd ~
mkdir franklyn-sentinel
tar -xzf ~/Downloads/franklyn-sentinel-*-aarch64-darwin-portable.tar.gz -C franklyn-sentinel
xattr -dr com.apple.quarantine franklyn-sentinel
./franklyn-sentinel/bin/franklyn join <pin>
```

</details>
