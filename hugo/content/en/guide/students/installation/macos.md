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

## Update

```shell
curl -fsSL https://franklyn.htl-leonding.ac.at/scripts/sentinel-install.sh | bash
```

## Uninstall

```shell
curl -fsSL https://franklyn.htl-leonding.ac.at/scripts/sentinel-install.sh | bash -s -- --uninstall
```

Open a new terminal window afterwards.

If you no longer need the screen recording permission, turn your terminal app off again under **System Settings → Privacy & Security → Screen & System Audio Recording**.
