---
title: Fedora
description: Install Franklyn Sentinel on Fedora
weight: 4
---

> Works on Fedora 43+ (Workstation, KDE) and Silverblue. On other variants use the [install script](../script/) instead.

## 1. Add the repository

```shell
sudo dnf config-manager addrepo --from-repofile=https://franklyn.htl-leonding.ac.at/fedora/franklyn.repo
```

## 2. Install

```shell
sudo dnf install franklyn
```

## 3. Join an exam

```shell
franklyn join <pin>
```

## Update

Updates come with your normal system updates:

```shell
sudo dnf upgrade
```

