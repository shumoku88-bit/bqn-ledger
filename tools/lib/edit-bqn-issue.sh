#!/usr/bin/env bash
# tools/lib/edit-bqn-issue.sh — issue command group for tools/edit-bqn.
#
# Sourced by tools/edit-bqn. Handles only `issue add`; BQN owns validation and
# TSV row rendering, while this shell layer handles preview/confirm/safe write.

handle_edit_bqn_issue_add() {
  local ISSUE_DATE ISSUE_STATUS ISSUE_TITLE ISSUE_AMOUNT ISSUE_MEMO DRY_RUN YES POST_CHECK
  ISSUE_DATE="$(date +%F)"
  ISSUE_STATUS="open"
  ISSUE_TITLE=""
  ISSUE_AMOUNT="0"
  ISSUE_MEMO=""
  DRY_RUN=0
  YES=0
  POST_CHECK="lint"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --date) ISSUE_DATE="$(get_opt_val "$1" "${2-}")"; shift 2 ;;
      --status) ISSUE_STATUS="$(get_opt_val "$1" "${2-}")"; shift 2 ;;
      --title) ISSUE_TITLE="$(get_opt_val "$1" "${2-}")"; shift 2 ;;
      --amount) ISSUE_AMOUNT="$(get_opt_val "$1" "${2-}")"; shift 2 ;;
      --memo) ISSUE_MEMO="$(get_opt_val_allow_empty "$1" "${2-}")"; shift 2 ;;
      --dry-run) DRY_RUN=1; shift ;;
      --yes) YES=1; shift ;;
      --post-check) POST_CHECK="$(get_opt_val "$1" "${2-}")"; shift 2 ;;
      *) echo "ERROR: unknown option: $1" >&2; return 2 ;;
    esac
  done

  edit_bqn_validate_post_check "$POST_CHECK"

  local TARGET_PATH TARGET_EXISTS SNAP_SIZE SNAP_MTIME SNAP_SHA256 SNAPSHOT_TOKEN
  TARGET_PATH="$BASE_DIR/$EXPECTED_TARGET_FILE"
  TARGET_EXISTS=0
  SNAP_SIZE=""
  SNAP_MTIME=""
  SNAP_SHA256=""
  if [[ -f "$TARGET_PATH" ]]; then
    TARGET_EXISTS=1
    SNAPSHOT_TOKEN="$(safe_snapshot_token "$TARGET_PATH")"
    IFS=$'\t' read -r SNAP_SIZE SNAP_MTIME SNAP_SHA256 <<< "$SNAPSHOT_TOKEN"
  fi

  local BQN_STDERR BQN_OUT FIRST_LINE PAYLOAD STATUS OP PROTOCOL_TARGET_FILE EXTRA
  BQN_STDERR="$(mktemp)"
  if ! BQN_OUT="$(edit_bqn_bqn_capture "$BQN_STDERR" bqn src_edit/issue_add_cmd.bqn "$ISSUE_DATE" "$ISSUE_STATUS" "$ISSUE_TITLE" "$ISSUE_AMOUNT" "$ISSUE_MEMO")"; then
    rm -f "$BQN_STDERR"
    return 1
  fi
  rm -f "$BQN_STDERR"

  if ! edit_bqn_split_protocol_output "$BQN_OUT"; then
    return 1
  fi
  FIRST_LINE="$EDIT_BQN_PROTOCOL_FIRST_LINE"
  PAYLOAD="$EDIT_BQN_PROTOCOL_PAYLOAD"

  if ! edit_bqn_require_append_protocol "$FIRST_LINE" "$EXPECTED_TARGET_FILE"; then
    return 1
  fi

  local MODE
  MODE="$(edit_bqn_mode "$DRY_RUN" "$YES")"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    edit_bqn_print_append_preview "Issue" "$TARGET_PATH" "$MODE" "$POST_CHECK" "Issue row" "$PAYLOAD"
    printf 'Dry-run only. No files were modified.\n'
    return 0
  fi

  if [[ "$YES" -eq 0 ]]; then
    edit_bqn_print_append_preview "Issue" "$TARGET_PATH" "$MODE" "$POST_CHECK" "Issue row" "$PAYLOAD"
    if ! confirm_append; then
      echo "Cancelled. No files were modified."
      return 0
    fi
  fi

  if [[ "$TARGET_EXISTS" -eq 1 ]]; then
    edit_bqn_apply_append_checked "$BASE_DIR" "$POST_CHECK" "$TARGET_PATH" "$PAYLOAD" "$SNAP_SIZE" "$SNAP_MTIME" "$SNAP_SHA256"
  else
    local WRITE_OUT BACKUP_PATH
    WRITE_OUT="$(safe_create_checked "$TARGET_PATH" $'date\tstatus\ttitle\tamount\tmemo\n'"$PAYLOAD"$'\n')"
    printf '%s\n' "$WRITE_OUT"
    BACKUP_PATH="$(awk -F': ' '$1 == "Backup" {print $2}' <<< "$WRITE_OUT")"
    run_post_check "$BASE_DIR" "$POST_CHECK" "$TARGET_PATH" "$BACKUP_PATH"
  fi
}
