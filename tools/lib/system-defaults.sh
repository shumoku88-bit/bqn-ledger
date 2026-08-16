#!/usr/bin/env bash

# Load local Household selection without overriding an explicit caller choice.
_caller_ledger_data_dir_set="${LEDGER_DATA_DIR+x}"
_caller_ledger_data_dir="${LEDGER_DATA_DIR-}"
if [[ -f ".env" ]]; then
  # shellcheck disable=SC1090,SC1091
  source ".env"
fi
if [[ -n "$_caller_ledger_data_dir_set" ]]; then
  LEDGER_DATA_DIR="$_caller_ledger_data_dir"
fi
unset _caller_ledger_data_dir_set _caller_ledger_data_dir

# Canonical Household tools have no repository data fallback. Callers may still
# parse --base after obtaining this placeholder; if neither --base nor
# LEDGER_DATA_DIR selects a Household, canonical admission fails closed instead
# of silently entering the repository's historical sample data.
get_default_base_dir() {
  printf '%s\n' '/__bqn-ledger-household-root-not-selected__'
}

# Physical canonical source names are fixed by the eight-source contract. This
# helper remains only while the shell entry points are consolidated; it never
# reads a config file and cannot redirect writer authority.
get_system_default_file() {
  local key="$1"
  local fallback="$2"
  case "$key" in
    DEFAULT_ACCOUNTS_FILE) printf 'accounts.journal\n' ;;
    DEFAULT_PLAN_FILE) printf 'plan.journal\n' ;;
    *) printf '%s\n' "$fallback" ;;
  esac
}

canonical_report_base_missing_required() {
  local base_dir="$1"
  local required=(
    accounts.journal actual.journal plan.journal budget.journal
    budget.toml household.toml report.toml issues.tsv
  )
  local file missing=()

  for file in "${required[@]}"; do
    [[ -f "$base_dir/$file" ]] || missing+=("$file")
  done
  if [[ ${#missing[@]} -gt 0 ]]; then
    printf '%s\n' "${missing[@]}"
  fi
}

ensure_canonical_report_base() {
  local base_dir="$1"
  local missing=() line
  while IFS= read -r line; do
    [[ -z "$line" ]] || missing+=("$line")
  done < <(canonical_report_base_missing_required "$base_dir")

  if [[ ${#missing[@]} -eq 0 ]]; then
    return 0
  fi
  echo "Error: canonical Household root is not usable: $base_dir" >&2
  echo "Set LEDGER_DATA_DIR or pass --base DIR with all eight canonical sources." >&2
  echo "Missing required canonical file(s): ${missing[*]}" >&2
  return 1
}
