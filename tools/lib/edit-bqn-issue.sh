#!/usr/bin/env bash
# tools/lib/edit-bqn-issue.sh — issue command group for tools/edit-bqn.
#
# Sourced by tools/edit-bqn. Handles `issue add`, `issue list`, and `issue close`;
# BQN owns validation / TSV row rendering, while this shell layer handles
# preview/confirm/safe write and target-source shape observation.

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

  local TARGET_PATH TARGET_EXISTS SNAP_SIZE SNAP_MTIME SNAP_SHA256 SNAPSHOT_TOKEN ISSUE_SCHEMA ISSUE_HEADER
  TARGET_PATH="$BASE_DIR/$EXPECTED_TARGET_FILE"
  TARGET_EXISTS=0
  SNAP_SIZE=""
  SNAP_MTIME=""
  SNAP_SHA256=""
  ISSUE_SCHEMA="closed"
  if [[ -f "$TARGET_PATH" ]]; then
    TARGET_EXISTS=1
    SNAPSHOT_TOKEN="$(safe_snapshot_token "$TARGET_PATH")"
    IFS=$'\t' read -r SNAP_SIZE SNAP_MTIME SNAP_SHA256 <<< "$SNAPSHOT_TOKEN"
    ISSUE_HEADER="$(awk 'length && substr($0,1,1) != "#" && substr($0,1,1) != "\\" {print; exit}' "$TARGET_PATH")"
    case "$ISSUE_HEADER" in
      $'issue_id\tstatus\tdate\tcategory\ttitle\tamount\tcurrency\tdetails')
        ISSUE_SCHEMA="legacy"
        ;;
      $'issue_id\tstatus\tdate\tdue\tcategory\ttitle\tamount\tcurrency\tdetails')
        ISSUE_SCHEMA="due"
        ;;
      $'issue_id\tstatus\tdate\tdue\tclosed\tcategory\ttitle\tamount\tcurrency\tdetails')
        ISSUE_SCHEMA="closed"
        ;;
      '')
        echo "ERROR: existing issues.tsv has no supported header" >&2
        return 1
        ;;
      *)
        echo "ERROR: existing issues.tsv header is not a supported eight-, nine-, or ten-column schema" >&2
        return 1
        ;;
    esac
  fi

  local BQN_STDERR BQN_OUT FIRST_LINE PAYLOAD STATUS OP PROTOCOL_TARGET_FILE EXTRA
  BQN_STDERR="$(mktemp)"
  if ! BQN_OUT="$(edit_bqn_bqn_capture "$BQN_STDERR" bqn src_edit/issue_add_cmd.bqn "$ISSUE_DATE" "$ISSUE_STATUS" "$ISSUE_TITLE" "$ISSUE_AMOUNT" "$ISSUE_MEMO" "$ISSUE_SCHEMA")"; then
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
    edit_bqn_apply_append_checked "$BASE_DIR" "$POST_CHECK" "$TARGET_PATH" "$PAYLOAD" "$SNAP_SIZE" "$SNAP_MTIME" "$SNAP_SHA256" "" issue
  else
    local WRITE_OUT BACKUP_PATH POST_WRITE_SHA POST_OK
    WRITE_OUT="$(safe_create_exclusive_checked "$TARGET_PATH" $'issue_id\tstatus\tdate\tdue\tclosed\tcategory\ttitle\tamount\tcurrency\tdetails\n'"$PAYLOAD")"
    printf '%s\n' "$WRITE_OUT"
    BACKUP_PATH="$(awk -F': ' '$1 == "Backup" {print $2}' <<< "$WRITE_OUT")"
    POST_WRITE_SHA="$(_safe_write_sha256 "$TARGET_PATH")"
    POST_OK=1
    if [[ "${BQN_LEDGER_TEST_MODE:-}" == "1" && "${EDIT_BQN_TEST_FORCE_POST_CHECK_FAIL:-}" == "1" ]]; then
      printf 'Post-check failed.\n' >&2
      POST_OK=0
    elif ! run_post_check "$BASE_DIR" "$POST_CHECK" "$TARGET_PATH" "$BACKUP_PATH" issue; then
      POST_OK=0
    fi
    if [[ "$POST_OK" -eq 1 ]]; then
      return 0
    fi
    edit_bqn_run_test_hook EDIT_BQN_TEST_BEFORE_POSTCHECK_ROLLBACK_HOOK
    if safe_remove_created_checked "$TARGET_PATH" "$POST_WRITE_SHA"; then
      echo 'Rollback: removed created Issue source' >&2
      return 1
    fi
    echo 'Rollback: refused; created Issue source changed after publication; recovery required' >&2
    return 1
  fi
}

handle_edit_bqn_issue_list() {
  local FORMAT
  FORMAT="text"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --format) FORMAT="$(get_opt_val "$1" "${2-}")"; shift 2 ;;
      *) echo "ERROR: unknown issue list argument: $1" >&2; return 2 ;;
    esac
  done
  case "$FORMAT" in
    tsv|text) ;;
    *) echo "ERROR: invalid format: $FORMAT (expected 'tsv' or 'text')" >&2; return 2 ;;
  esac
  cd "$ROOT_DIR" && bqn src_edit/issue_list_cmd.bqn "$BASE_DIR" "$FORMAT"
}

