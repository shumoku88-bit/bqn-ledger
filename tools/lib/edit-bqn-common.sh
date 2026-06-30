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

edit_bqn_split_protocol_output() {
  local output="$1"
  EDIT_BQN_PROTOCOL_FIRST_LINE="${output%%$'\n'*}"
  if [[ "$EDIT_BQN_PROTOCOL_FIRST_LINE" == "$output" ]]; then
    echo "ERROR: invalid BQN protocol: missing payload line" >&2
    return 1
  fi
  EDIT_BQN_PROTOCOL_PAYLOAD="${output#*$'\n'}"
}

edit_bqn_require_append_protocol() {
  local first_line="$1"
  local expected_target_file="$2"
  local status op protocol_target_file extra

  IFS=$'\t' read -r status op protocol_target_file extra <<< "$first_line"
  if [[ -n "${extra:-}" || "$status" != "OK" || "$op" != "APPEND" || "$protocol_target_file" != "$expected_target_file" ]]; then
    echo "ERROR: invalid BQN protocol header: $first_line" >&2
    return 1
  fi
}

edit_bqn_require_append_protocol_prefix() {
  local first_line="$1"
  local expected_target_file="$2"
  local status op protocol_target_file rest

  IFS=$'\t' read -r status op protocol_target_file rest <<< "$first_line"
  if [[ "$status" != "OK" || "$op" != "APPEND" || "$protocol_target_file" != "$expected_target_file" ]]; then
    echo "ERROR: invalid BQN protocol header: $first_line" >&2
    return 1
  fi
}

edit_bqn_print_append_preview() {
  local preview_title="$1"
  local target_path="$2"
  local mode="$3"
  local post_check="$4"
  local row_title="$5"
  local payload="$6"

  printf '%s append preview\n' "$preview_title"
  printf 'Target: %s\n' "$target_path"
  printf 'Mode: %s\n' "$mode"
  printf 'Post-check: %s\n' "$post_check"
  printf '%s:\n' "$row_title"
  printf '%s\n' "$payload"
}

edit_bqn_apply_append_checked() {
  local base_dir="$1"
  local post_check="$2"
  local target_path="$3"
  local payload="$4"
  local snap_size="$5"
  local snap_mtime="$6"
  local snap_sha256="$7"
  local hook_var_name="${8:-}"
  local write_out backup_path

  if [[ -n "$hook_var_name" ]]; then
    edit_bqn_run_test_hook "$hook_var_name"
  fi

  write_out="$(safe_append_checked "$target_path" "$payload" "$snap_size" "$snap_mtime" "$snap_sha256")"
  printf '%s\n' "$write_out"

  backup_path="$(awk -F': ' '$1 == "Backup" {print $2}' <<< "$write_out")"
  run_post_check "$base_dir" "$post_check" "$target_path" "$backup_path"
}

edit_bqn_parse_replace_protocol() {
  local output="$1"
  local -a lines=()
  local status op extra

  mapfile -t lines <<< "$output"
  if [[ ${#lines[@]} -lt 3 ]]; then
    echo "ERROR: incomplete REPLACE protocol output" >&2
    return 1
  fi

  IFS=$'\t' read -r status op EDIT_BQN_REPLACE_LINE_NUM EDIT_BQN_REPLACE_ID extra <<< "${lines[0]}"
  if [[ "$status" == "ERROR" ]]; then
    echo "ERROR: $op" >&2
    return 1
  fi
  if [[ -n "${extra:-}" || "$status" != "OK" || "$op" != "REPLACE" ]]; then
    echo "ERROR: unexpected BQN protocol: expected OK REPLACE, got: $status $op" >&2
    return 1
  fi

  EDIT_BQN_REPLACE_OLD_LINE="${lines[1]}"
  EDIT_BQN_REPLACE_NEW_LINE="${lines[2]}"
  if [[ -z "$EDIT_BQN_REPLACE_LINE_NUM" || -z "$EDIT_BQN_REPLACE_OLD_LINE" || -z "$EDIT_BQN_REPLACE_NEW_LINE" ]]; then
    echo "ERROR: incomplete REPLACE protocol output" >&2
    return 1
  fi
}

edit_bqn_print_replace_preview() {
  local title="$1"
  local target_path="$2"
  local line_num="$3"
  local edit_id="$4"
  local mode="$5"
  local post_check="$6"
  local old_line="$7"
  local new_line="$8"

  printf '%s preview\n' "$title"
  printf 'Target: %s\n' "$target_path"
  printf 'Line: %s\n' "$line_num"
  printf 'Plan ID: %s\n' "$edit_id"
  printf 'Mode: %s\n' "$mode"
  printf 'Post-check: %s\n' "$post_check"
  printf 'Diff:\n'
  printf -- '- %s\n' "$old_line"
  printf -- '+ %s\n' "$new_line"
}

edit_bqn_apply_replace_checked() {
  local base_dir="$1"
  local post_check="$2"
  local target_path="$3"
  local line_num="$4"
  local old_line="$5"
  local new_line="$6"
  local snap_size="$7"
  local snap_mtime="$8"
  local snap_sha256="$9"
  local hook_var_name="${10:-}"
  local write_out backup_path

  if [[ -n "$hook_var_name" ]]; then
    edit_bqn_run_test_hook "$hook_var_name"
  fi

  write_out="$(safe_replace_line_checked "$target_path" "$line_num" "$old_line" "$new_line" "$snap_size" "$snap_mtime" "$snap_sha256")"
  printf '%s\n' "$write_out"

  backup_path="$(awk -F': ' '$1 == "Backup" {print $2}' <<< "$write_out")"
  run_post_check "$base_dir" "$post_check" "$target_path" "$backup_path"
}
