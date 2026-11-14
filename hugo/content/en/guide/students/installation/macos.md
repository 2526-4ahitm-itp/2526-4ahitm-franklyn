---
title: macOS
description: Install Franklyn Sentinel on macOS
weight: 2
---

> **Requires a Mac with Apple Silicon (M1 or newer) and macOS 14 (Sonoma) or newer.** Intel Macs are not supported.

## 1. Install

Open **Terminal** and run the installer. It installs into your home directory, no `sudo` required:

```shell
curl -fsSL https://franklyn.htl-leonding.ac.at/scripts/sentinel-install.sh | bash
```

Open a new terminal window afterwards so `franklyn` is on your `PATH`.

## 2. Join an exam

```shell
franklyn join <pin>
```

The first time, macOS asks whether your terminal app may record the screen:

1. Click **Open System Settings** and turn on your terminal app (e.g. **Terminal**) under **Privacy & Security → Screen & System Audio Recording**.
2. Let macOS **Quit & Reopen** the terminal.
3. Run `franklyn join <pin>` again.

The permission belongs to the terminal app, so you only grant it once — updates keep it. A different terminal app (e.g. iTerm) needs its own permission.

## Update and uninstall

Run the installer again to **update**. To **uninstall**:

```shell
curl -fsSL https://franklyn.htl-leonding.ac.at/scripts/sentinel-install.sh | bash -s -- --uninstall
```

<details>
<summary>Manual download</summary>

{{< callout type="warning" >}}
Prefer the installer above. macOS refuses to start this build when it was downloaded with a web browser, until you remove the download mark as shown below.
{{< /callout >}}

Download `franklyn-sentinel-[VERSION]-aarch64-darwin-portable.tar.gz` from our [Releases](https://github.com/2526-4ahitm-itp/2526-4ahitm-franklyn/releases), then extract it outside of `Downloads` and remove the browser's download mark:

```shell
cd ~
mkdir franklyn-sentinel
tar -xzf ~/Downloads/franklyn-sentinel-*-aarch64-darwin-portable.tar.gz -C franklyn-sentinel
xattr -dr com.apple.quarantine franklyn-sentinel
./franklyn-sentinel/bin/franklyn join <pin>
```

</details>
