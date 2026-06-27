#!/usr/bin/env bash
set -euo pipefail

export NO_COLOR=1

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

echo "Checking tools/repo-index..." >&2

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

./tools/repo-index > "$tmp" 2>/dev/null || true

if [ ! -s "$tmp" ]; then
  echo "Error: repo-index output is empty" >&2
  exit 1
fi

# Basic structure checks (content-independent)
if ! grep -q "bqn-import" "$tmp"; then
  echo "Assertion failed: Should contain at least one bqn-import" >&2
  exit 1
fi

if ! grep -q "bqn-def" "$tmp"; then
  echo "Assertion failed: Should contain at least one bqn-def" >&2
  exit 1
fi

echo "repo-index check OK" >&2
