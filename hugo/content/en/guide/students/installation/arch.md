---
title: Arch Linux
description: Install Franklyn Sentinel on Arch Linux, EndeavourOS, Manjaro and Omarchy
weight: 5
---

> Works on Arch Linux, EndeavourOS, Manjaro and Omarchy. On CachyOS use the [install script](../script/) instead.

## 1. Install an AUR helper

Franklyn Sentinel is in the [AUR](https://aur.archlinux.org/packages/franklyn-bin), so you need an AUR helper such as `yay` or `paru`. Skip this step if you already have one. To install `yay`:

```shell
sudo pacman -S --needed git base-devel
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -si
```

## 2. Install

{{< callout type="warning" >}}
**Manjaro:** install `base-devel` first, even if you already have an AUR helper. Manjaro does not include it and AUR packages cannot be built without it:

```shell
sudo pacman -S --needed base-devel
```
{{< /callout >}}

```shell
yay -S franklyn-bin
```

With `paru`, use `paru -S franklyn-bin`.

## 3. Join an exam

```shell
franklyn join <pin>
```

## Update and uninstall

Updates come with your normal system updates (`yay -Syu`). To uninstall:

```shell
yay -Rns franklyn-bin
```
