#!/usr/bin/env bash
# Usage: ./r.sh <docker command>
# examples:
# - ./r.sh compose -f docker-compose.yaml up -d
# - ./r.sh compose down
set -euo pipefail

docker_socket="${DOCKER_SOCKET_PATH:-/var/run/docker.sock}"

if command -v docker >/dev/null 2>&1 && [[ -S "${docker_socket}" ]]; then
	container_cmd=(docker)
elif command -v podman >/dev/null 2>&1; then
	xdg_runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
	export DOCKER_HOST="unix://${xdg_runtime_dir}/podman/podman.sock"
	export DOCKER_SOCKET_PATH="${xdg_runtime_dir}/podman/podman.sock"
	container_cmd=(podman)
else
	echo "Error: neither docker (with socket) nor podman found in PATH." >&2
	exit 1
fi

if [[ $# -eq 0 ]]; then
	echo "Usage: $0 <compose command>" >&2
	echo "Example: $0 \"compose up -d\"" >&2
	echo "Example: $0 compose up -d" >&2
	exit 1
fi

if [[ $# -eq 1 ]]; then
	echo "Running: ${container_cmd[*]} $1" >&2
	${container_cmd[@]} $1
else
	echo "Running: ${container_cmd[*]} $*" >&2
	${container_cmd[@]} "$@"
fi
