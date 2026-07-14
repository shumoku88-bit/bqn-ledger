#!/usr/bin/env bash
set -euo pipefail

# Inventory ledger-like public roots and report whether POLICY_BUDGET_STYLE is
# explicitly set to envelope or none. Audit mode is intentionally non-blocking;
# the final compatibility check will replace this once exceptions are classified.

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

explicit=0
missing_key=0
missing_config=0
invalid=0
roots=0

check_root() {
  local root="$1"
  local config="$root/config.tsv"
  local value=""
  local key_lines=0

  roots=$((roots + 1))

  if [[ ! -f "$config" ]]; then
    echo "BUDGET_STYLE_AUDIT missing_config $root" >&2
    missing_config=$((missing_config + 1))
    return
  fi

  key_lines="$(awk '
    /^[[:space:]]*#/ || /^[[:space:]]*$/ { next }
    /^POLICY_BUDGET_STYLE([[:space:]]|=)/ { count++ }
    END { print count + 0 }
  ' "$config")"

  if [[ "$key_lines" -eq 0 ]]; then
    echo "BUDGET_STYLE_AUDIT missing_key $config" >&2
    missing_key=$((missing_key + 1))
    return
  fi

  if [[ "$key_lines" -ne 1 ]]; then
    echo "BUDGET_STYLE_AUDIT invalid duplicate_key $config" >&2
    invalid=$((invalid + 1))
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
    envelope|none)
      echo "BUDGET_STYLE_AUDIT explicit=$value $config" >&2
      explicit=$((explicit + 1))
      ;;
    *)
      echo "BUDGET_STYLE_AUDIT invalid value=${value:-<empty>} $config" >&2
      invalid=$((invalid + 1))
      ;;
  esac
}

check_root data

while IFS= read -r -d '' dir; do
  if [[ -f "$dir/config.tsv" || -f "$dir/accounts.tsv" || -f "$dir/journal.tsv" || -f "$dir/cycle.tsv" || -f "$dir/plan.tsv" || -f "$dir/budget_alloc.tsv" ]]; then
    check_root "$dir"
  fi
done < <(find fixtures -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)

echo "BUDGET_STYLE_AUDIT summary roots=$roots explicit=$explicit missing_key=$missing_key missing_config=$missing_config invalid=$invalid" >&2

# Audit-only discovery slice: do not fail yet. A later commit in this same slice
# will classify intentional negative/compatibility fixtures and enable enforcement.
exit 0
