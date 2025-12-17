#!/usr/bin/env bash

# fr-local-deploy-docker.sh
# Interactive builder/pusher for server, proctor, and hugo images.
# Prompts for a registry prefix, lets you pick targets (all/server/proctor/hugo),
# and uses docker by default or podman via --podman.
# Performs a preflight check that required commands are installed for chosen targets:
#   - always: selected OCI tool and tr
#   - server: nix
#   - proctor: fr-proctor-build or bun, plus tar
#   - hugo: hugo
# Builds and tags images with VERSION, then offers to push (or auto-yes via --yes).

set -euo pipefail

require_min_bash() {
  local min_major=4
  local min_minor=0
  if (( BASH_VERSINFO[0] < min_major || (BASH_VERSINFO[0] == min_major && BASH_VERSINFO[1] < min_minor) )); then
    cat <<EOF >&2
This script requires Bash ${min_major}.${min_minor}+ because it uses associative arrays.
Current Bash: ${BASH_VERSION:-unknown}
macOS ships Bash 3.2 by default; please upgrade (e.g., via Homebrew: brew install bash) and re-run.
EOF
    exit 1
  fi
}

require_min_bash

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
version="$(tr -d '\n' < "$repo_root/VERSION")"
OCI_BIN="docker"

declare -a IMAGES_BUILT PUSHED SKIPPED
declare -A IMAGE_SUMMARY

ensure_trailing_slash() {
  local val="$1"
  [[ $val == */ ]] || val+="/"
  printf "%s" "$val"
}

prompt_prefix() {
  local prefill="${1-}"
  if [[ -n $prefill ]]; then
    ensure_trailing_slash "$prefill"
    return
  fi

  read -rp "Registry prefix (required, e.g., ghcr.io/me/repo/): " input
  if [[ -z $input ]]; then
    echo "Registry prefix is required; exiting." >&2
    exit 1
  fi
  ensure_trailing_slash "$input"
}

prompt_targets() {
  local default_targets="all"
  read -rp "Targets (all, server, proctor, hugo) [${default_targets}]: " input
  if [[ -z $input ]]; then
    input="$default_targets"
  fi
  IFS="," read -ra raw <<< "$input"
  local -a targets=()
  for t in "${raw[@]}"; do
    t="${t// /}"
    case "$t" in
      all)
        targets=(server proctor hugo)
        break
        ;;
      server|proctor|hugo)
        targets+=("$t")
        ;;
      *)
        echo "Unknown target: $t" >&2
        exit 1
        ;;
    esac
  done
  printf '%s\n' "${targets[@]}"
}

confirm() {
  local prompt="$1"
  if [[ ${YES_MODE:-false} == "true" ]]; then
    echo "$prompt Y"
    return 0
  fi
  read -rp "$prompt" reply
  if [[ -z $reply || $reply =~ ^[Yy] ]]; then
    return 0
  fi
  return 1
}

