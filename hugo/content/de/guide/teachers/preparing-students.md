---
title: Schüler vorbereiten
description: Schüler vor dem Test mit Franklyn Sentinel einrichten
weight: 30
---

Schüler müssen Franklyn Sentinel vor dem Test installiert haben. Wenn du deinen eigenen Server betreibst, müssen sie außerdem konfigurieren, mit welchem Server sie sich verbinden.

Wenn du nicht sicher bist, mit welchem Server du verbunden bist, kannst du die URL im Browser auf der Proctor-Seite nachsehen.

Wenn du zum Beispiel folgendes siehst:
`https://franklyn3.htl-leonding.ac.at/proctor/exams/`

dann lautet die URL für Schüler:
`franklyn3.htl-leonding.ac.at/api`

---

**Franklyn einrichten**

Gib folgendes im Terminal ein, um den Server zu konfigurieren (überspringen, wenn `franklyn.htl-leonding.ac.at` verwendet wird):

```shell
franklyn config set api_url "franklyn3.htl-leonding.ac.at/api"
```

Gib folgendes im Terminal ein, um dem Test mit dem von deinem Lehrer bereitgestellten PIN beizutreten:

```shell
franklyn join <pin>
```
