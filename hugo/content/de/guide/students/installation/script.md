---
title: Anderes Linux
description: Franklyn Sentinel mit dem Installationsskript installieren
weight: 8
---

> Verwende das unter Fedora Kinoite, Bazzite, AlmaLinux, Rocky Linux, CachyOS, Gentoo und jeder anderen Distribution mit **glibc 2.34+**. Für Bildschirmaufnahme unter Wayland wird zusätzlich PipeWire benötigt.

## 1. Installieren

{{< callout type="warning" >}}
**AlmaLinux / Rocky Linux:** Installiere zuerst `zstd`, der Installer braucht es zum Entpacken von Franklyn:

```shell
sudo dnf install zstd
```
{{< /callout >}}

Installiert in dein Home-Verzeichnis. Kein `sudo` erforderlich.

```shell
curl -fsSL https://franklyn.htl-leonding.ac.at/scripts/sentinel-install.sh | bash
```

Öffne danach ein neues Terminal, damit `franklyn` im `PATH` ist.

## 2. Einer Prüfung beitreten

```shell
franklyn join <pin>
```

## Aktualisieren und deinstallieren

Führe denselben Befehl erneut aus, um zu **aktualisieren**. Zum **Deinstallieren**:

```shell
curl -fsSL https://franklyn.htl-leonding.ac.at/scripts/sentinel-install.sh | bash -s -- --uninstall
```

<details>
<summary>Manueller Download (Portable)</summary>

Lade das Portable-Paket für deine Architektur von unseren [Releases](https://github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/releases) herunter. Es enthält alle Laufzeitbibliotheken, nur glibc wird benötigt.

```shell
tar --zstd -xf franklyn-sentinel-[VERSION]-[ARCH]-portable.tar.zst
cd franklyn-sentinel-[VERSION]-[ARCH]-portable
./bin/franklyn join <pin>
```

</details>
