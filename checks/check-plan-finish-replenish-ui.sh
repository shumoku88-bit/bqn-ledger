#!/usr/bin/env bash
set -euo pipefail

# Verify plan finish replenishment helper stays shell-safe and supports read-only preflight.

if [ -f "src_next/report.bqn" ]; then
  ROOT_DIR="$PWD"
else
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
fi
cd "$ROOT_DIR"

bash -n tools/plan-finish-replenish-ui.sh

tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT
base="$tmp_root/plan-completion"
cp -R fixtures/plan-completion "$base"

before_plan="$(shasum -a 256 "$base/plan.tsv" | awk '{print $1}')"
before_journal="$(shasum -a 256 "$base/journal.tsv" | awk '{print $1}')"

run_preflight() {
  local label="$1"
  shift
  out="$("$@" bash tools/plan-finish-replenish-ui.sh --base "$base" --check)"
  if ! grep -qF 'OK plan finish replenish preflight passed' <<< "$out"; then
    echo "FAIL: preflight output mismatch ($label)" >&2
    printf '%s\n' "$out" >&2
    exit 1
  fi
}

run_preflight default env
run_preflight bqn-editor env BQN_EDITOR=1

after_plan="$(shasum -a 256 "$base/plan.tsv" | awk '{print $1}')"
after_journal="$(shasum -a 256 "$base/journal.tsv" | awk '{print $1}')"

if [ "$before_plan" != "$after_plan" ]; then
  echo "FAIL: preflight modified plan.tsv" >&2
  exit 1
fi
if [ "$before_journal" != "$after_journal" ]; then
  echo "FAIL: preflight modified journal.tsv" >&2
  exit 1
fi

printf 'OK plan finish replenish UI smoke\n'
