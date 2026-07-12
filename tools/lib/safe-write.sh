#!/usr/bin/env bash
# tools/lib/safe-write.sh — atomic TSV append with backup and stale check
#
# Replicates the BQN editor's writeSingleFileAtomic + appendRowContent behavior.
# This file is sourced by shell dispatchers, not executed directly.
#
# Usage:
#   source tools/lib/safe-write.sh
#   safe_append <target_file> <row_tsv> [--backup-dir <dir>]
#   safe_rewrite <target_file> <full_content> <backup_path>

set -euo pipefail

# ── Snapshot ────────────────────────────────────────────────────

# Return a portable mtime token for stale detection.
_safe_write_mtime() {
  local path="$1"
  if stat -f %m "$path" >/dev/null 2>&1; then
    stat -f %m "$path"
  else
    stat -c %Y "$path"
  fi
}

# Return the final byte as lowercase hex using POSIX od (empty for empty files).
_safe_write_last_byte_hex() {
  local path="$1"
  tail -c 1 "$path" | od -An -tx1 | tr -d '[:space:]'
}

# Return a portable SHA256 digest.
_safe_write_sha256() {
  local path="$1"
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$path" | awk '{print $1}'
  else
    openssl dgst -sha256 "$path" | awk '{print $NF}'
  fi
}

# Take a SHA256 snapshot of a file for stale detection.
# Sets global: _SW_SNAP_PATH, _SW_SNAP_SHA256, _SW_SNAP_SIZE, _SW_SNAP_MTIME
_safe_write_snapshot() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "ERROR: file not found: $path" >&2
    return 1
  fi
  _SW_SNAP_PATH="$path"
  _SW_SNAP_SHA256="$(_safe_write_sha256 "$path")"
  _SW_SNAP_SIZE="$(wc -c < "$path" | tr -d ' ')"
  _SW_SNAP_MTIME="$(_safe_write_mtime "$path")"
}

# Print a tab-separated snapshot token: size, mtime, sha256.
# Callers can capture this before validation/preview and pass it to
# safe_append_checked immediately before writing.
safe_snapshot_token() {
  local path="$1"
  _safe_write_snapshot "$path"
  printf '%s\t%s\t%s\n' "$_SW_SNAP_SIZE" "$_SW_SNAP_MTIME" "$_SW_SNAP_SHA256"
}

# Check if a file has changed since the snapshot.
# Returns 0 if unchanged, 1 if stale.
_safe_write_check_stale() {
  local path="$_SW_SNAP_PATH"
  local current_sha256 current_size current_mtime
  current_sha256="$(_safe_write_sha256 "$path")"
  current_size="$(wc -c < "$path" | tr -d ' ')"
  current_mtime="$(_safe_write_mtime "$path")"
  if [[ "$current_sha256" != "$_SW_SNAP_SHA256" ]]; then
    echo "ERROR: file $path is stale; it changed during editing" >&2
    return 1
  fi
  if [[ "$current_size" != "$_SW_SNAP_SIZE" ]]; then
    echo "ERROR: file $path is stale; size changed during editing" >&2
    return 1
  fi
  if [[ "$current_mtime" != "$_SW_SNAP_MTIME" ]]; then
    echo "ERROR: file $path is stale; modification time changed during editing" >&2
    return 1
  fi
  return 0
}

# Seed the internal stale-check snapshot from a previously captured token.
_safe_write_seed_snapshot() {
  local path="$1"
  local size="$2"
  local mtime="$3"
  local sha256="$4"
  _SW_SNAP_PATH="$path"
  _SW_SNAP_SIZE="$size"
  _SW_SNAP_MTIME="$mtime"
  _SW_SNAP_SHA256="$sha256"
}

