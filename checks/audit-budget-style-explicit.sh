#!/usr/bin/env bash
set -euo pipefail

# Enforce the POLICY_BUDGET_STYLE explicit-choice decision for committed
# config-bearing ledgers and first-class public examples. Existing technical
# fixtures without config.tsv remain legacy fallback coverage and are not
# mass-populated by this check.

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

required_first_class=(
  data/config.tsv
  fixtures/demo/config.tsv
  fixtures/household-moko/config.tsv
  fixtures/household-monthly-salary/config.tsv
  fixtures/generalization-moko/config.tsv
  fixtures/generalization-calendar/config.tsv
  fixtures/currency-usd-single/config.tsv
  fixtures/envelopes-disabled-policy/config.tsv
)

# These fixtures intentionally prove the temporary compatibility contract.
# Keep the list narrow and verify the expected state so exceptions cannot drift.
missing_exceptions=(
  fixtures/src-next-config-eligible-missing/config.tsv
  fixtures/src-next-household-mapping-policy/config.tsv
)

empty_exceptions=(
  fixtures/src-next-config-eligible-empty/config.tsv
)

contains_path() {
  local needle="$1"
  shift
  local item
  for item in "$@"; do
    [[ "$item" == "$needle" ]] && return 0
  done
  return 1
}

budget_style_state() {
  local config="$1"
  local key_lines value

  key_lines="$(awk '
    /^[[:space:]]*#/ || /^[[:space:]]*$/ { next }
    /^POLICY_BUDGET_STYLE([[:space:]]|=)/ { count++ }
    END { print count + 0 }
  ' "$config")"

  if [[ "$key_lines" -eq 0 ]]; then
    printf 'missing\n'
    return
  fi

  if [[ "$key_lines" -ne 1 ]]; then
    printf 'duplicate\n'
    return
  fi

  value="$(awk '
    /^[[:space:]]*#/ || /^[[:space:]]*$/ { next }
    /^POLICY_BUDGET_STYLE([[:space:]]|=)/ {
      line=$0
      sub(/^POLICY_BUDGET_STYLE[[:space:]]*=[[:space:]]*/, "", line)
      if (line == $0) sub(/^POLICY_BUDGET_STYLE[[:space:]]+/, "", line)
      sub(/[[:space:]]+$/, "", line)
      print line
    }
  ' "$config")"

  case "$value" in
    envelope|none) printf 'explicit:%s\n' "$value" ;;
    '') printf 'empty\n' ;;
    *) printf 'unknown:%s\n' "$value" ;;
  esac
}

status=0
explicit=0
exceptions=0

while IFS= read -r -d '' config; do
  state="$(budget_style_state "$config")"

  if contains_path "$config" "${missing_exceptions[@]}"; then
    if [[ "$state" != missing ]]; then
      echo "FAIL: expected missing POLICY_BUDGET_STYLE compatibility fixture: $config ($state)" >&2
      status=1
    else
      exceptions=$((exceptions + 1))
    fi
    continue
  fi

  if contains_path "$config" "${empty_exceptions[@]}"; then
    if [[ "$state" != empty ]]; then
      echo "FAIL: expected empty POLICY_BUDGET_STYLE negative fixture: $config ($state)" >&2
      status=1
    else
      exceptions=$((exceptions + 1))
    fi
    continue
  fi

  case "$state" in
    explicit:envelope|explicit:none)
      explicit=$((explicit + 1))
      ;;
    *)
      echo "FAIL: committed config must explicitly choose POLICY_BUDGET_STYLE=envelope or none: $config ($state)" >&2
      status=1
      ;;
  esac
done < <(find data fixtures -type f -name config.tsv -print0 | sort -z)

for config in "${required_first_class[@]}"; do
  if [[ ! -f "$config" ]]; then
    echo "FAIL: first-class public ledger/example is missing config.tsv: $config" >&2
    status=1
    continue
  fi

  state="$(budget_style_state "$config")"
  case "$state" in
    explicit:envelope|explicit:none) ;;
    *)
      echo "FAIL: first-class public ledger/example must explicitly choose budget style: $config ($state)" >&2
      status=1
      ;;
  esac
done

for config in "${missing_exceptions[@]}" "${empty_exceptions[@]}"; do
  if [[ ! -f "$config" ]]; then
    echo "FAIL: stale budget-style exception path: $config" >&2
    status=1
  fi
done

if [[ "$status" -ne 0 ]]; then
  exit 1
fi

tools/report fixtures/demo --section snapshot >/dev/null

echo "audit-budget-style-explicit: explicit=$explicit intentional_exceptions=$exceptions; demo snapshot OK" >&2
echo "OK" >&2
