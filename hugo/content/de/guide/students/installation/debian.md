---
title: Ubuntu / Debian
description: Franklyn Sentinel unter Ubuntu, Debian, Linux Mint, Pop!_OS und Zorin OS installieren
weight: 3
---

> Funktioniert unter Ubuntu 22.04+, Debian 12+ und darauf basierenden Distributionen: Linux Mint, Pop!_OS, Zorin OS.

## 1. Repository hinzufügen

```shell
curl -fsSL https://franklyn.htl-leonding.ac.at/repo/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/franklyn.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/franklyn.gpg] https://franklyn.htl-leonding.ac.at/repo stable main" | sudo tee /etc/apt/sources.list.d/franklyn.list
sudo apt update
```

## 2. Installieren

```shell
sudo apt install franklyn-sentinel
```

## 3. Einer Prüfung beitreten

```shell
franklyn join <pin>
```

## Aktualisieren

Updates kommen mit deinen normalen Systemupdates:

```shell
sudo apt update
sudo apt upgrade
```

