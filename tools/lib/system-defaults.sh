#!/usr/bin/env bash

# Load local defaults without overriding an explicit caller-selected Household.
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

# Resolve system defaults from config/system_defaults.tsv

get_default_base_dir() {
  local defaults_file="config/system_defaults.tsv"
  local fallback="data"
  if [[ -f "$defaults_file" ]]; then
    local val
    val=$(awk -F'\t' '$1 == "DEFAULT_BASE_DIR" { print $2 }' "$defaults_file")
    if [[ -n "$val" ]]; then
      printf '%s\n' "$val"
      return 0
    fi
  fi
  printf '%s\n' "$fallback"
}

get_system_default_file() {
  local key="$1"
  local fallback="$2"

  # Account physical ownership is canonical and is no longer configurable.
  # tools/edit-bqn is the only shell caller for DEFAULT_ACCOUNTS_FILE; keep the
  # old key from redirecting Account writes while the remaining writer defaults
  # are migrated source by source.
  if [[ "$key" == "DEFAULT_ACCOUNTS_FILE" ]]; then
    printf 'accounts.journal\n'
    return 0
  fi

  local defaults_file="config/system_defaults.tsv"
  if [[ -f "$defaults_file" ]]; then
    local val
    val=$(awk -F'\t' -v k="$key" '$1 == k { print $2 }' "$defaults_file")
    if [[ -n "$val" ]]; then
      printf '%s\n' "$val"
      return 0
    fi
  fi
  printf '%s\n' "$fallback"
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
  echo "Error: canonical Household root is not usable for reports: $base_dir" >&2
  echo "Missing required canonical file(s): ${missing[*]}" >&2
  return 1
}
