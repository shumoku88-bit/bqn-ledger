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

# Plan mutation has dedicated writer owners. The old monolithic edit-bqn
# dispatcher remains a read/list and non-Plan command owner, but it must never
# acquire Plan writer authority. Reject those commands before any source path is
# selected or mutation candidate is constructed.
if [[ "${BASH_SOURCE[1]##*/}" == "edit-bqn" ]]; then
  _edit_bqn_args=("$@")
  _edit_bqn_i=0
  if [[ "${_edit_bqn_args[0]-}" == "--base" ]]; then
    _edit_bqn_i=2
  fi
  _edit_bqn_command="${_edit_bqn_args[_edit_bqn_i]-}"
  _edit_bqn_subcommand="${_edit_bqn_args[_edit_bqn_i+1]-}"
  if [[ "$_edit_bqn_command" == "plan" ]]; then
    case "$_edit_bqn_subcommand" in
      add|edit|finish)
        echo "ERROR: Plan mutation is owned by tools/plan-$_edit_bqn_subcommand, not tools/edit-bqn" >&2
        return 2
        ;;
    esac
  fi
  unset _edit_bqn_args _edit_bqn_i _edit_bqn_command _edit_bqn_subcommand
fi

# Canonical Household tools have no repository data fallback. Callers may still
# parse --base after obtaining this placeholder; if neither --base nor
# LEDGER_DATA_DIR selects a Household, canonical admission fails closed instead
# of silently entering the repository's historical sample data.
get_default_base_dir() {
  printf '%s\n' '/__bqn-ledger-household-root-not-selected__'
}

# Physical canonical source names are fixed by the eight-source contract.
# Account compatibility still resolves to the one canonical declaration owner.
# The Plan filename coordinate is intentionally unavailable to the retired
# dispatcher path; dedicated Plan writers own plan.journal directly.
get_system_default_file() {
  local key="$1"
  local fallback="$2"
  case "$key" in
    DEFAULT_ACCOUNTS_FILE) printf 'accounts.journal\n' ;;
    DEFAULT_PLAN_FILE) printf '__retired_plan_mutation_owner__\n' ;;
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
