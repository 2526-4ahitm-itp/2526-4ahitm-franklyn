#!/usr/bin/env bash
set -euo pipefail

GNUPGHOME="/aptly/gpg"
export GNUPGHOME

echo "Importing GPG key from ${GNUPGHOME}..."
if [[ ! -d "${GNUPGHOME}" ]] || [[ -z "$(ls -A "${GNUPGHOME}" 2>/dev/null)" ]]; then
	echo "ERROR: GPG directory ${GNUPGHOME} is empty or missing." >&2
	echo "Run r.sh first to generate the GPG key." >&2
	exit 1
fi
chmod 700 "${GNUPGHOME}"

GPG_KEY_ID="$(gpg --with-colons --list-keys 2>/dev/null | awk -F: '/^pub/{print $5}' | head -1)"
if [[ -z "${GPG_KEY_ID}" ]]; then
	echo "ERROR: No GPG key found in ${GNUPGHOME}." >&2
	exit 1
fi
echo "Using GPG key: ${GPG_KEY_ID}"

mkdir -p /aptly/public
gpg --armor --export "${GPG_KEY_ID}" >/aptly/public/gpg.key
echo "GPG public key exported to /aptly/public/gpg.key"

for suite in stable dev; do
	repo_name="franklyn-${suite}"
	if ! aptly repo show "${repo_name}" &>/dev/null; then
		echo "Creating repo: ${repo_name}"
		aptly repo create \
			-distribution="${suite}" \
			-component="main" \
			-architectures="amd64,arm64" \
			"${repo_name}"
	else
		echo "Repo ${repo_name} already exists."
	fi
done

for suite in stable dev; do
	repo_name="franklyn-${suite}"
	if ! aptly publish show "${suite}" filesystem:default: &>/dev/null; then
		echo "Publishing ${repo_name} as distribution '${suite}'..."
		aptly publish repo \
			-batch \
			-gpg-key="${GPG_KEY_ID}" \
			-distribution="${suite}" \
			-architectures="amd64,arm64" \
			"${repo_name}" \
			"filesystem:default:"
	else
		echo "Distribution '${suite}' already published."
	fi
done

echo "Published repository contents:"
ls -la /aptly/public/dists/ 2>/dev/null || echo "(no dists yet)"

echo "Starting nginx on :8081..."
nginx -g "daemon off;" &

echo "Starting aptly API server on :8080 (ServeInAPIMode enabled)..."
exec aptly api serve \
	-listen=":8080" \
	-no-lock