---
title: Ubuntu / Debian
description: Install Franklyn Sentinel on Ubuntu, Kubuntu, Debian, Linux Mint, MX Linux, Pop!_OS and Zorin OS
weight: 3
---

> Works on Ubuntu 22.04+, Debian 12+ and distributions based on them: Kubuntu, Linux Mint, MX Linux, Pop!_OS, Zorin OS.

## 1. Add the repository

```shell
curl -fsSL https://franklyn.htl-leonding.ac.at/repo/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/franklyn.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/franklyn.gpg] https://franklyn.htl-leonding.ac.at/repo stable main" | sudo tee /etc/apt/sources.list.d/franklyn.list
sudo apt update
```

## 2. Install

```shell
sudo apt install franklyn-sentinel
```

## 3. Join an exam

```shell
franklyn join <pin>
```

## Update

Updates come with your normal system updates:

```shell
sudo apt update
sudo apt upgrade
```

## Uninstall

Remove the package:

```shell
sudo apt remove franklyn-sentinel
```

Remove the Franklyn repository and its signing key:

```shell
sudo rm /etc/apt/sources.list.d/franklyn.list /etc/apt/keyrings/franklyn.gpg
sudo apt update
```
