---
title: Arch Linux
description: Franklyn Sentinel unter Arch Linux, EndeavourOS, Manjaro und Omarchy installieren
weight: 5
---

> Funktioniert unter Arch Linux, EndeavourOS, Manjaro und Omarchy. Unter CachyOS verwende stattdessen das [Installationsskript](../script/).

## 1. Installieren

Franklyn Sentinel ist im [AUR](https://aur.archlinux.org/packages/franklyn-bin). Installiere es mit `yay`.

{{< callout type="warning" >}}
**Manjaro:** Führe zuerst `sudo pacman -S --needed base-devel` aus.
{{< /callout >}}

```shell
yay -S franklyn-bin
```

## 2. Einer Prüfung beitreten

```shell
franklyn join <pin>
```

## Aktualisieren und deinstallieren

Updates kommen mit deinen normalen Systemupdates (`yay -Syu`). Zum Deinstallieren:

```shell
yay -Rns franklyn-bin
```
