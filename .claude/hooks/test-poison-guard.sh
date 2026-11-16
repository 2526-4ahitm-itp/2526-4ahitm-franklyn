#!/usr/bin/env sh
# Flips the TESTS poison switch (AGENTS.md §6) when non-test code is read.
set -eu

marker="${TMPDIR:-/tmp}/franklyn-tests-poisoned"
input=$(cat)

target=$(printf '%s' "$input" |
  sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
[ -n "$target" ] || target=$(printf '%s' "$input" |
  sed -n 's/.*"path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
[ -n "$target" ] || target='<unscoped search>'

case "$target" in
  */itest/*|*/src/test/*|*_test.go|*.spec.*|*.test.*|*AGENTS.md|*CLAUDE.md) exit 0 ;;
esac

printf '%s\n' "$target" >>"$marker"
exit 0
