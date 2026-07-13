#!/usr/bin/env bash
# Dedicated travel source-event handlers. Accounting/source meaning remains BQN-owned.

handle_edit_bqn_travel_friend_add() {
  local date="" party="" item="" amount="" currency="" payer="" trip_id="" source_event_id=""
  local dry_run=0 yes=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --date) date="$(get_opt_val "$1" "${2-}")"; shift 2 ;;
      --party) party="$(get_opt_val_allow_empty "$1" "${2-}")"; shift 2 ;;
      --item) item="$(get_opt_val_allow_empty "$1" "${2-}")"; shift 2 ;;
      --amount) amount="$(get_opt_val "$1" "${2-}")"; shift 2 ;;
      --currency) currency="$(get_opt_val "$1" "${2-}")"; shift 2 ;;
      --payer) payer="$(get_opt_val "$1" "${2-}")"; shift 2 ;;
      --trip-id) trip_id="$(get_opt_val "$1" "${2-}")"; shift 2 ;;
      --source-event-id) source_event_id="$(get_opt_val "$1" "${2-}")"; shift 2 ;;
      --dry-run) dry_run=1; shift ;;
      --yes) yes=1; shift ;;
      *) echo "ERROR: unknown travel friend add argument: $1" >&2; return 2 ;;
    esac
  done
  [[ -n "$date" ]] || { echo 'ERROR: missing required option: --date' >&2; return 2; }
  [[ -n "$amount" ]] || { echo 'ERROR: missing required option: --amount' >&2; return 2; }
  [[ -n "$currency" ]] || { echo 'ERROR: missing required option: --currency' >&2; return 2; }
  [[ -n "$payer" ]] || { echo 'ERROR: missing required option: --payer' >&2; return 2; }
  [[ -n "$trip_id" ]] || { echo 'ERROR: missing required option: --trip-id' >&2; return 2; }
  [[ -n "$source_event_id" ]] || { echo 'ERROR: missing required option: --source-event-id' >&2; return 2; }
  [[ -d "$BASE_DIR" ]] || { echo "ERROR: base directory does not exist: $BASE_DIR" >&2; return 1; }

  local target_file="friend_travel_events.tsv" target_path="$BASE_DIR/friend_travel_events.tsv"
  local existed=0 snap_size="" snap_mtime="" snap_sha=""
  if [[ -e "$target_path" ]]; then
    [[ -f "$target_path" ]] || { echo "ERROR: source path is not a regular file: $target_path" >&2; return 1; }
    existed=1
    IFS=$'\t' read -r snap_size snap_mtime snap_sha <<< "$(safe_snapshot_token "$target_path")"
  fi

  local stderr_file output
  stderr_file="$(mktemp)"
  if ! output="$(edit_bqn_bqn_capture "$stderr_file" bqn src_edit/travel_friend_add_cmd.bqn "$BASE_DIR" add "$date" "$party" "$item" "$amount" "$currency" "$payer" "$trip_id" "$source_event_id" pending)"; then
    rm -f "$stderr_file"
    return 1
  fi
  rm -f "$stderr_file"
  edit_bqn_split_protocol_output "$output" || return 1
  edit_bqn_require_append_protocol "$EDIT_BQN_PROTOCOL_FIRST_LINE" "$target_file" || return 1
  local payload="$EDIT_BQN_PROTOCOL_PAYLOAD" mode
  mode="$(edit_bqn_mode "$dry_run" "$yes")"
  edit_bqn_print_append_preview 'Friend travel pending event' "$target_path" "$mode" dedicated 'Pending event row' "$payload"
  if [[ "$dry_run" -eq 1 ]]; then
    echo 'Dry-run only. No files were modified.'
    return 0
  fi
  if [[ "$yes" -eq 0 ]] && ! confirm_append; then
    echo 'Cancelled. No files were modified.'
    return 0
  fi

  local write_out backup_path post_sha
  if [[ "$existed" -eq 1 ]]; then
    edit_bqn_run_test_hook EDIT_BQN_TEST_BEFORE_APPEND_HOOK
    write_out="$(safe_append_checked "$target_path" "$payload" "$snap_size" "$snap_mtime" "$snap_sha")" || return 1
  else
    write_out="$(safe_create_exclusive_checked "$target_path" "$payload")" || return 1
  fi
  printf '%s\n' "$write_out"
  backup_path="$(awk -F': ' '$1 == "Backup" {print $2}' <<< "$write_out")"
  post_sha="$(_safe_write_sha256 "$target_path")"

  local post_ok=1
  if ! (cd "$ROOT_DIR" && bqn src_edit/travel_friend_add_cmd.bqn "$BASE_DIR" validate >/dev/null); then post_ok=0; fi
  if [[ "${BQN_LEDGER_TEST_MODE:-}" == "1" && "${EDIT_BQN_TEST_FRIEND_POST_CHECK_FAIL:-}" == "1" ]]; then post_ok=0; fi
  if [[ "$post_ok" -ne 1 ]]; then
    echo 'ERROR: friend travel source post-check failed; rolling back' >&2
    if [[ "$existed" -eq 1 ]]; then
      safe_restore_backup_checked "$target_path" "$backup_path" "$post_sha"
    else
      safe_remove_created_checked "$target_path" "$post_sha"
    fi
    echo 'Rollback: OK' >&2
    return 1
  fi
  echo 'Post-check: OK (friend travel source validator)'
  printf 'Event ID: %s\n' "$source_event_id"
}
