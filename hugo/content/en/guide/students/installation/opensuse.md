---
title: openSUSE
description: Install Franklyn Sentinel on openSUSE Tumbleweed and Leap 16
weight: 6
---

> Works on Tumbleweed and Leap 16.0. Leap 15 is not supported.

## 1. Add the repository

**Tumbleweed:**

```shell
sudo zypper addrepo https://download.opensuse.org/repositories/home:franklyn/openSUSE_Tumbleweed/home:franklyn.repo
```

**Leap 16.0:**

```shell
sudo zypper addrepo https://download.opensuse.org/repositories/home:franklyn/openSUSE_Leap_16.0/home:franklyn.repo
```

## 2. Install

```shell
sudo zypper refresh
sudo zypper install franklyn
```

## 3. Join an exam

```shell
franklyn join <pin>
```

## Update

```shell
sudo zypper refresh
sudo zypper update franklyn
```

## Uninstall

Remove the package:

```shell
sudo zypper remove franklyn
```

Remove the Franklyn repository:

```shell
sudo zypper removerepo home_franklyn
```
