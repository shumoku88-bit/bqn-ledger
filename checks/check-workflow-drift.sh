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

# CBQN policy drift guard: CI currently tracks upstream master and logs the
# exact commit. Keep this synchronized with docs/CBQN_REPRODUCIBILITY.md.
if ! grep -q 'CBQN_REF: master' "$WORKFLOW"; then
  echo "FAIL: workflow CBQN_REF no longer tracks master; update docs/CBQN_REPRODUCIBILITY.md with the policy change" >&2
  exit 1
fi
if ! grep -q 'CBQN commit:' "$WORKFLOW"; then
  echo "FAIL: workflow must log the exact CBQN commit used by CI" >&2
  exit 1
fi
if ! grep -q 'GitHub Actions currently tracks CBQN `master` during CI' docs/CBQN_REPRODUCIBILITY.md; then
  echo "FAIL: docs/CBQN_REPRODUCIBILITY.md is not synchronized with workflow CBQN_REF=master" >&2
  exit 1
fi

echo "workflow drift check OK" >&2
