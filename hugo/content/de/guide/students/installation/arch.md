---
title: Arch Linux
description: Franklyn Sentinel unter Arch Linux, EndeavourOS, Manjaro und Omarchy installieren
weight: 5
---

> Funktioniert unter Arch Linux, EndeavourOS, Manjaro und Omarchy. Unter CachyOS verwende stattdessen das [Installationsskript](../script/).

## 1. AUR-Helfer installieren

Franklyn Sentinel ist im [AUR](https://aur.archlinux.org/packages/franklyn-bin), daher brauchst du einen AUR-Helfer wie `yay` oder `paru`. Überspringe diesen Schritt, wenn du schon einen hast. So installierst du `yay`:

```shell
sudo pacman -S --needed git base-devel
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -si
```

## 2. Installieren

{{< callout type="warning" >}}
**Manjaro:** Installiere zuerst `base-devel`, auch wenn du schon einen AUR-Helfer hast. Manjaro bringt es nicht mit, und ohne es lassen sich AUR-Pakete nicht bauen:

```shell
sudo pacman -S --needed base-devel
```
{{< /callout >}}

```shell
yay -S franklyn-bin
```

Mit `paru` verwendest du `paru -S franklyn-bin`.

## 3. Einer Prüfung beitreten

```shell
franklyn join <pin>
```

## Aktualisieren und deinstallieren

Updates kommen mit deinen normalen Systemupdates (`yay -Syu`). Zum Deinstallieren:

```shell
yay -Rns franklyn-bin
```
