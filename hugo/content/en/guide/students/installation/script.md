---
title: Other Linux
description: Install Franklyn Sentinel with the install script
weight: 8
---

> Use this on Fedora Kinoite, Bazzite, AlmaLinux, Rocky Linux, CachyOS, Gentoo and any other distribution with **glibc 2.34+**. Wayland screen capture also needs PipeWire.

## 1. Install

{{< callout type="warning" >}}
**AlmaLinux / Rocky Linux:** install `zstd` first, the installer needs it to unpack Franklyn:

```shell
sudo dnf install zstd
```
{{< /callout >}}

Installs into your home directory. No `sudo` required.

```shell
curl -fsSL https://franklyn.htl-leonding.ac.at/scripts/sentinel-install.sh | bash
```

Open a new terminal afterwards so `franklyn` is on your `PATH`.

## 2. Join an exam

```shell
franklyn join <pin>
```

## Update

```shell
curl -fsSL https://franklyn.htl-leonding.ac.at/scripts/sentinel-install.sh | bash
```

## Uninstall

```shell
curl -fsSL https://franklyn.htl-leonding.ac.at/scripts/sentinel-install.sh | bash -s -- --uninstall
```

<details>
<summary>Manual download (portable)</summary>

Download the portable bundle for your architecture from [Releases](https://github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/releases). It bundles all runtime libraries, so only glibc is needed.

```shell
tar --zstd -xf franklyn-sentinel-[VERSION]-[ARCH]-portable.tar.zst
cd franklyn-sentinel-[VERSION]-[ARCH]-portable
./bin/franklyn join <pin>
```

</details>
