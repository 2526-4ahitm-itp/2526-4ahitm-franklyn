---
title: Deploy with Docker Compose
description: Run the Franklyn stack on a server with Caddy
weight: 40
---

Franklyn ships a production-oriented Compose setup under `cicd/compose/`: Caddy, the app services, Postgres, the APT repository (aptly), the Flatpak repository (flat-manager) and GlitchTip.

## First setup

Run inside the `cicd/compose` directory:

```sh
./setup.sh
```

It creates the repository GPG key and the API credentials, then prints the values to add to `.env` and the `FRANKLYN_FLATPAK_TOKEN` for the GitHub secret. Running it again reuses the existing key and credentials.

## Start the stack

```sh
docker compose up -d
```

## After changing the Caddyfile

Caddy mounts the `Caddyfile` as a single file, so restart it to pick up changes:

```sh
docker compose restart franklyn-caddy
```
