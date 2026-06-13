---
title: Einrichtung
description: Franklyn Sentinel konfigurieren und einer Prüfung beitreten
weight: 20
---

## Server konfigurieren

> Wenn dein Lehrer den Standardserver (`franklyn.htl-leonding.ac.at`) verwendet, überspringe diesen Schritt.

Falls deine Prüfung auf einem anderen Server läuft, gib folgendes im Terminal ein, um die Serveradresse einmalig vor dem Beitreten festzulegen – ähnlich wie das Konfigurieren von git-Benutzername und -E-Mail zu Beginn einer Prüfung.

```shell
franklyn config set api_url "franklyn3.htl-leonding.ac.at/api"
```

Ersetze `franklyn3.htl-leonding.ac.at` durch den Server, den dein Lehrer angibt.

## Der Prüfung beitreten

Gib folgendes im Terminal ein, um der Prüfung mit dem von deinem Lehrer bereitgestellten PIN beizutreten:

```shell
franklyn join <pin>
```

Beispiel: `franklyn join 1234`
