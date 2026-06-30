#!/usr/bin/env bash
# tools/lib/edit-bqn-issue.sh — issue command group for tools/edit-bqn.
#
# Sourced by tools/edit-bqn. Handles only `issue add`; BQN owns validation and
# TSV row rendering, while this shell layer handles preview/confirm/safe write.

handle_edit_bqn_issue_add() {
  local ISSUE_DATE ISSUE_STATUS ISSUE_TITLE ISSUE_AMOUNT ISSUE_MEMO DRY_RUN YES
  ISSUE_DATE="$(date +%F)"
  ISSUE_STATUS="open"
  ISSUE_TITLE=""
  ISSUE_AMOUNT="0"
  ISSUE_MEMO=""
  DRY_RUN=0
  YES=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --date) ISSUE_DATE="$(get_opt_val "$1" "${2-}")"; shift 2 ;;
      --status) ISSUE_STATUS="$(get_opt_val "$1" "${2-}")"; shift 2 ;;
      --title) ISSUE_TITLE="$(get_opt_val "$1" "${2-}")"; shift 2 ;;
      --amount) ISSUE_AMOUNT="$(get_opt_val "$1" "${2-}")"; shift 2 ;;
      --memo) ISSUE_MEMO="$(get_opt_val_allow_empty "$1" "${2-}")"; shift 2 ;;
      --dry-run) DRY_RUN=1; shift ;;
      --yes) YES=1; shift ;;
      *) echo "ERROR: unknown option: $1" >&2; return 2 ;;
    esac
  done

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

  FIRST_LINE="${BQN_OUT%%$'\n'*}"
  if [[ "$FIRST_LINE" == "$BQN_OUT" ]]; then
    echo "ERROR: invalid BQN protocol: missing payload line" >&2
    return 1
  fi
  PAYLOAD="${BQN_OUT#*$'\n'}"

  IFS=$'\t' read -r STATUS OP PROTOCOL_TARGET_FILE EXTRA <<< "$FIRST_LINE"
  if [[ -n "${EXTRA:-}" || "$STATUS" != "OK" || "$OP" != "APPEND" || "$PROTOCOL_TARGET_FILE" != "$EXPECTED_TARGET_FILE" ]]; then
    echo "ERROR: invalid BQN protocol header: $FIRST_LINE" >&2
    return 1
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf 'Proposed row:\n'
    printf '%s\n' "$PAYLOAD"
    printf '(Dry-run mode, no changes saved)\n'
    return 0
  fi

  printf 'File: %s\n' "$TARGET_PATH"
  printf 'Proposed row:\n'
  printf '%s\n' "$PAYLOAD"

  if [[ "$YES" -eq 0 ]]; then
    if ! confirm_append; then
      echo "aborted by user" >&2
      return 1
    fi
  fi

  if [[ "$TARGET_EXISTS" -eq 1 ]]; then
    safe_append_checked "$TARGET_PATH" "$PAYLOAD" "$SNAP_SIZE" "$SNAP_MTIME" "$SNAP_SHA256" >/dev/null
  else
    safe_create_checked "$TARGET_PATH" $'date\tstatus\ttitle\tamount\tmemo\n'"$PAYLOAD"$'\n' >/dev/null
  fi

  printf 'OK: Issue row appended.\n'
}
