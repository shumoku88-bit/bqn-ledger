#!/usr/bin/env bash
# tools/lib/plan-finish-workflow.sh — narrow postcondition helpers for plan finish UI.
#
# The daily replenish workflow must not treat a successful process exit as proof
# that an actual journal row was appended. A cancelled confirmation currently
# returns success from the low-level editor path, so verify the selected plan_id
# is explicitly CLOSED before offering follow-up replenishment.

plan_finish_plan_id_is_open() {
  local edit_cmd="$1"
  local base_dir="$2"
  local plan_id="$3"
  local rows

  if [[ -z "$plan_id" ]]; then
    return 2
  fi

  if ! rows="$("$edit_cmd" --base "$base_dir" plan list --all --format tsv)"; then
    return 2
  fi

  awk -F '\t' -v pid="$plan_id" '
    $2 == pid {
      found = 1
      if ($8 == "CLOSED") closed = 1
      else open = 1
    }
    END {
      if (open) exit 0
      if (found && closed) exit 1
      exit 2
    }
  ' <<< "$rows"
}

plan_finish_require_applied() {
  local edit_cmd="$1"
  local base_dir="$2"
  local plan_id="$3"
  local status

  plan_finish_plan_id_is_open "$edit_cmd" "$base_dir" "$plan_id"
  status=$?

  case "$status" in
    0) return 130 ;; # explicitly open: finish was not applied
    1) return 0 ;;   # explicitly closed: finish postcondition holds
    *) return "$status" ;;
  esac
}
