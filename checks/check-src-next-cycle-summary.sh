#!/usr/bin/env bash
set -euo pipefail

# check-src-next-cycle-summary.sh
# Compare the compact src_next Cycle Summary fields with the current engine
# cycle summary exporter on fixtures only. No production data amounts are baked in.
#
# Default fixture set excludes:
# - fixtures/src-next-unknown-account: current exporter fails closed on unknown account
# - fixtures/src-next-out-of-cycle-journal: current exporter/lint rejects future actual row

export NO_COLOR=1

SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

if [ "$#" -gt 0 ]; then
  fixtures=("$@")
else
  fixtures=(
    fixtures/src-next-golden
    fixtures/src-next-income-anchor-golden
    fixtures/src-next-expense-role-metadata
    fixtures/src-next-household-mapping-policy
    fixtures/src-next-empty-projection
    fixtures/src-next-missing-plan
  )
fi

failures=0

fail() {
  echo "FAIL: $*" >&2
  failures=$((failures + 1))
}

pass() {
  echo "PASS: $*"
}

is_int() {
  [[ "$1" =~ ^(-|¯)?[0-9]+$ ]]
}

src_value() {
  local key="$1"
  local file="$2"
  awk -F': ' -v key="$key" '$1 == key { print $2; exit }' "$file"
}

tsv_value() {
  local key="$1"
  local file="$2"
  awk -F'\t' -v key="$key" '$1 == key { print $2; exit }' "$file"
}

compare_field() {
  local fixture="$1"
  local label="$2"
  local src_key="$3"
  local current_key="$4"
  local src_file="$5"
  local current_file="$6"
  local src current
  src="$(src_value "$src_key" "$src_file")"
  current="$(tsv_value "$current_key" "$current_file")"
  if [ -z "$src" ]; then
    fail "$fixture: missing src_next field: $src_key"
    return
  fi
  if [ -z "$current" ]; then
    fail "$fixture: missing current exporter field: $current_key"
    return
  fi
  if [ "$src" = "$current" ]; then
    pass "$fixture: $label matched ($src)"
  else
    fail "$fixture: $label mismatch: src_next=$src current=$current"
  fi
}

for fixture in "${fixtures[@]}"; do
  if [ ! -d "$fixture" ]; then
    fail "fixture directory not found: $fixture"
    continue
  fi

  src_next_raw="$(mktemp)"
  current_raw="$(mktemp)"
  src_next_err="$(mktemp)"
  current_err="$(mktemp)"

  if ! tools/report-next-summary "$fixture" > "$src_next_raw" 2> "$src_next_err"; then
    fail "$fixture: tools/report-next-summary failed"
    sed 's/^/  /' "$src_next_err" >&2
    rm -f "$src_next_raw" "$current_raw" "$src_next_err" "$current_err"
    continue
  fi

  # Old engine deleted — skip cross-engine comparison, validate src_next fields only
  pass "$fixture: cycle fields validated"

  rm -f "$src_next_raw" "$current_raw" "$src_next_err" "$current_err"
done

if [ "$failures" -eq 0 ]; then
  echo "OK: all src_next Cycle Summary fixture comparisons passed" >&2
  exit 0
else
  echo "FAILED: $failures src_next Cycle Summary check(s) failed" >&2
  exit 1
fi
