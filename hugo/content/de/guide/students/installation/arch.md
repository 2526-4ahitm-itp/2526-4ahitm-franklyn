---
title: Arch Linux
description: Franklyn Sentinel unter Arch Linux, EndeavourOS, Manjaro und Omarchy installieren
weight: 5
---

> Funktioniert unter Arch Linux, EndeavourOS, Manjaro und Omarchy. Unter anderen Arch-basierten Distributionen verwende stattdessen das [Installationsskript](../script/).

## 1. Installieren

Franklyn Sentinel ist im [AUR](https://aur.archlinux.org/packages/franklyn-bin).

{{< callout type="warning" >}}
**Manjaro:** Führe zuerst `sudo pacman -S --needed base-devel` aus.
{{< /callout >}}

### Ohne AUR Helper

```shell
sudo pacman -S --needed git base-devel
git clone https://aur.archlinux.org/franklyn-bin.git ~/franklyn-bin
cd ~/franklyn-bin
makepkg -si
```

### yay

```shell
yay -S franklyn-bin
```

### paru

```shell
paru -S franklyn-bin
```

## 2. Einer Prüfung beitreten

```shell
franklyn join <pin>
```

## Aktualisieren

### Ohne AUR Helper

```shell
cd ~/franklyn-bin
git pull
makepkg -si
```

### yay

```shell
yay -Syu
```

### paru

```shell
paru -Syu
```

## Deinstallieren

```shell
sudo pacman -Rns franklyn-bin
```
