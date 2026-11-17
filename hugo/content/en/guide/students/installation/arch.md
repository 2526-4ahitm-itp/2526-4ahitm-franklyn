---
title: Arch Linux
description: Install Franklyn Sentinel on Arch Linux, EndeavourOS, Manjaro and Omarchy
weight: 5
---

> Works on Arch Linux, EndeavourOS, Manjaro and Omarchy. On other Arch-based distributions use the [install script](../script/) instead.

## 1. Install

Franklyn Sentinel is in the [AUR](https://aur.archlinux.org/packages/franklyn-bin).

{{< callout type="warning" >}}
**Manjaro:** run `sudo pacman -S --needed base-devel` first.
{{< /callout >}}

### Without AUR helper

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

## 2. Join an exam

```shell
franklyn join <pin>
```

## Update

### Without AUR helper

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

<<<<<<< HEAD
=======
## Uninstall

Remove the package. This works no matter how you installed it:

```shell
sudo pacman -R franklyn-bin
```

If you installed without an AUR helper, also delete the cloned build folder:

```shell
rm -rf ~/franklyn-bin
```

Optionally, delete your Franklyn settings and logs:

```shell
rm -rf ~/.config/franklyn ~/.local/share/franklyn-sentinel
```
>>>>>>> d4006f3 (docs: simplify arch uninstall command)
