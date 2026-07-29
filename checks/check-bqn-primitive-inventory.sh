#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

baseline=221c4234af615cbf31bb9e22a7600efed58b088c
report=docs/BQN_PRIMITIVE_USAGE_INVENTORY.md
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

python3 tools/bqn-primitive-inventory \
  --ref "$baseline" \
  --format markdown >"$tmp"

if [[ ! -f $report ]]; then
  cat "$tmp" >&2
  echo "FAIL: missing generated inventory: $report" >&2
  exit 1
fi

if ! cmp -s "$tmp" "$report"; then
  diff -u "$report" "$tmp" >&2 || true
  echo "FAIL: BQN primitive inventory drift" >&2
  exit 1
fi
