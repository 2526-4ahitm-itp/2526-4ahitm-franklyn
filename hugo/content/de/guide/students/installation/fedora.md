---
title: Fedora
description: Franklyn Sentinel unter Fedora installieren
weight: 4
---

> Funktioniert unter Fedora 43+ (Workstation, KDE) und Silverblue. Unter Kinoite, Bazzite, AlmaLinux oder Rocky Linux verwende stattdessen das [Installationsskript](../script/).

## 1. Repository hinzufügen

```shell
sudo dnf config-manager addrepo --from-repofile=https://franklyn.htl-leonding.ac.at/fedora/franklyn.repo
```

## 2. Installieren

```shell
sudo dnf install franklyn
```

## 3. Einer Prüfung beitreten

```shell
franklyn join <pin>
```

## Aktualisieren

Updates kommen mit deinen normalen Systemupdates:

```shell
sudo dnf upgrade
```

## Deinstallieren

```shell
sudo dnf remove franklyn
```
