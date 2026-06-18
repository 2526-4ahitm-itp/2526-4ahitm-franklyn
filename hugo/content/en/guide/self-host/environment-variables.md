---
title: Server Environment Variables
description: Environment variables read by the Franklyn server at startup
weight: 10
---

The Franklyn server reads these environment variables at startup. Variables without a default are required; the server fails to start if they are unset.

## Authentication

| Variable | Default | Description |
|---|---|---|
| `KEYCLOAK_SERVER_URL` | required | Keycloak realm URL used for token verification |
| `KEYCLOAK_ISSUER` | required | Expected `iss` claim on incoming JWTs (Keycloak realm URL) |
| `KEYCLOAK_PUBLIC_KEY_LOCATION` | required | Keycloak realm JWKS endpoint URL used to verify JWT signatures |

## Database

| Variable | Default | Description |
|---|---|---|
| `DB_USERNAME` | required | PostgreSQL user |
| `DB_PASSWORD` | required | PostgreSQL password |
| `DB_HOST` | required | PostgreSQL host |
| `DB_PORT` | required | PostgreSQL port |

The database name is fixed to `db`.

## Application

| Variable | Default | Description |
|---|---|---|
| `FRANKLYN_PIN_RANGE_MIN` | `1337` | Lower bound for generated session PINs |
| `FRANKLYN_PIN_RANGE_MAX` | `4200` | Upper bound for generated session PINs |
| `FRANKLYN_VIDEO_STORAGE_DIR` | `/var/lib/franklyn` | Directory where recorded videos are written |
