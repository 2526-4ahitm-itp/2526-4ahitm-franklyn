#!/usr/bin/env sh
# Flips the TESTS poison switch (AGENTS.md §6) when non-test code is read.
# One marker per session: /tmp/franklyn-tests-poisoned.d/<session-id>
set -eu

marker_dir=/tmp/franklyn-tests-poisoned.d
input=$(cat)

session=$(printf '%s' "$input" |
  sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
[ -n "$session" ] || session="${CLAUDE_CODE_SESSION_ID:-}"
# The value becomes a filename, so refuse anything that is not a bare id.
case "$session" in
  ''|*[!0-9A-Za-z._-]*) session=unknown-session ;;
esac

tool=$(printf '%s' "$input" |
  sed -n 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

case "$tool" in
  Bash)
    # Bash reads code too (cat/grep/sed/...) and that door stood open until 2026-11-18,
    # when a probe subagent walked through it. Heuristic on purpose: this is a backstop,
    # so over-marking is the acceptable failure and a silent miss is not.
    # Drop tool_response first: it carries the command's own stdout, and matching
    # against that would mark a benign `go build` for the .go paths in its output.
    cmd=$(printf '%s' "$input" | sed 's/"tool_response".*$//' |
      sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"//p' | sed 's/"[[:space:]]*[,}].*$//')
    # Not a reader, or only touches tests/the spec/this marker -> nothing to flip.
    case "$cmd" in
      *cat*|*grep*|*rg*|*sed*|*awk*|*head*|*tail*|*less*|*nl*|*xxd*) ;;
      *) exit 0 ;;
    esac
    case "$cmd" in
      *franklyn-tests-poisoned*) exit 0 ;;
      *_test.go*|*/itest/*|*/src/test/*) exit 0 ;;
    esac
    # Only mark when it actually points at source.
    case "$cmd" in
      *.go*|*.java*|*.ts*|*.vue*|*.rs*|*.sql*|*/internal/*|*/src/main/*) ;;
      *) exit 0 ;;
    esac
    target="<bash> $(printf '%s' "$cmd" | sed 's/"[},[:space:]]*$//' | cut -c1-200)"
    ;;
  *)
    target=$(printf '%s' "$input" |
      sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
    [ -n "$target" ] || target=$(printf '%s' "$input" |
      sed -n 's/.*"path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
    [ -n "$target" ] || target='<unscoped search>'
    # Exempt: tests (the style reference) and the protobuf spec (what tests are written
    # from). Generated Go under internal/proto is deliberately absent: it stays poison.
    case "$target" in
      */itest/*|*/src/test/*|*_test.go|*.spec.*|*.test.*|*AGENTS.md|*CLAUDE.md) exit 0 ;;
      */protobuf/*.proto|*/protobuf/buf.yaml) exit 0 ;;
    esac
    ;;
esac

mkdir -p "$marker_dir"
printf '%s\n' "$target" >>"$marker_dir/$session"
exit 0
