---
title: Environment Variables
description: Environment variables read by Franklyn components at startup
weight: 10
---

Variables without a default are required; the container fails to start if they are unset.

## Server

### Authentication

| Variable | Default | Description |
|---|---|---|
| `KEYCLOAK_SERVER_URL` | required | Full Keycloak realm URL used for server-side token verification (e.g. `https://auth.example.org/realms/myrealm`) |

### Database

| Variable | Default | Description |
|---|---|---|
| `DB_USERNAME` | required | PostgreSQL user |
| `DB_PASSWORD` | required | PostgreSQL password |
| `DB_HOST` | required | PostgreSQL host |
| `DB_PORT` | required | PostgreSQL port |

The database name is fixed to `db`.

### Application

| Variable | Default | Description |
|---|---|---|
| `FRANKLYN_PIN_RANGE_MIN` | `1337` | Lower bound for generated session PINs |
| `FRANKLYN_PIN_RANGE_MAX` | `4200` | Upper bound for generated session PINs |
| `FRANKLYN_VIDEO_STORAGE_DIR` | `/var/lib/franklyn` | Directory where recorded videos are written |

## Proctor

| Variable | Default | Description |
|---|---|---|
| `PROCTOR_KEYCLOAK_HOST` | required | Keycloak base URL the **browser** uses — host only, no realm path (e.g. `https://auth.example.org`). Must match the host in `KEYCLOAK_SERVER_URL` and be reachable from end users, not just from inside the cluster. |
| `PROCTOR_KEYCLOAK_REALM` | required | Keycloak realm |
| `PROCTOR_KEYCLOAK_CLIENT_ID` | required | Keycloak client ID for the Proctor SPA |
