#!/usr/bin/env bash
# Pure admission for local terminal UI preferences.
# These settings are environment-owned and must not be read from ledger config.tsv.

bl_selector_preference() {
  local mode="${BL_UI_MODE:-}"
  if [[ "$mode" == "minimal" ]]; then
    printf 'plain\n'
    return 0
  fi
  local value="${BL_SELECTOR:-auto}"
  case "$value" in
    auto|fzf|gum|plain) printf '%s\n' "$value" ;;
    *)
      printf 'Error: invalid BL_SELECTOR: %s (expected auto, fzf, gum, or plain)\n' "$value" >&2
      return 2
      ;;
  esac
}

bl_fzf_preview_window() {
  local value="${BL_FZF_PREVIEW_WINDOW:-right:60%}"
  if [[ ! "$value" =~ ^(right|left|up|down):([1-9]|[1-9][0-9]|100)%$ ]]; then
    printf 'Error: invalid BL_FZF_PREVIEW_WINDOW: %s (expected POSITION:PERCENT, e.g. right:75%%)\n' "$value" >&2
    return 2
  fi
  printf '%s\n' "$value"
}