check_requirements() {
  local -a targets=("$@")
  local -A needed=()

  needed["$OCI_BIN"]=1
  needed["tr"]=1

  for target in "${targets[@]}"; do
    case "$target" in
      server)
        needed["nix"]=1
        ;;
      proctor)
        if command -v fr-proctor-build >/dev/null 2>&1; then
          needed["fr-proctor-build"]=1
        else
          needed["bun"]=1
        fi
        needed["tar"]=1
        ;;
      hugo)
        needed["hugo"]=1
        ;;
    esac
  done

  local -a missing=()
  for cmd in "${!needed[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing+=("$cmd")
    fi
  done

  if (( ${#missing[@]} )); then
    printf "Missing required commands: %s\n" "${missing[*]}" >&2
    exit 1
  fi
}

build_server() {
  echo "Building server package via Nix..."
  local out
  out="$(cd "$repo_root" && nix build .#franklyn-server --print-out-paths)"

  shopt -s nullglob
  local artifacts=("$out"/lib/franklyn-server-*.jar)
  if (( ${#artifacts[@]} != 1 )); then
    echo "Expected exactly one server jar in $out/lib, found ${#artifacts[@]}" >&2
    exit 1
  fi
  echo "Copying ${artifacts[0]} to repo root..."
  rm -f "$repo_root"/franklyn-server-*.jar
  cp "${artifacts[0]}" "$repo_root/"
  shopt -u nullglob

  echo "Building server docker image from repo root..."
  "$OCI_BIN" build \
    -f "$repo_root/server/src/main/docker/Dockerfile.ci" \
    -t "${IMAGE_PREFIX}franklyn-server:${version}" \
    -t "${IMAGE_PREFIX}franklyn-server:latest" \
    "$repo_root"
  IMAGES_BUILT+=("${IMAGE_PREFIX}franklyn-server:${version}" "${IMAGE_PREFIX}franklyn-server:latest")
  local summary="franklyn-server build (version ${version})"
  IMAGE_SUMMARY["${IMAGE_PREFIX}franklyn-server:${version}"]="$summary"
  IMAGE_SUMMARY["${IMAGE_PREFIX}franklyn-server:latest"]="$summary"
}

build_proctor() {
  echo "Building proctor frontend..."
  if command -v fr-proctor-build >/dev/null 2>&1; then
    (cd "$repo_root/proctor" && fr-proctor-build)
  else
    (cd "$repo_root/proctor" && bun install && bun run build)
  fi

  echo "Packaging proctor dist into tar.gz..."
  rm -f "$repo_root"/franklyn-proctor-*.tar.gz
  local proctor_tar="franklyn-proctor-${version}.tar.gz"
  tar -czf "$repo_root/$proctor_tar" -C "$repo_root/proctor/dist" .

  echo "Building proctor docker image from repo root..."
  "$OCI_BIN" build \
    -f "$repo_root/proctor/docker/Dockerfile.ci" \
    -t "${IMAGE_PREFIX}franklyn-proctor:${version}" \
    -t "${IMAGE_PREFIX}franklyn-proctor:latest" \
    "$repo_root"
  IMAGES_BUILT+=("${IMAGE_PREFIX}franklyn-proctor:${version}" "${IMAGE_PREFIX}franklyn-proctor:latest")
  local summary="franklyn-proctor build (version ${version})"
  IMAGE_SUMMARY["${IMAGE_PREFIX}franklyn-proctor:${version}"]="$summary"
  IMAGE_SUMMARY["${IMAGE_PREFIX}franklyn-proctor:latest"]="$summary"
}

build_hugo() {
  echo "Building hugo static site..."
  (cd "$repo_root/hugo" && hugo --gc --minify --destination public-docker)

  echo "Building hugo docker image from repo root..."
  "$OCI_BIN" build \
    -f "$repo_root/hugo/docker/Dockerfile.ci" \
    -t "${IMAGE_PREFIX}franklyn-hugo:${version}" \
    -t "${IMAGE_PREFIX}franklyn-hugo:latest" \
    "$repo_root"
  IMAGES_BUILT+=("${IMAGE_PREFIX}franklyn-hugo:${version}" "${IMAGE_PREFIX}franklyn-hugo:latest")
  local summary="franklyn-hugo build (version ${version})"
  IMAGE_SUMMARY["${IMAGE_PREFIX}franklyn-hugo:${version}"]="$summary"
  IMAGE_SUMMARY["${IMAGE_PREFIX}franklyn-hugo:latest"]="$summary"
}

push_images() {
  for tag in "${IMAGES_BUILT[@]}"; do
    local summary="${IMAGE_SUMMARY[$tag]:-build complete}"
    echo "${summary} => ${tag}"
    if confirm "Pushing to ${tag} (Y/n) "; then
      "$OCI_BIN" push "$tag"
      PUSHED+=("$tag")
    else
      SKIPPED+=("$tag")
    fi
  done
}

main() {
  local prefix_arg=""
  local use_podman="false"
  YES_MODE=${YES_MODE:-false}

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --podman)
        use_podman="true"
        shift
        ;;
      --yes)
        YES_MODE="true"
        shift
        ;;
      --help|-h)
        cat <<EOF
 Usage: $(basename "$0") [PREFIX] [--podman] [--yes]
  PREFIX     Registry prefix (e.g., ghcr.io/me/repo/)
  --podman   Use podman instead of docker
  --yes      Non-interactive confirmations (assume yes)
EOF
        exit 0
        ;;
      --*)
        echo "Unknown argument: $1" >&2
        exit 1
        ;;
      *)
        if [[ -z $prefix_arg ]]; then
          prefix_arg="$1"
          shift
        else
          echo "Unexpected positional argument: $1" >&2
          exit 1
        fi
        ;;
    esac
  done

  if [[ $use_podman == "true" ]]; then
    OCI_BIN="podman"
  fi

  IMAGE_PREFIX="$(prompt_prefix "$prefix_arg")"
  echo "Using registry prefix: $IMAGE_PREFIX"
  echo "Version: $version"
  echo "OCI tool: $OCI_BIN"
  echo "Yes mode: $YES_MODE"


  mapfile -t TARGETS < <(prompt_targets)

  check_requirements "${TARGETS[@]}"

  IMAGES_BUILT=()
  PUSHED=()
  SKIPPED=()
  IMAGE_SUMMARY=()

  for target in "${TARGETS[@]}"; do
    case "$target" in
      server) build_server ;;
      proctor) build_proctor ;;
      hugo) build_hugo ;;
    esac
  done

  push_images

  echo "\nSummary:"
  for img in "${IMAGES_BUILT[@]}"; do
    if printf '%s\n' "${PUSHED[@]}" | grep -qx "$img"; then
      echo "- Pushed: $img"
    elif printf '%s\n' "${SKIPPED[@]}" | grep -qx "$img"; then
      echo "- Skipped push: $img"
    else
      echo "- Built only: $img"
    fi
  done
}

main "$@"
