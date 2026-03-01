#!/usr/bin/env bash
# Usage: ./r.sh [prod] <docker command>
# examples:
# - ./r.sh compose up -d
# - ./r.sh compose down
# - ./r.sh prod compose up -d
set -euo pipefail

script_dir="$(dirname "${BASH_SOURCE[0]}")"

# ===========================================================================
# Centralized host paths — every path that gets mounted into a container or
# that r.sh needs to manage on the host lives here. All variables are
# exported so docker compose can interpolate them via ${VAR} in yaml files.
# ===========================================================================

# Aptly — data, GPG keys, and API secrets
export FRANKLYN_APTLY_DATA_DIR="${script_dir}/aptly/data"
export FRANKLYN_APTLY_GPG_DIR="${script_dir}/aptly/gpg"
export FRANKLYN_APTLY_SECRETS_DIR="${script_dir}/aptly/secrets"
export FRANKLYN_APTLY_CREDENTIALS_FILE="${FRANKLYN_APTLY_SECRETS_DIR}/api_credentials"

# Caddyfile selection (profile dependent)
export FRANKLYN_CADDYFILE="${script_dir}/Caddyfile"
export FRANKLYN_CADDY_PORT="80"
export FRANKLYN_CADDY_PORT_SECURE="443"

# ---------------------------------------------------------------------------
# Container runtime detection
# ---------------------------------------------------------------------------
if command -v docker >/dev/null 2>&1; then
	container_cmd=(docker)
elif command -v podman >/dev/null 2>&1; then
	container_cmd=(podman)
else
	echo "Error: neither docker nor podman found in PATH." >&2
	exit 1
fi

