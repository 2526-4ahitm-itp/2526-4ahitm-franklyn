#!/usr/bin/env bash
# One-time setup: generates GPG keys and API credentials, then prints
# the env vars to add to .env before running: docker compose up -d
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

aptly_gpg_dir="${script_dir}/aptly/gpg"
aptly_secrets_dir="${script_dir}/aptly/secrets"
aptly_credentials_file="${aptly_secrets_dir}/api_credentials"

flatpak_dir="${script_dir}/flatpak"
flatpak_secrets_file="${flatpak_dir}/secrets/env"
flatpak_image="ghcr.io/flatpak/flat-manager:e3da356b25f1e561ca87a969294d9c1e86224f97"

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

# ---------------------------------------------------------------------------
# Aptly: GPG key generation (skip if already exists)
# ---------------------------------------------------------------------------
setup_aptly_gpg() {
	if [[ -f "${aptly_gpg_dir}/pubring.kbx" ]] || [[ -f "${aptly_gpg_dir}/pubring.gpg" ]]; then
		echo "GPG key already exists, skipping." >&2
		return
	fi

	echo "Generating Aptly GPG key..." >&2
	mkdir -p "${aptly_gpg_dir}"
	chmod 700 "${aptly_gpg_dir}"
	export GNUPGHOME="${aptly_gpg_dir}"

	gpg --batch --gen-key <<-GPGEOF
		%no-protection
		Key-Type: RSA
		Key-Length: 4096
		Subkey-Type: RSA
		Subkey-Length: 4096
		Name-Real: Franklyn APT Repository
		Name-Email: franklyn@htl-leonding.ac.at
		Expire-Date: 0
		%commit
	GPGEOF

	chmod 700 "${aptly_gpg_dir}"
	unset GNUPGHOME
	echo "GPG key generated." >&2
}

# ---------------------------------------------------------------------------
# Aptly: API credentials (skip if already exist; env var override always wins)
# Produces a bcrypt hash for Caddy's basicauth directive.
# ---------------------------------------------------------------------------
setup_aptly_credentials() {
	mkdir -p "${aptly_secrets_dir}"
	chmod 700 "${aptly_secrets_dir}"

	local user password

	if [[ -n "${APTLY_API_USER:-}" ]] && [[ -n "${APTLY_API_PASSWORD:-}" ]]; then
		user="${APTLY_API_USER}"
		password="${APTLY_API_PASSWORD}"
		echo "Using credentials from environment." >&2
		echo "APTLY_API_USER=${user}" >"${aptly_credentials_file}"
		echo "APTLY_API_PASSWORD=${password}" >>"${aptly_credentials_file}"
		chmod 600 "${aptly_credentials_file}"
	elif [[ -f "${aptly_credentials_file}" ]]; then
		echo "Credentials already exist, reusing." >&2
		# shellcheck disable=SC1090
		source "${aptly_credentials_file}"
		user="${APTLY_API_USER}"
		password="${APTLY_API_PASSWORD}"
	else
		user="franklyn-admin"
		password="$(openssl rand -base64 24)"
		echo "APTLY_API_USER=${user}" >"${aptly_credentials_file}"
		echo "APTLY_API_PASSWORD=${password}" >>"${aptly_credentials_file}"
		chmod 600 "${aptly_credentials_file}"
		echo "" >&2
		echo "========================================" >&2
		echo " APTLY API CREDENTIALS (save these!)" >&2
		echo "========================================" >&2
		echo " User:     ${user}" >&2
		echo " Password: ${password}" >&2
		echo " File:     ${aptly_credentials_file}" >&2
		echo "========================================" >&2
		echo "" >&2
	fi

	local bcrypt_hash
	bcrypt_hash="$("${container_cmd[@]}" run --rm caddy:2-alpine caddy hash-password --plaintext "${password}")"

	APTLY_USER="${user}"
	APTLY_HASH="${bcrypt_hash}"
	APTLY_HASH_ESCAPED="$(printf '%s' "${bcrypt_hash}" | sed 's/\$/$$/g')"
}

setup_flatpak_gpg() {
	if [[ -d "${flatpak_dir}/gpg" ]]; then
		echo "Flatpak GPG keyring already exists, skipping." >&2
		return
	fi

	mkdir -p "${flatpak_dir}/gpg"
	chmod 700 "${flatpak_dir}/gpg"
	GNUPGHOME="${aptly_gpg_dir}" gpg --batch --export-secret-keys |
		GNUPGHOME="${flatpak_dir}/gpg" gpg --batch --import
}

setup_flatpak_secrets() {
	mkdir -p "${flatpak_dir}/secrets"
	chmod 700 "${flatpak_dir}/secrets"

	if [[ ! -f "${flatpak_secrets_file}" ]]; then
		{
			echo "FLATPAK_SECRET=$(openssl rand -base64 32)"
			echo "FLATPAK_DB_PASSWORD=$(openssl rand -hex 24)"
		} >"${flatpak_secrets_file}"
		chmod 600 "${flatpak_secrets_file}"
	fi

	source "${flatpak_secrets_file}"

	FLATPAK_TOKEN="$(printf '%s' "${FLATPAK_SECRET}" | "${container_cmd[@]}" run --rm -i \
		--entrypoint flat-manager-client "${flatpak_image}" gentoken \
		--base64 --secret-file - --name github-ci \
		--scope build --scope upload --scope publish --scope jobs \
		--repo stable --repo dev --prefix at.ac.htl_leonding.franklyn.Sentinel)"
}

setup_aptly_gpg
setup_aptly_credentials
setup_flatpak_gpg
setup_flatpak_secrets

# ---------------------------------------------------------------------------
# Print env vars — add these to your .env before running docker compose
# ---------------------------------------------------------------------------
echo "" >&2
echo "========================================" >&2
echo " Add to your .env:" >&2
echo "========================================" >&2
echo "FRANKLYN_APTLY_USER=${APTLY_USER}" >&2
echo "FRANKLYN_APTLY_HASH=${APTLY_HASH_ESCAPED}" >&2
echo "FRANKLYN_FLATPAK_SECRET=${FLATPAK_SECRET}" >&2
echo "FRANKLYN_FLATPAK_DB_PASSWORD=${FLATPAK_DB_PASSWORD}" >&2
echo "========================================" >&2
echo " GitHub secret FRANKLYN_FLATPAK_TOKEN:" >&2
echo "========================================" >&2
echo "${FLATPAK_TOKEN}" >&2
echo "========================================" >&2
echo "" >&2
