#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

summary="$(python3 tools/src-next-import-graph --summary --validate)"

value_for() {
  local key="$1"
  awk -F '\t' -v key="$key" '$1 == key { print $2; exit }' <<<"$summary"
}

modules="$(value_for modules)"
root_modules="$(value_for root_modules)"
nested_modules="$(value_for nested_modules)"
scan_errors="$(value_for scan_errors)"

for value in "$modules" "$root_modules" "$nested_modules" "$scan_errors"; do
  if [[ ! "$value" =~ ^[0-9]+$ ]]; then
    echo "FAIL: import graph summary contains a non-integer value: $value" >&2
    exit 1
  fi
done

if [ "$modules" -eq 0 ]; then
  echo "FAIL: src_next import graph found no BQN modules" >&2
  exit 1
fi

if [ "$root_modules" -eq 0 ]; then
  echo "FAIL: src_next import graph found no root modules" >&2
  exit 1
fi

if [ "$nested_modules" -eq 0 ]; then
  echo "FAIL: src_next import graph must include existing nested modules" >&2
  exit 1
fi

if [ "$scan_errors" -ne 0 ]; then
  echo "FAIL: src_next import graph found $scan_errors scan errors" >&2
  exit 1
fi

modules_table="$(python3 tools/src-next-import-graph --modules --validate)"
for required in \
  src_next/report.bqn \
  src_next/developer_inspection.bqn \
  src_next/context.bqn \
  src_next/calc/main.bqn; do
  if ! awk -F '\t' -v required="$required" '$1 == required { found=1 } END { exit found ? 0 : 1 }' <<<"$modules_table"; then
    echo "FAIL: import graph module table is missing $required" >&2
    exit 1
  fi
done

if ! python3 tools/src-next-import-graph --cycles --validate >/dev/null; then
  echo "FAIL: cycle report could not be generated" >&2
  exit 1
fi

printf 'OK: src_next import graph scanner passed\n'
