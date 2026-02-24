---
title: Deploy with Docker Compose
description: Run the Franklyn stack on a server with Traefik
weight: 40
---

Franklyn ships a production-oriented Compose setup under `cicd/compose/`.

## Start the stack

Run inside the `cicd/compose` directory:

```sh
./r.sh compose up -d
```

This brings up Traefik, the app services, and Postgres on the `franklyn` network.

