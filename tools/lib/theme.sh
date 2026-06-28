#!/usr/bin/env bash
# tools/lib/theme.sh — Common color themes for bqn-ledger CLI tools

# Respect NO_COLOR (https://no-color.org/)
if [[ -n "${NO_COLOR:-}" ]]; then
  export BL_THEME="plain"
else
  # Resolve theme selection:
  # 1. Environment variable BL_THEME
  # 2. Local config.tsv parameter (e.g., THEME=nord)
  # 3. Default fallback: 'nord' (calm and muted Nordic frost palette)
  if [[ -z "${BL_THEME:-}" ]]; then
    # Try reading from config.tsv in base_dir
    local check_dir="${base_dir:-}"
    if [[ -z "$check_dir" ]]; then
      if [[ -n "${LEDGER_DATA_DIR:-}" ]]; then
        check_dir="$LEDGER_DATA_DIR"
      else
        local defaults_file="config/system_defaults.tsv"
        if [[ -f "$defaults_file" ]]; then
          check_dir=$(awk -F'\t' '$1 == "DEFAULT_BASE_DIR" { print $2 }' "$defaults_file" 2>/dev/null || true)
        fi
      fi
    fi
    # If we resolved check_dir, look for config.tsv (Key=Value format)
    if [[ -n "$check_dir" && -f "$check_dir/config.tsv" ]]; then
      BL_THEME=$(awk -F'=' 'tolower($1) == "theme" { print $2 }' "$check_dir/config.tsv" 2>/dev/null || true)
      BL_THEME=$(echo "${BL_THEME:-}" | xargs)
    fi
    unset check_dir
  fi
  # Final fallback
  export BL_THEME="${BL_THEME:-nord}"
fi

# Define escape code helper
esc=$'\e'

case "$BL_THEME" in
  nord|muted|calm)
    # Nordic Frost / Muted pastel True Color (calm and non-vibrant)
    export ESC_HEADER="${esc}[38;2;136;192;208m"       # Frost Blue (#88C0D0)
    export ESC_OK="${esc}[38;2;163;190;140m"           # Sage Green (#A3BE8C)
    export ESC_WARN="${esc}[38;2;235;203;139m"         # Amber Yellow (#EBCB8B)
    export ESC_ERROR="${esc}[38;2;191;97;106m"         # Aurora Red (#BF616A)
    export ESC_FUTURE="${esc}[38;2;180;142;173m"        # Soft Purple (#B48EAD)
    export ESC_MUTED="${esc}[38;2;76;86;106m"           # Slate Gray (#4C566A)
    export ESC_NUM_HEADER="${esc}[1;38;2;136;192;208m" # Bold Frost Blue for numeric headers
    export ESC_RESET="${esc}[0m"
    
    # gum-specific styles (Hex values are supported by gum/lipgloss)
    export GUM_HEADER_FG="#88C0D0"
    export GUM_CURSOR_FG="#A3BE8C"
    export GUM_MATCH_FG="#EBCB8B"
    ;;
  classic|vibrant)
    # Traditional 16-color ANSI colors (vibrant)
    export ESC_HEADER="${esc}[1;36m"      # Bold Cyan
    export ESC_OK="${esc}[32m"            # Green
    export ESC_WARN="${esc}[33m"          # Yellow
    export ESC_ERROR="${esc}[1;31m"       # Bold Red
    export ESC_FUTURE="${esc}[35m"        # Magenta
    export ESC_MUTED="${esc}[1;34m"       # Bold Blue
    export ESC_NUM_HEADER="${esc}[1m"     # Bold
    export ESC_RESET="${esc}[0m"
    
    # gum-specific styles (ANSI color index)
    export GUM_HEADER_FG="6"
    export GUM_CURSOR_FG="2"
    export GUM_MATCH_FG="3"
    ;;
  *)
    # Plain text / No color
    export ESC_HEADER=""
    export ESC_OK=""
    export ESC_WARN=""
    export ESC_ERROR=""
    export ESC_FUTURE=""
    export ESC_MUTED=""
    export ESC_NUM_HEADER=""
    export ESC_RESET=""
    
    export GUM_HEADER_FG=""
    export GUM_CURSOR_FG=""
    export GUM_MATCH_FG=""
    ;;
esac

# Set gum style options into global array variables
set_gum_theme_args() {
  GUM_CHOOSE_ARGS=()
  GUM_FILTER_ARGS=()
  if [[ -n "${GUM_HEADER_FG:-}" ]]; then
    GUM_CHOOSE_ARGS+=(--header.foreground="$GUM_HEADER_FG")
    GUM_FILTER_ARGS+=(--header.foreground="$GUM_HEADER_FG")
  fi
  if [[ -n "${GUM_CURSOR_FG:-}" ]]; then
    GUM_CHOOSE_ARGS+=(--cursor.foreground="$GUM_CURSOR_FG" --selected.foreground="$GUM_CURSOR_FG")
    GUM_FILTER_ARGS+=(--indicator.foreground="$GUM_CURSOR_FG" --selected-indicator.foreground="$GUM_CURSOR_FG")
  fi
  if [[ -n "${GUM_MATCH_FG:-}" ]]; then
    GUM_FILTER_ARGS+=(--match.foreground="$GUM_MATCH_FG")
  fi
}

# Auto-execute to set arrays
set_gum_theme_args
