#!/usr/bin/env bash
# Recomputes the Maven dependency hash of the franklyn-server Nix package for the
# current OS and writes it into server/default.nix. Run after changing server/pom.xml.
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
nix_file="$repo_root/server/default.nix"

case "$(uname -s)" in
  Linux) key=linux ;;
  Darwin) key=darwin ;;
  *)
    echo "error: unsupported OS $(uname -s)" >&2
    exit 1
    ;;
esac

# Each hash line in server/default.nix ends with a "# darwin" / "# linux" anchor comment.
# Without exactly one line per anchor the replacement below would silently do nothing.
for anchor in darwin linux; do
  count="$(grep -cE "\"sha256-[^\"]*\";? # $anchor\$" "$nix_file" || true)"
  if [[ "$count" -ne 1 ]]; then
    echo "error: expected exactly one hash line ending in '# $anchor' in $nix_file, found $count" >&2
    exit 1
  fi
done

echo "Computing $key Maven dependency hash (downloads all server dependencies)..." >&2

# The build is expected to fail: with a fake hash Nix refetches the dependencies
# and reports the real hash. A stale real hash would not work, because Nix would
# reuse the cached dependencies and never notice the pom change.
build_log="$(cd "$repo_root" && FRANKLYN_USE_FAKE_MVN_HASH=1 nix build .#franklyn-server --impure --no-link 2>&1 || true)"
hash="$(printf '%s\n' "$build_log" | awk '
  /hash mismatch in fixed-output derivation .*maven-deps/ { found = 1 }
  found && /got:/ { print $2; exit }
')"

if [[ -z "$hash" ]]; then
  printf '%s\n' "$build_log" >&2
  echo "error: no Maven dependency hash found in the nix build output above" >&2
  exit 1
fi

sed -i.bak -E "s|\"sha256-[^\"]*\"(;?) # $key\$|\"$hash\"\1 # $key|" "$nix_file"
rm -f "$nix_file.bak"

if ! grep -F "\"$hash\"" "$nix_file" | grep -qE "# $key\$"; then
  echo "error: failed to write the $key hash into $nix_file" >&2
  exit 1
fi
echo "$key: $hash" >&2
