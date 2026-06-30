#!/usr/bin/env bash
# tools/lib/edit-bqn-common.sh — shared helpers for tools/edit-bqn dispatchers.
#
# This file is sourced by tools/edit-bqn and small command-group modules under
# tools/lib/. It owns syntax-only shell helpers; ledger meaning stays in BQN.

get_opt_val() {
  local opt="$1"
  local val="${2-}"
  if [[ $# -lt 2 || -z "$val" || "$val" == --* ]]; then
    echo "ERROR: missing value for $opt" >&2
    exit 2
  fi
  printf '%s\n' "$val"
}

get_opt_val_allow_empty() {
  local opt="$1"
  if [[ $# -lt 2 ]]; then
    echo "ERROR: missing value for $opt" >&2
    exit 2
  fi
  printf '%s\n' "$2"
}

edit_bqn_validate_post_check() {
  local mode="$1"
  case "$mode" in
    none|lint|full) ;;
    *) echo "ERROR: invalid --post-check mode: $mode" >&2; exit 2 ;;
  esac
}

edit_bqn_mode() {
  local dry_run="$1"
  local yes="$2"
  if [[ "$dry_run" -eq 1 ]]; then
    printf 'dry-run\n'
  elif [[ "$yes" -eq 1 ]]; then
    printf 'yes\n'
  else
    printf 'confirm\n'
  fi
}

edit_bqn_run_test_hook() {
  local var_name="$1"
  local hook="${!var_name:-}"
  if [[ "${BQN_LEDGER_TEST_MODE:-}" != "1" || -z "$hook" ]]; then
    return 0
  fi
  if declare -F -- "$hook" >/dev/null; then
    "$hook"
  else
    printf 'Warning: %s is set but not a declared function: %s\n' "$var_name" "$hook" >&2
  fi
}

edit_bqn_bqn_capture() {
  local stderr_file="$1"
  shift
  local output=""
  if ! output="$(cd "$ROOT_DIR" && "$@" 2>"$stderr_file")"; then
    if [[ -n "$output" ]]; then
      printf '%s\n' "$output" >&2
    fi
    if [[ -s "$stderr_file" ]]; then
      cat "$stderr_file" >&2
    fi
    return 1
  fi
  printf '%s\n' "$output"
}
