---
title: openSUSE
description: Franklyn Sentinel unter openSUSE Tumbleweed und Leap 16 installieren
weight: 6
---

> Funktioniert unter Tumbleweed und Leap 16.0. Leap 15 wird nicht unterstützt.

## 1. Repository hinzufügen

**Tumbleweed:**

```shell
sudo zypper addrepo https://download.opensuse.org/repositories/home:franklyn/openSUSE_Tumbleweed/home:franklyn.repo
```

**Leap 16.0:**

```shell
sudo zypper addrepo https://download.opensuse.org/repositories/home:franklyn/openSUSE_Leap_16.0/home:franklyn.repo
```

## 2. Installieren

```shell
sudo zypper refresh
sudo zypper install franklyn
```

`zypper refresh` fragt, ob du dem Signaturschlüssel von `home:franklyn` vertraust. Antworte mit `i` (immer vertrauen). Ist dein System auf Englisch eingestellt, ist es `a`.

## 3. Einer Prüfung beitreten

```shell
franklyn join <pin>
```

## Aktualisieren

```shell
sudo zypper refresh
sudo zypper update franklyn
```

## Deinstallieren

```shell
sudo zypper remove franklyn
```
