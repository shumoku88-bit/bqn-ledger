#!/usr/bin/env bash

# Load local environment variables from .env if present
if [[ -f ".env" ]]; then
  # shellcheck disable=SC1090
  source ".env"
fi

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

ledger_base_missing_required() {
  local base_dir="$1"
  local required=(accounts.tsv journal.tsv cycle.tsv)
  local file missing=()

  for file in "${required[@]}"; do
    if [[ ! -f "$base_dir/$file" ]]; then
      missing+=("$file")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    printf '%s\n' "${missing[@]}"
  fi
}

ledger_suggest_base_dir() {
  local candidates=(
    "../ledger-data/data"
    "../../ledger-data/data"
    "data"
  )
  local candidate

  for candidate in "${candidates[@]}"; do
    if [[ -d "$candidate" ]] && [[ -f "$candidate/accounts.tsv" ]] && [[ -f "$candidate/journal.tsv" ]] && [[ -f "$candidate/cycle.tsv" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

ensure_ledger_report_base() {
  local base_dir="$1"
  local missing=() suggestion line
  while IFS= read -r line; do
    missing+=("$line")
  done < <(ledger_base_missing_required "$base_dir")

  if [[ ${#missing[@]} -eq 0 ]]; then
    return 0
  fi

  echo "Error: ledger data directory is not usable for reports: $base_dir" >&2
  echo "Missing required file(s): ${missing[*]}" >&2

  if suggestion="$(ledger_suggest_base_dir)"; then
    echo "Candidate data directory found: $suggestion" >&2
    echo "Try:" >&2
    echo "  export LEDGER_DATA_DIR=$suggestion" >&2
    echo "  tools/main-ui.sh" >&2
    echo "  tools/add-ui.sh" >&2
  else
    echo "Set LEDGER_DATA_DIR to the directory containing accounts.tsv, journal.tsv, and cycle.tsv." >&2
  fi

  return 1
}
