#!/usr/bin/env bash
# Physical terminal choice adapter.
#
# Candidate rows are opaque to this helper. It selects one complete input line
# and returns that line unchanged. Workflow/domain meaning stays with callers.

if ! declare -F bl_selector_preference >/dev/null 2>&1; then
  _bl_ui_choice_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  # shellcheck source=tools/lib/ui-preferences.sh
  source "$_bl_ui_choice_dir/ui-preferences.sh"
  unset _bl_ui_choice_dir
fi

bl_ui_choice_backend() {
  local selector
  selector="$(bl_selector_preference)" || return $?
  if [[ "$selector" != "auto" ]]; then
    printf '%s\n' "$selector"
    return 0
  fi

  if command -v fzf >/dev/null 2>&1; then
    printf 'fzf\n'
  elif command -v gum >/dev/null 2>&1; then
    printf 'gum\n'
  else
    printf 'plain\n'
  fi
}

bl_ui_choose_line() {
  local prompt="$1"
  local -a lines=()
  local line selector idx ans

  while IFS= read -r line; do
    lines+=("$line")
  done

  if [[ ${#lines[@]} -eq 0 ]]; then
    printf 'No candidates for: %s\n' "$prompt" >&2
    return 1
  fi

  selector="$(bl_ui_choice_backend)" || return $?
  case "$selector" in
    fzf)
      printf '%s\n' "${lines[@]}" |
        fzf --prompt="$prompt> " --height=40% --reverse --select-1 --exit-0
      ;;
    gum)
      printf '%s\n' "${lines[@]}" | gum filter --placeholder="$prompt"
      ;;
    plain)
      printf '=== %s ===\n' "$prompt" >&2
      idx=1
      for line in "${lines[@]}"; do
        printf '  %2d) %s\n' "$idx" "$line" >&2
        idx=$((idx + 1))
      done
      printf '選択 [1-%d]> ' "${#lines[@]}" >&2
      if ! read -r ans </dev/tty; then
        return 130
      fi
      if [[ "$ans" =~ ^[0-9]+$ ]] && (( ans >= 1 && ans <= ${#lines[@]} )); then
        printf '%s\n' "${lines[$((ans - 1))]}"
      else
        printf '%s\n' "$ans"
      fi
      ;;
    *)
      printf 'Error: unsupported selector backend: %s\n' "$selector" >&2
      return 2
      ;;
  esac
}
