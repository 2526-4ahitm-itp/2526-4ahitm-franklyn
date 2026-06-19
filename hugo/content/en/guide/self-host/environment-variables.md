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
| `KEYCLOAK_URL` | required | Full Keycloak realm URL used for server-side token verification (e.g. `https://auth.example.org/realms/myrealm`) |

### Database

| Variable | Default | Description |
|---|---|---|
| `DB_USERNAME` | required | PostgreSQL user |
| `DB_PASSWORD` | required | PostgreSQL password |
| `DB_HOST` | required | PostgreSQL host |
| `DB_PORT` | required | PostgreSQL port |
| `DB_DATABASE` | required | PostgreSQL database name |

### Application

| Variable | Default | Description |
|---|---|---|
| `FRANKLYN_PIN_RANGE_MIN` | `1337` | Lower bound for generated session PINs |
| `FRANKLYN_PIN_RANGE_MAX` | `4200` | Upper bound for generated session PINs |
| `FRANKLYN_STORAGE_DIR` | `/var/lib/franklyn` | Directory for all persistent data |

## Proctor

| Variable | Default | Description |
|---|---|---|
| `KEYCLOAK_HOST` | required | Keycloak base URL served to the browser — no realm path (e.g. `https://auth.example.org`). Host must match `KEYCLOAK_URL`. |
| `KEYCLOAK_REALM` | required | Keycloak realm |
| `KEYCLOAK_CLIENT_ID` | required | Keycloak client ID for the Proctor SPA |
| `FRANKLYN_TELEMETRY` | `false` | When `true`, Proctor sends error reports to the Franklyn team. This helps us find and fix bugs faster. No personally identifiable data beyond your Keycloak user ID and role is sent. |
