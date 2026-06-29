#!/usr/bin/env bash
set -euo pipefail

export NO_COLOR=1

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

WORKFLOW=".github/workflows/check.yml"

echo "Checking workflow drift..." >&2

if [ ! -f "$WORKFLOW" ]; then
  echo "FAIL: missing workflow file: $WORKFLOW" >&2
  exit 1
fi

# Current workflow must not carry old Go/editor assumptions.
if grep -nE 'actions/setup-go|go-version:|editor/go\.sum|go test|tools/edit-legacy-go|GO_EDITOR_USAGE\.md|editor/' "$WORKFLOW"; then
  echo "FAIL: workflow still contains stale Go/editor references" >&2
  exit 1
fi

# Current workflow should exercise the current check and coverage entrypoints.
for needle in 'bash tools/check.sh' 'bash tools/coverage'; do
  if ! grep -q "$needle" "$WORKFLOW"; then
    echo "FAIL: workflow missing expected step: $needle" >&2
    exit 1
  fi
done

echo "workflow drift check OK" >&2
