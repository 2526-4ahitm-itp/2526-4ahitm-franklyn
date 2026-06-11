---
title: Sentinel Configuration
description: Configuration file locations, keys, and environment variable overrides for Franklyn Sentinel
weight: 10
---

## Configuration File Paths

Sentinel supports two levels of configuration: system-level (applies to all users on the machine) and user-level (per user, overrides system-level).

**System-level:**

| OS | Path |
|---|---|
| Linux | `/etc/franklyn/config.toml` |
| macOS | `/Library/Application Support/at.htl-leonding.franklyn/config.toml` |
| Windows | `%PROGRAMDATA%\htl-leonding\franklyn\config.toml` |

**User-level:**

| OS | Path |
|---|---|
| Linux | `~/.config/franklyn/config.toml` |
| macOS | `~/Library/Application Support/at.htl-leonding.franklyn/config.toml` |
| Windows | `%LOCALAPPDATA%\htl-leonding\franklyn\config` |

You can also set the `FRANKLYN_DATA_DIR` environment variable to point to a custom directory; Sentinel will read `$FRANKLYN_DATA_DIR/config.toml` as the system config instead of the default OS path.

> The user-level config directory and an empty file are created automatically on first `franklyn config set` or `franklyn config edit`. System-level paths can't be managed by the franklyn program.

## Configuration Keys

| Key | Default | Description |
|---|---|---|
| `api_url` | `franklyn.htl-leonding.ac.at/api` | Franklyn API endpoint |
| `oidc_url` | `https://auth.htl-leonding.ac.at` | OpenID Connect server |
| `oidc_realm` | `franklyn` | OIDC realm |
| `oidc_client_id` | `sentinel` | OIDC client ID |
| `oidc_scopes` | `openid` | OIDC scopes (space-separated) |

## Load Order

Later entries override earlier ones:

1. Embedded defaults (compiled into the binary)
2. System-level config file
3. User-level config file
4. Environment variables

## Environment Variable Overrides

Set environment variables at startup for a systemd service, Docker container, or any other managed environment to enforce configuration without touching user files.

All config keys map to `FRANKLYN_<KEY>` in uppercase:

```shell
FRANKLYN_API_URL=yourserver.example.com/api
FRANKLYN_OIDC_URL=https://auth.yourserver.example.com
FRANKLYN_OIDC_REALM=yourrealm
FRANKLYN_OIDC_CLIENT_ID=yourclient
FRANKLYN_OIDC_SCOPES=openid
```

## Notes

- Configuration is loaded once at startup. Changes to config files or environment variables require a restart.
- Config files must be valid TOML.