if [[ $# -eq 0 ]]; then
	echo "Usage: $0 [prod] <compose command>" >&2
	echo "Example: $0 \"compose up -d\"" >&2
	echo "Example: $0 compose up -d" >&2
	echo "Example: $0 prod compose up -d" >&2
	exit 1
fi

# Optional profile selector
compose_profile="dev"
if [[ "${1:-}" == "prod" ]]; then
	compose_profile="prod"
	shift
fi
if [[ "${compose_profile}" == "dev" ]]; then
	FRANKLYN_CADDYFILE="${script_dir}/Caddyfile.dev"
	export FRANKLYN_CADDY_PORT="8080"
	export FRANKLYN_CADDY_PORT_SECURE="4433"
fi

# ---------------------------------------------------------------------------
# Aptly: ensure data directory exists
# ---------------------------------------------------------------------------
mkdir -p "${FRANKLYN_APTLY_DATA_DIR}"

# ---------------------------------------------------------------------------
# Aptly: GPG key generation (skip if already exists)
# ---------------------------------------------------------------------------
setup_aptly_gpg() {
	if [[ -f "${FRANKLYN_APTLY_GPG_DIR}/pubring.kbx" ]] || [[ -f "${FRANKLYN_APTLY_GPG_DIR}/pubring.gpg" ]]; then
		echo "Aptly GPG key already exists in ${FRANKLYN_APTLY_GPG_DIR}, skipping generation." >&2
		return
	fi

	echo "Generating Aptly GPG key in ${FRANKLYN_APTLY_GPG_DIR}..." >&2
	mkdir -p "${FRANKLYN_APTLY_GPG_DIR}"
	chmod 700 "${FRANKLYN_APTLY_GPG_DIR}"

	export GNUPGHOME="${FRANKLYN_APTLY_GPG_DIR}"

	gpg --batch --gen-key <<-GPGEOF
		%no-protection
		Key-Type: RSA
		Key-Length: 4096
		Subkey-Type: RSA
		Subkey-Length: 4096
		Name-Real: Franklyn APT Repository
		Name-Email: franklyn-apt@htl-leonding.ac.at
		Expire-Date: 0
		%commit
	GPGEOF

	chmod 700 "${FRANKLYN_APTLY_GPG_DIR}"
	echo "GPG key generated successfully." >&2
	unset GNUPGHOME
}

# ---------------------------------------------------------------------------
# Aptly: API credential generation (skip if already exists, env var override)
# Produces a bcrypt hash for Caddy's basicauth directive.
# ---------------------------------------------------------------------------
setup_aptly_credentials() {
	mkdir -p "${FRANKLYN_APTLY_SECRETS_DIR}"
	chmod 700 "${FRANKLYN_APTLY_SECRETS_DIR}"

	local user password

	# Environment variables always take precedence
	if [[ -n "${APTLY_API_USER:-}" ]] && [[ -n "${APTLY_API_PASSWORD:-}" ]]; then
		user="${APTLY_API_USER}"
		password="${APTLY_API_PASSWORD}"
		echo "Using Aptly API credentials from environment variables." >&2

		# Always regenerate files when env vars are provided (they may have changed)
		echo "APTLY_API_USER=${user}" >"${FRANKLYN_APTLY_CREDENTIALS_FILE}"
		echo "APTLY_API_PASSWORD=${password}" >>"${FRANKLYN_APTLY_CREDENTIALS_FILE}"
		chmod 600 "${FRANKLYN_APTLY_CREDENTIALS_FILE}"

	elif [[ -f "${FRANKLYN_APTLY_CREDENTIALS_FILE}" ]]; then
		echo "Aptly API credentials already exist at ${FRANKLYN_APTLY_CREDENTIALS_FILE}, skipping generation." >&2
		# shellcheck disable=SC1090
		source "${FRANKLYN_APTLY_CREDENTIALS_FILE}"
		user="${APTLY_API_USER}"
		password="${APTLY_API_PASSWORD}"

	else
		user="franklyn-admin"
		password="$(openssl rand -base64 24)"
		echo "Generated new Aptly API credentials." >&2
		echo "APTLY_API_USER=${user}" >"${FRANKLYN_APTLY_CREDENTIALS_FILE}"
		echo "APTLY_API_PASSWORD=${password}" >>"${FRANKLYN_APTLY_CREDENTIALS_FILE}"
		chmod 600 "${FRANKLYN_APTLY_CREDENTIALS_FILE}"
		echo "" >&2
		echo "========================================" >&2
		echo " APTLY API CREDENTIALS (save these!)" >&2
		echo "========================================" >&2
		echo " User:     ${user}" >&2
		echo " Password: ${password}" >&2
		echo " File:     ${FRANKLYN_APTLY_CREDENTIALS_FILE}" >&2
		echo "========================================" >&2
		echo "" >&2
	fi

	# Generate bcrypt hash for Caddy basicauth
	local bcrypt_hash
	bcrypt_hash="$("${container_cmd[@]}" run --rm caddy:2-alpine caddy hash-password --plaintext "${password}")"

	export FRANKLYN_APTLY_USER="${user}"
	export FRANKLYN_APTLY_HASH="${bcrypt_hash}"
}

# ---------------------------------------------------------------------------
# Compose files
# ---------------------------------------------------------------------------
compose_files=(-f docker-compose.yaml)
if [[ "${compose_profile}" == "prod" ]]; then
	setup_aptly_gpg
	setup_aptly_credentials
fi

# ---------------------------------------------------------------------------
# Run the container command
# ---------------------------------------------------------------------------
# Inject compose files if the first arg is "compose"
if [[ "${1:-}" == "compose" ]]; then
	shift
	echo "Running: ${container_cmd[*]} compose --profile ${compose_profile} ${compose_files[*]} $*" >&2
	"${container_cmd[@]}" compose --profile "${compose_profile}" "${compose_files[@]}" "$@"
elif [[ $# -eq 1 ]]; then
	echo "Running: ${container_cmd[*]} $1" >&2
	${container_cmd[@]} $1
else
	echo "Running: ${container_cmd[*]} $*" >&2
	"${container_cmd[@]}" "$@"
fi