handle_edit_bqn_issue_close() {
  local ISSUE_INDEX CLOSE_STATUS DECISION_MEMO CLOSE_DATE DRY_RUN YES POST_CHECK
  ISSUE_INDEX="0"
  CLOSE_STATUS="resolved"
  DECISION_MEMO=""
  CLOSE_DATE=""
  DRY_RUN=0
  YES=0
  POST_CHECK="lint"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --index) ISSUE_INDEX="$(get_opt_val "$1" "${2-}")"; shift 2 ;;
      --status) CLOSE_STATUS="$(get_opt_val "$1" "${2-}")"; shift 2 ;;
      --decision|--memo) DECISION_MEMO="$(get_opt_val_allow_empty "$1" "${2-}")"; shift 2 ;;
      --closed-date) CLOSE_DATE="$(get_opt_val "$1" "${2-}")"; shift 2 ;;
      --dry-run) DRY_RUN=1; shift ;;
      --yes) YES=1; shift ;;
      --post-check) POST_CHECK="$(get_opt_val "$1" "${2-}")"; shift 2 ;;
      *) echo "ERROR: unknown option: $1" >&2; return 2 ;;
    esac
  done

  if [[ "$ISSUE_INDEX" == "0" ]]; then
    echo "ERROR: must specify issue to close using --index" >&2
    return 2
  fi
  edit_bqn_validate_post_check "$POST_CHECK"

  local TARGET_PATH SNAPSHOT_TOKEN SNAP_SIZE SNAP_MTIME SNAP_SHA256 ISSUE_HEADER ISSUE_SCHEMA
  TARGET_PATH="$BASE_DIR/$EXPECTED_TARGET_FILE"
  SNAPSHOT_TOKEN="$(safe_snapshot_token "$TARGET_PATH")"
  IFS=$'\t' read -r SNAP_SIZE SNAP_MTIME SNAP_SHA256 <<< "$SNAPSHOT_TOKEN"
  ISSUE_HEADER="$(awk 'length && substr($0,1,1) != "#" && substr($0,1,1) != "\\" {print; exit}' "$TARGET_PATH")"
  case "$ISSUE_HEADER" in
    $'issue_id\tstatus\tdate\tcategory\ttitle\tamount\tcurrency\tdetails') ISSUE_SCHEMA="legacy" ;;
    $'issue_id\tstatus\tdate\tdue\tcategory\ttitle\tamount\tcurrency\tdetails') ISSUE_SCHEMA="due" ;;
    $'issue_id\tstatus\tdate\tdue\tclosed\tcategory\ttitle\tamount\tcurrency\tdetails') ISSUE_SCHEMA="closed" ;;
    *)
      echo "ERROR: existing issues.tsv header is not a supported eight-, nine-, or ten-column schema" >&2
      return 1
      ;;
  esac
  if [[ "$ISSUE_SCHEMA" == "closed" ]]; then
    [[ -n "$CLOSE_DATE" ]] || CLOSE_DATE="$(date +%F)"
  elif [[ -n "$CLOSE_DATE" ]]; then
    echo "ERROR: --closed-date requires the ten-column closed-aware issues.tsv schema" >&2
    return 2
  fi

  local BQN_STDERR BQN_OUT LINE_NUM ISSUE_TITLE OLD_LINE NEW_LINE MODE
  BQN_STDERR="$(mktemp)"
  if [[ "$ISSUE_SCHEMA" == "closed" ]]; then
    if ! BQN_OUT="$(edit_bqn_bqn_capture "$BQN_STDERR" bqn src_edit/issue_close_cmd.bqn "$BASE_DIR" "$ISSUE_INDEX" "$CLOSE_STATUS" "$DECISION_MEMO" "$CLOSE_DATE")"; then
      rm -f "$BQN_STDERR"
      return 1
    fi
  else
    if ! BQN_OUT="$(edit_bqn_bqn_capture "$BQN_STDERR" bqn src_edit/issue_close_cmd.bqn "$BASE_DIR" "$ISSUE_INDEX" "$CLOSE_STATUS" "$DECISION_MEMO")"; then
      rm -f "$BQN_STDERR"
      return 1
    fi
  fi
  rm -f "$BQN_STDERR"

  if ! edit_bqn_parse_replace_protocol "$BQN_OUT"; then
    return 1
  fi
  LINE_NUM="$EDIT_BQN_REPLACE_LINE_NUM"
  ISSUE_TITLE="$EDIT_BQN_REPLACE_ID"
  OLD_LINE="$EDIT_BQN_REPLACE_OLD_LINE"
  NEW_LINE="$EDIT_BQN_REPLACE_NEW_LINE"

  MODE="$(edit_bqn_mode "$DRY_RUN" "$YES")"
  edit_bqn_print_replace_preview "Issue close" "$TARGET_PATH" "$LINE_NUM" "$ISSUE_TITLE" "$MODE" "$POST_CHECK" "$OLD_LINE" "$NEW_LINE"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf 'Dry-run only. No files were modified.\n'
    return 0
  fi

  if [[ "$YES" -eq 0 ]]; then
    printf 'Close this issue? [y/N]: '
    read -r REPLY
    case "$REPLY" in
      y|Y|yes|YES) ;;
      *) echo "Cancelled. No files were modified."; return 0 ;;
    esac
  fi

  edit_bqn_apply_replace_checked "$BASE_DIR" "$POST_CHECK" "$TARGET_PATH" "$LINE_NUM" "$OLD_LINE" "$NEW_LINE" "$SNAP_SIZE" "$SNAP_MTIME" "$SNAP_SHA256" "" issue
}
