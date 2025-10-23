#!/usr/bin/env bash
# useage:
# ./enter-env.sh [podman] [server|hugo|proctor|sentinel]
#
# per default docker is used unless you specify otherwise with 'podman'
#
# per default the entire environment dev shell is buiilt 

set -e

COMMAND="docker"
NIX_STORE_FRANKLYN="franklyn-nix-store"
ROOT_VOL_FRANKLYN="franklyn-container-root"
DEV_CONTEXT=""

if [ "$1" = "podman" ]; then
    COMMAND="podman"
    shift
fi
echo "ℹ️ Using tool: $COMMAND"

arg="${1:-}"

if [[ "$arg" == hugo || "$arg" == server || "$arg" == proctor || "$arg" == sentinel ]]; then
    DEV_CONTEXT=$arg
    echo "ℹ️ Using dev context: $DEV_CONTEXT"
fi

function check_vol() {
    VOLNAME=$1
    if $COMMAND volume inspect "$VOLNAME" >/dev/null 2>&1; then
      echo "✅ Volume '$VOLNAME' already exists."
    else
      echo "🆕 Creating volume '$VOLNAME'..."
      $COMMAND volume create "$VOLNAME" >/dev/null
      echo "✅ Volume '$VOLNAME' created."
    fi

}

check_vol $NIX_STORE_FRANKLYN
# check_vol $ROOT_VOL_FRANKLYN

echo "Entering Nix Env"

if [[ -n $DEV_CONTEXT ]]; then
    DEV_CONTEXT=".#$DEV_CONTEXT"
fi

$COMMAND run --rm -w /src -it \
    --mount type=bind,src="$PWD",target="/src" \
    -v $NIX_STORE_FRANKLYN:/nix \
    -v $HOME/.m2:/root/.m2 \
    -v $HOME/.cargo:/root/.cargo \
    -v $HOME/.bun/install/cache:/root/.bun/install/cache \
    -v $HOME/.cache:/root/.cache \
    nixos/nix \
    nix develop $DEV_CONTEXT \
        --extra-experimental-features nix-command \
        --extra-experimental-features flakes
