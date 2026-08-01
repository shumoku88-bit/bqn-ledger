#!/usr/bin/env bash
# tools/lib/theme.sh — Common color themes for bqn-ledger CLI tools

# Respect NO_COLOR (https://no-color.org/)
if [[ -n "${NO_COLOR:-}" ]]; then
  export BL_THEME="plain"
else
  # Resolve theme selection:
  # 1. Environment variable BL_THEME
  # 2. Local config.tsv parameter (e.g., THEME=catppuccin)
  # 3. Default fallback: 'nord' (Nordic frost palette)
  if [[ -z "${BL_THEME:-}" ]]; then
    check_dir="${base_dir:-}"
    if [[ -z "$check_dir" ]]; then
      if [[ -n "${LEDGER_DATA_DIR:-}" ]]; then
        check_dir="$LEDGER_DATA_DIR"
      else
        defaults_file="config/system_defaults.tsv"
        if [[ -f "$defaults_file" ]]; then
          check_dir=$(awk -F'\t' '$1 == "DEFAULT_BASE_DIR" { print $2 }' "$defaults_file" 2>/dev/null || true)
        fi
        unset defaults_file
      fi
    fi
    if [[ -n "$check_dir" && -f "$check_dir/config.tsv" ]]; then
      BL_THEME=$(awk -F'=' 'tolower($1) == "theme" { print $2 }' "$check_dir/config.tsv" 2>/dev/null || true)
      BL_THEME=$(echo "${BL_THEME:-}" | xargs)
    fi
    unset check_dir
  fi
  export BL_THEME="${BL_THEME:-nord}"
fi

esc=$'\e'

case "$BL_THEME" in
  catppuccin|mocha|catppuccin-mocha)
    # Catppuccin Mocha — Elegant, soothing modern dark palette
    export ESC_HEADER="${esc}[38;2;137;180;250m"       # Sapphire / Soft Blue (#89B4FA)
    export ESC_OK="${esc}[38;2;166;227;161m"           # Mint Green (#A6E3A1)
    export ESC_WARN="${esc}[38;2;249;226;175m"         # Soft Gold (#F9E2AF)
    export ESC_ERROR="${esc}[38;2;243;139;168m"        # Flamingo Red (#F38BA8)
    export ESC_FUTURE="${esc}[38;2;203;166;247m"       # Mauve Violet (#CBA6F7)
    export ESC_MUTED="${esc}[38;2;88;91;112m"          # Subtext Gray (#585B70)
    export ESC_NUM_HEADER="${esc}[1;38;2;137;180;250m" # Bold Sapphire Blue
    export ESC_RESET="${esc}[0m"
    
    export GUM_HEADER_FG="#89B4FA"
    export GUM_CURSOR_FG="#A6E3A1"
    export GUM_MATCH_FG="#F9E2AF"
    ;;
  tokyo|tokyo-night|tokyonight)
    # Tokyo Night Storm — Sleek, vibrant Cyberpunk Tokyo vibe
    export ESC_HEADER="${esc}[38;2;122;162;247m"       # Tokyo Blue (#7AA2F7)
    export ESC_OK="${esc}[38;2;158;206;106m"           # Lime Green (#9ECE6A)
    export ESC_WARN="${esc}[38;2;224;175;104m"         # Sunset Orange (#E0AF68)
    export ESC_ERROR="${esc}[38;2;247;118;142m"        # Coral Red (#F7768E)
    export ESC_FUTURE="${esc}[38;2;187;154;247m"       # Amethyst Purple (#BB9AF7)
    export ESC_MUTED="${esc}[38;2;65;72;104m"          # Deep Storm Gray (#414868)
    export ESC_NUM_HEADER="${esc}[1;38;2;122;162;247m" # Bold Tokyo Blue
    export ESC_RESET="${esc}[0m"
    
    export GUM_HEADER_FG="#7AA2F7"
    export GUM_CURSOR_FG="#9ECE6A"
    export GUM_MATCH_FG="#E0AF68"
    ;;
  dracula)
    # Dracula — High-contrast, iconic rich dark theme
    export ESC_HEADER="${esc}[38;2;139;233;253m"       # Cyan (#8BE9FD)
    export ESC_OK="${esc}[38;2;80;250;123m"            # Neon Green (#50FA7B)
    export ESC_WARN="${esc}[38;2;241;250;140m"         # Pastel Yellow (#F1FA8C)
    export ESC_ERROR="${esc}[38;2;255;85;85m"          # Vivid Red (#FF5555)
    export ESC_FUTURE="${esc}[38;2;189;147;249m"       # Bright Purple (#BD93F9)
    export ESC_MUTED="${esc}[38;2;98;114;164m"         # Comment Gray (#6272A4)
    export ESC_NUM_HEADER="${esc}[1;38;2;139;233;253m" # Bold Cyan
    export ESC_RESET="${esc}[0m"
    
    export GUM_HEADER_FG="#8BE9FD"
    export GUM_CURSOR_FG="#50FA7B"
    export GUM_MATCH_FG="#F1FA8C"
    ;;
  nord|muted|calm|savepoint|savepoint-original)
    # Savepoint (Nordic Frost) — The saved original baseline palette
    export ESC_HEADER="${esc}[38;2;136;192;208m"       # Frost Blue (#88C0D0)
    export ESC_OK="${esc}[38;2;163;190;140m"           # Sage Green (#A3BE8C)
    export ESC_WARN="${esc}[38;2;235;203;139m"         # Amber Yellow (#EBCB8B)
    export ESC_ERROR="${esc}[38;2;191;97;106m"         # Aurora Red (#BF616A)
    export ESC_FUTURE="${esc}[38;2;180;142;173m"        # Soft Purple (#B48EAD)
    export ESC_MUTED="${esc}[38;2;76;86;106m"           # Slate Gray (#4C566A)
    export ESC_NUM_HEADER="${esc}[1;38;2;136;192;208m" # Bold Frost Blue
    export ESC_RESET="${esc}[0m"
    
    export GUM_HEADER_FG="#88C0D0"
    export GUM_CURSOR_FG="#A3BE8C"
    export GUM_MATCH_FG="#EBCB8B"
    ;;
  classic|vibrant)
    # Traditional 16-color ANSI colors
    export ESC_HEADER="${esc}[1;36m"      # Bold Cyan
    export ESC_OK="${esc}[32m"            # Green
    export ESC_WARN="${esc}[33m"          # Yellow
    export ESC_ERROR="${esc}[1;31m"       # Bold Red
    export ESC_FUTURE="${esc}[35m"        # Magenta
    export ESC_MUTED="${esc}[1;34m"       # Bold Blue
    export ESC_NUM_HEADER="${esc}[1m"     # Bold
    export ESC_RESET="${esc}[0m"
    
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

set_gum_theme_args
