---
title: Arch Linux
description: Install Franklyn Sentinel on Arch Linux, EndeavourOS, Manjaro and Omarchy
weight: 5
---

> Works on Arch Linux, EndeavourOS, Manjaro and Omarchy. On CachyOS use the [install script](../script/) instead.

## 1. Install

Franklyn Sentinel is in the [AUR](https://aur.archlinux.org/packages/franklyn-bin). Install it with `yay`.

{{< callout type="warning" >}}
**Manjaro:** run `sudo pacman -S --needed base-devel` first.
{{< /callout >}}

```shell
yay -S franklyn-bin
```

## 2. Join an exam

```shell
franklyn join <pin>
```

## Update and uninstall

Updates come with your normal system updates (`yay -Syu`). To uninstall:

```shell
yay -Rns franklyn-bin
```
