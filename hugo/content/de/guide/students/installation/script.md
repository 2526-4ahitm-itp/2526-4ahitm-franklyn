---
title: Anderes Linux (ohne Root)
description: Franklyn Sentinel mit dem Installationsskript installieren
weight: 8
---

{{< badge content="ohne Root" color="red" >}}

> Funktioniert unter jeder Linux-Distribution mit **glibc 2.34+**. Für Bildschirmaufnahme unter Wayland wird zusätzlich PipeWire benötigt.

## 1. Installieren

Installiert in dein Home-Verzeichnis. Kein `sudo` erforderlich.

```shell
curl -fsSL https://franklyn.htl-leonding.ac.at/scripts/sentinel-install.sh | bash
```

Öffne danach ein neues Terminal, damit `franklyn` im `PATH` ist.

## 2. Einer Prüfung beitreten

```shell
franklyn join <pin>
```

## Aktualisieren

```shell
curl -fsSL https://franklyn.htl-leonding.ac.at/scripts/sentinel-install.sh | bash
```

## Deinstallieren

```shell
curl -fsSL https://franklyn.htl-leonding.ac.at/scripts/sentinel-install.sh | bash -s -- --uninstall
```

Das entfernt Franklyn, den Menüeintrag, die Icons und die `PATH`-Zeile in deiner Shell-Konfiguration. Öffne danach ein neues Terminal.
