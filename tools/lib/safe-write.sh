#!/usr/bin/env bash
# tools/lib/safe-write.sh — atomic TSV append with backup and stale check
#
# Replicates the Go editor's writeSingleFileAtomic + appendRowContent behavior.
# This file is sourced by shell dispatchers, not executed directly.
#
# Usage:
#   source tools/lib/safe-write.sh
#   safe_append <target_file> <row_tsv> [--backup-dir <dir>]
#   safe_rewrite <target_file> <full_content> <backup_path>

set -euo pipefail

# ── Snapshot ────────────────────────────────────────────────────

# Take a SHA256 snapshot of a file for stale detection.
# Sets global: _SW_SNAP_PATH, _SW_SNAP_SHA256, _SW_SNAP_SIZE
_safe_write_snapshot() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "ERROR: file not found: $path" >&2
    return 1
  fi
  _SW_SNAP_PATH="$path"
  _SW_SNAP_SHA256="$(openssl dgst -sha256 "$path" | awk '{print $NF}')"
  _SW_SNAP_SIZE="$(wc -c < "$path" | tr -d ' ')"
}

# Check if a file has changed since the snapshot.
# Returns 0 if unchanged, 1 if stale.
_safe_write_check_stale() {
  local path="$_SW_SNAP_PATH"
  local current_sha256
  current_sha256="$(openssl dgst -sha256 "$path" | awk '{print $NF}')"
  local current_size
  current_size="$(wc -c < "$path" | tr -d ' ')"
  if [[ "$current_sha256" != "$_SW_SNAP_SHA256" ]]; then
    echo "ERROR: file $path is stale; it changed during editing" >&2
    return 1
  fi
  if [[ "$current_size" != "$_SW_SNAP_SIZE" ]]; then
    echo "ERROR: file $path is stale; size changed during editing" >&2
    return 1
  fi
  return 0
}

# ── Backup ──────────────────────────────────────────────────────

# Choose a backup path that doesn't collide.
# Usage: _choose_backup_path <base_dir> <filename>
# Prints the chosen path to stdout.
_choose_backup_path() {
  local base_dir="$1"
  local filename="$2"
  local stamp
  stamp="$(date +%Y%m%d%H%M%S)"
  local candidate="$base_dir/.backup/${filename}.${stamp}.bak"
  if [[ ! -e "$candidate" ]]; then
    printf '%s\n' "$candidate"
    return 0
  fi
  local i=2
  while true; do
    candidate="$base_dir/.backup/${filename}.${stamp}-${i}.bak"
    if [[ ! -e "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
    i=$((i + 1))
  done
}

# Create backup of a file.
_create_backup() {
  local source_path="$1"
  local backup_path="$2"
  mkdir -p "$(dirname "$backup_path")"
  cp -p "$source_path" "$backup_path"
}

# ── Atomic write ────────────────────────────────────────────────

# Append a single row to a TSV file atomically.
# Handles trailing newline (adds one if missing).
#
# Usage: safe_append <target_file> <row_tsv>
# Assumes snapshot has been taken via _safe_write_snapshot.
safe_append() {
  local target="$1"
  local row="$2"
  local base_dir
  base_dir="$(cd "$(dirname "$target")" && pwd)"
  local filename
  filename="$(basename "$target")"
  local backup_path
  backup_path="$(_choose_backup_path "$base_dir" "$filename")"

  # Take snapshot
  _safe_write_snapshot "$target"

  # Create backup
  _create_backup "$target" "$backup_path"

  # Stale check
  if ! _safe_write_check_stale; then
    return 1
  fi

  # Build proposed content: original + ensure trailing newline + row + newline
  local tmp_file
  tmp_file="$(mktemp "${target}.tmp-XXXXXX")"
  # shellcheck disable=SC2064
  trap "rm -f '$tmp_file'" EXIT

  # Copy original content
  cat "$target" > "$tmp_file"

  # Ensure trailing newline before appending
  if [[ -s "$tmp_file" ]] && [[ "$(tail -c 1 "$tmp_file" | xxd -p)" != "0a" ]]; then
    printf '\n' >> "$tmp_file"
  fi

  # Append the new row
  printf '%s\n' "$row" >> "$tmp_file"

  # Atomic rename
  mv "$tmp_file" "$target"
  trap - EXIT

  # Print results
  printf 'Wrote: %s\n' "$target"
  printf 'Backup: %s\n' "$backup_path"
}

# Rewrite a file atomically (for plan edit).
# Usage: safe_rewrite <target_file> <new_content_file> <backup_path>
safe_rewrite() {
  local target="$1"
  local new_content_file="$2"
  local backup_path="$3"

  # Take snapshot
  _safe_write_snapshot "$target"

  # Create backup
  _create_backup "$target" "$backup_path"

  # Stale check
  if ! _safe_write_check_stale; then
    return 1
  fi

  # Atomic rename
  local tmp_file
  tmp_file="$(mktemp "${target}.tmp-XXXXXX")"
  # shellcheck disable=SC2064
  trap "rm -f '$tmp_file'" EXIT

  cp "$new_content_file" "$tmp_file"
  mv "$tmp_file" "$target"
  trap - EXIT

  printf 'Wrote: %s\n' "$target"
  printf 'Backup: %s\n' "$backup_path"
}

# ── Preview / Confirm ───────────────────────────────────────────

# Print append preview (matches Go editor output format).
print_append_preview() {
  local title="$1"
  local target="$2"
  local mode="$3"       # confirm|dry-run|yes
  local post_check="$4" # lint|none|full
  local backup_path="$5"
  local row_title="$6"
  local row="$7"

  printf '%s append preview\n' "$title"
  printf 'Target: %s\n' "$target"
  printf 'Mode: %s\n' "$mode"
  printf 'Post-check: %s\n' "$post_check"
  printf 'Backup: %s\n' "$backup_path"
  printf '%s:\n' "$row_title"
  printf '%s\n' "$row"
}

# Confirm append (y/N).
# Returns 0 for confirmed, 1 for cancelled.
confirm_append() {
  printf 'Append this row? [y/N]: '
  local answer
  read -r answer < /dev/tty || true
  answer="$(printf '%s' "$answer" | tr '[:upper:]' '[:lower:]')"
  [[ "$answer" == "y" || "$answer" == "yes" ]]
}

# ── Post-check ──────────────────────────────────────────────────

# Run BQN post-check.
# Usage: run_post_check <base_dir> <mode> <target_path> <backup_path>
run_post_check() {
  local base_dir="$1"
  local mode="$2"
  local target_path="$3"
  local backup_path="$4"

  if [[ "$mode" == "none" ]]; then
    printf 'Post-check: skipped\n'
    return 0
  fi

  local root_dir
  root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

  local cmd_str
  case "$mode" in
    lint)
      cmd_str="bqn src_next/report.bqn $base_dir"
      ;;
    full)
      cmd_str="./tools/check.sh"
      ;;
    *)
      printf 'Post-check: skipped\n'
      return 0
      ;;
  esac

  printf 'Post-check command: %s\n' "$cmd_str"

  local output
  if output=$(cd "$root_dir" && eval "$cmd_str" 2>&1); then
    printf 'Post-check: OK\n'
    return 0
  else
    printf 'Post-check failed.\n'
    printf 'Source: %s\n' "$target_path"
    printf 'Backup: %s\n' "$backup_path"
    printf 'Restore suggestion: cp %q %q\n' "$backup_path" "$target_path"
    if [[ -n "$output" ]]; then
      printf '%s\n' "$output"
    fi
    return 1
  fi
}