# Check an explicit previously captured snapshot token.
_safe_write_check_expected_snapshot() {
  local path="$1"
  local size="$2"
  local mtime="$3"
  local sha256="$4"
  _safe_write_seed_snapshot "$path" "$size" "$mtime" "$sha256"
  _safe_write_check_stale
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
  if [[ -s "$tmp_file" ]] && [[ "$(_safe_write_last_byte_hex "$tmp_file")" != "0a" ]]; then
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

# Create a new file atomically if it still does not exist.
#
# Usage: safe_create_checked <target_file> <content>
# This is used for optional append-only source files such as issues.tsv.
# Existing files must use safe_append_checked so a backup and stale check exist.
safe_create_checked() {
  local target="$1"
  local content="$2"
  local target_dir
  target_dir="$(dirname "$target")"

  if [[ -e "$target" ]]; then
    echo "ERROR: file $target is stale; it appeared during editing" >&2
    return 1
  fi

  mkdir -p "$target_dir"
  local tmp_file
  tmp_file="$(mktemp "${target}.tmp-XXXXXX")"
  # shellcheck disable=SC2064
  trap "rm -f '$tmp_file'" EXIT

  printf '%s' "$content" > "$tmp_file"

  if [[ -e "$target" ]]; then
    echo "ERROR: file $target is stale; it appeared during editing" >&2
    return 1
  fi

  mv "$tmp_file" "$target"
  trap - EXIT

  printf 'Wrote: %s\n' "$target"
  printf 'Backup: none (created new file)\n'
}

# Assert that a specific 1-based line number exists and exactly matches an expected row.
# No normalization is performed: tabs, empty fields, and bytes other than the line
# terminator must match exactly.
_safe_write_assert_line_exact() {
  local target="$1"
  local line_number="$2"
  local expected_old_row="$3"

  if [[ ! "$line_number" =~ ^[0-9]+$ || "$line_number" -lt 1 ]]; then
    echo "ERROR: invalid line number for replace: $line_number" >&2
    return 1
  fi

  local -a lines=()
  mapfile -t lines < "$target"
  local line_count="${#lines[@]}"
  if (( line_number > line_count )); then
    echo "ERROR: replace line $line_number out of range for $target (lines: $line_count)" >&2
    return 1
  fi

  local current_row="${lines[$((line_number - 1))]}"
  if [[ "$current_row" != "$expected_old_row" ]]; then
    echo "ERROR: replace old row mismatch for $target line $line_number" >&2
    return 1
  fi
}

# Append a single row using a previously captured snapshot token.
#
# Responsibility boundary:
# - Caller captures the snapshot before validation/preview.
# - This function checks that exact snapshot before creating a backup.
# - It checks the same snapshot again immediately before atomic rename.
# - It is append-only. Replace/edit operations need a separate API that also
#   asserts the expected old line/content before rewrite.
#
# Usage: safe_append_checked <target_file> <row_tsv> <expected_size> <expected_mtime> <expected_sha256>
safe_append_checked() {
  local target="$1"
  local row="$2"
  local expected_size="$3"
  local expected_mtime="$4"
  local expected_sha256="$5"
  local base_dir
  base_dir="$(cd "$(dirname "$target")" && pwd)"
  local filename
  filename="$(basename "$target")"
  local backup_path
  backup_path="$(_choose_backup_path "$base_dir" "$filename")"

  # Stale check against the caller's pre-validation/pre-preview snapshot.
  # Do this before creating a backup so a stale write attempt has no side effects.
  if ! _safe_write_check_expected_snapshot "$target" "$expected_size" "$expected_mtime" "$expected_sha256"; then
    return 1
  fi

  # Create backup
  _create_backup "$target" "$backup_path"

  # Build proposed content: original + ensure trailing newline + row + newline
  local tmp_file
  tmp_file="$(mktemp "${target}.tmp-XXXXXX")"
  # shellcheck disable=SC2064
  trap "rm -f '$tmp_file'" EXIT

  cat "$target" > "$tmp_file"

  if [[ -s "$tmp_file" ]] && [[ "$(_safe_write_last_byte_hex "$tmp_file")" != "0a" ]]; then
    printf '\n' >> "$tmp_file"
  fi

  printf '%s\n' "$row" >> "$tmp_file"

  # Re-check immediately before rename. This closes the gap between backup and write.
  if ! _safe_write_check_expected_snapshot "$target" "$expected_size" "$expected_mtime" "$expected_sha256"; then
    return 1
  fi

  mv "$tmp_file" "$target"
  trap - EXIT

  printf 'Wrote: %s\n' "$target"
  printf 'Backup: %s\n' "$backup_path"
}

# Replace exactly one line using a previously captured snapshot token.
#
# Responsibility boundary:
# - Caller captures the snapshot before validation/preview.
# - This function checks that exact snapshot before creating a backup.
# - It asserts the expected old row at the expected 1-based line number.
# - It checks the same snapshot and old row again immediately before atomic rename.
# - It replaces one line only. It never searches for similar rows or repairs TSV.
#
# Usage: safe_replace_line_checked <target_file> <line_number> <expected_old_row> <new_row> <expected_size> <expected_mtime> <expected_sha256>
safe_replace_line_checked() {
  local target="$1"
  local line_number="$2"
  local expected_old_row="$3"
  local new_row="$4"
  local expected_size="$5"
  local expected_mtime="$6"
  local expected_sha256="$7"
  local base_dir
  base_dir="$(cd "$(dirname "$target")" && pwd)"
  local filename
  filename="$(basename "$target")"
  local backup_path
  backup_path="$(_choose_backup_path "$base_dir" "$filename")"

  # Stale and exact-row checks before backup creation: stale/no-op failures must
  # not create side effects.
  if ! _safe_write_check_expected_snapshot "$target" "$expected_size" "$expected_mtime" "$expected_sha256"; then
    return 1
  fi
  if ! _safe_write_assert_line_exact "$target" "$line_number" "$expected_old_row"; then
    return 1
  fi

  _create_backup "$target" "$backup_path"

  local -a lines=()
  mapfile -t lines < "$target"
  lines[line_number - 1]="$new_row"

  local had_final_newline=0
  if [[ -s "$target" ]] && [[ "$(_safe_write_last_byte_hex "$target")" == "0a" ]]; then
    had_final_newline=1
  fi

  local tmp_file
  tmp_file="$(mktemp "${target}.tmp-XXXXXX")"
  # shellcheck disable=SC2064
  trap "rm -f '$tmp_file'" EXIT

  local i line_count
  line_count="${#lines[@]}"
  for ((i = 0; i < line_count; i++)); do
    printf '%s' "${lines[$i]}" >> "$tmp_file"
    if (( i < line_count - 1 || had_final_newline == 1 )); then
      printf '\n' >> "$tmp_file"
    fi
  done

  # Test-only hook for simulating a concurrent edit between backup/content build
  # and final rename. This is ignored unless explicit test mode is enabled.
  if [[ "${BQN_LEDGER_TEST_MODE:-}" == "1" && -n "${SAFE_WRITE_TEST_BEFORE_REPLACE_RENAME_HOOK:-}" ]]; then
    local hook="$SAFE_WRITE_TEST_BEFORE_REPLACE_RENAME_HOOK"
    if declare -F -- "$hook" >/dev/null; then
      "$hook"
    else
      printf 'Warning: SAFE_WRITE_TEST_BEFORE_REPLACE_RENAME_HOOK is set but not a declared function: %s\n' "$hook" >&2
    fi
  fi

  # Re-check immediately before rename. This closes the gap between backup and write.
  if ! _safe_write_check_expected_snapshot "$target" "$expected_size" "$expected_mtime" "$expected_sha256"; then
    return 1
  fi
  if ! _safe_write_assert_line_exact "$target" "$line_number" "$expected_old_row"; then
    return 1
  fi

  mv "$tmp_file" "$target"
  trap - EXIT

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

# Print append preview (matches BQN editor output format).
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

  local -a cmd
  case "$mode" in
    lint)
      cmd=(bqn src_next/report.bqn "$base_dir")
      ;;
    full)
      cmd=(./tools/check.sh)
      ;;
    *)
      printf 'Post-check: skipped\n'
      return 0
      ;;
  esac

  printf 'Post-check command:'
  printf ' %q' "${cmd[@]}"
  printf '\n'

  local output
  if output=$(cd "$root_dir" && "${cmd[@]}" 2>&1); then
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
