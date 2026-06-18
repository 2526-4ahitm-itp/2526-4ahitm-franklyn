#!/usr/bin/env bash
set -euo pipefail

# List of required environment variables
REQUIRED_VARS=(
    KEYCLOAK_URL
    DB_USERNAME
    DB_PASSWORD
    DB_HOST
    DB_PORT
)

missing_vars=0
for var in "${REQUIRED_VARS[@]}"; do
    if [[ -z "${!var:-}" ]]; then
        echo "${var} is required" >&2
        missing_vars=1
    fi
done

if [[ $missing_vars -ne 0 ]]; then
    exit 1
fi

exec java -jar franklyn.jar
