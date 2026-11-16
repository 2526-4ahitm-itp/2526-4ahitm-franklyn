---
title: Anderes Linux (ohne Root)
description: Franklyn Sentinel mit dem Installationsskript installieren
weight: 8
---

{{< badge content="ohne Root" color="red" >}}

> Funktioniert unter jeder Linux-Distribution mit **glibc 2.34+**. Für Bildschirmaufnahme unter Wayland wird zusätzlich PipeWire benötigt.

## 1. Installieren

{{< callout type="warning" >}}
Der Installer braucht `zstd` zum Entpacken von Franklyn. Installiere es zuerst, falls es fehlt.
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

## Aktualisieren

```shell
curl -fsSL https://franklyn.htl-leonding.ac.at/scripts/sentinel-install.sh | bash
```

## Deinstallieren

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
