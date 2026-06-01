---
title: Mit Docker Compose deployen
description: Den Franklyn-Stack auf einem Server mit Traefik betreiben
weight: 40
---

Franklyn liefert ein produktionsorientiertes Compose-Setup unter `cicd/compose/`.

## Stack starten

Im Verzeichnis `cicd/compose` ausführen:

```sh
./r.sh compose up -d
```

Dieser Befehl startet Traefik, die App-Services und Postgres im `franklyn`-Netzwerk.
