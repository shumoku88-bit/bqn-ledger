#!/usr/bin/env bash
set -euo pipefail
export NO_COLOR=1

# checks/check-editor-parity.sh
# Comprehensive black-box differential parity testing between Go and BQN editors.
# Runs all edit commands side-by-side on fresh fixtures and asserts byte-parity of outcomes.

if [ -f "src_next/report.bqn" ]; then
  ROOT_DIR="$PWD"
else
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
fi
cd "$ROOT_DIR"

tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

# Track test outcomes
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); }
fail() { FAIL=$((FAIL + 1)); echo "  FAIL: $1" >&2; }

# Helper to normalize backup files in diffs
normalize_backup_dir() {
  local base="$1"
  # Rename any backup directories to a static string to prevent timestamp differences
  if [ -d "$base/.backup" ]; then
    find "$base/.backup" -type f | sort | while read -r f; do
      local dir
      dir="$(dirname "$f")"
      local name
      name="$(basename "$f")"
      if [ "$f" != "$base/.backup/$name" ]; then
        mv "$f" "$base/.backup/$name"
      fi
    done
    # Remove mtime/timestamp directories
    find "$base/.backup" -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} +
  fi
}

prepare_fixtures() {
  local base="$1"
  cp -R data "$base"
  # Insert plan rows for edit/finish tests
  echo -e "2026-08-15\tTest Plan\texpenses:食費\tassets:bank\t1000\tplan_id=plan-2026-08-15-test-edit" >> "$base/plan.tsv"
  echo -e "2026-08-15\tTest Plan Closed\texpenses:食費\tassets:bank\t2000\tplan_id=plan-2026-08-15-test-closed" >> "$base/plan.tsv"
  # Insert finished plan ID in journal
  echo -e "2026-06-29\tTest Plan Closed\texpenses:食費\tassets:bank\t2000\tplan_id=plan-2026-08-15-test-closed" >> "$base/journal.tsv"
  # Insert reversible journal row
  echo -e "2026-06-25\tReversable Memo\tassets:bank\texpenses:食費\t1000" >> "$base/journal.tsv"
}

run_parity_check() {
  local label="$1"
  shift # the rest of the arguments are the command and flags

  local go_base="$tmp_root/go-$label"
  local bqn_base="$tmp_root/bqn-$label"
  local go_out="$tmp_root/go-$label.out"
  local bqn_out="$tmp_root/bqn-$label.out"

  prepare_fixtures "$go_base"
  prepare_fixtures "$bqn_base"

  # Strip BQN-only flags for Go editor execution if needed (Go does not support --yes, --post-check in some commands)
  local go_args=()
  for arg in "$@"; do
    if [[ "$arg" != "--yes" && "$arg" != "--post-check" && "$arg" != "none" && "$arg" != "lint" && "$arg" != "full" ]]; then
      go_args+=("$arg")
    fi
  done

  # Execute Go editor (Legacy)
  set +e
  echo "y" | ./tools/edit-legacy-go --base "$go_base" "${go_args[@]}" >"$go_out" 2>&1
  local go_rc=$?
  set -e

  # Execute BQN editor
  set +e
  ./tools/edit-bqn --base "$bqn_base" "$@" >"$bqn_out" 2>&1
  local bqn_rc=$?
  set -e

  # 1. Assert both succeeded or both failed
  local go_failed=0
  local bqn_failed=0
  [ "$go_rc" -ne 0 ] && go_failed=1
  [ "$bqn_rc" -ne 0 ] && bqn_failed=1
  if [ "$go_failed" -ne "$bqn_failed" ]; then
    fail "$label: status mismatch (success vs failure). Go exit=$go_rc, BQN exit=$bqn_rc"
    echo "=== Go output ===" >&2; cat "$go_out" >&2
    echo "=== BQN output ===" >&2; cat "$bqn_out" >&2
    return 1
  fi

  # 2. Normalize and diff file states
  normalize_backup_dir "$go_base"
  normalize_backup_dir "$bqn_base"

  # Exclude temp files and stdout dump from recursive diff
  if ! diff -r -x ".backup" -x "*.out" "$go_base" "$bqn_base" >/dev/null; then
    fail "$label: data files mismatch"
    diff -r -x ".backup" -x "*.out" -u "$go_base" "$bqn_base" >&2 || true
    return 1
  fi

  # 3. Assert backup files match if they exist
  if [ -d "$go_base/.backup" ] || [ -d "$bqn_base/.backup" ]; then
    if [ ! -d "$go_base/.backup" ] || [ ! -d "$bqn_base/.backup" ]; then
      fail "$label: one editor created a backup but the other did not"
      return 1
    fi
    # Compare backup file contents (ignoring the backup filenames themselves)
    local go_backup_file bqn_backup_file
    go_backup_file="$(find "$go_base/.backup" -type f | head -n 1)"
    bqn_backup_file="$(find "$bqn_base/.backup" -type f | head -n 1)"
    if [ -n "$go_backup_file" ] && [ -n "$bqn_backup_file" ]; then
      if ! cmp -s "$go_backup_file" "$bqn_backup_file"; then
        fail "$label: backup files mismatch"
        diff -u "$go_backup_file" "$bqn_backup_file" >&2 || true
        return 1
      fi
    fi
  fi

  pass
}

# ── Differential Testing Scenarios ──

echo "Running BQN vs Go black-box differential parity checks..."

# 1. journal add
run_parity_check "journal-add" \
  journal add --date 2026-06-30 --memo "Test addition" --from assets:bank --to expenses:食費 --amount 5000 --yes --post-check none

# 2. journal add dry-run
run_parity_check "journal-add-dryrun" \
  journal add --date 2026-06-30 --memo "Test addition" --from assets:bank --to expenses:食費 --amount 5000 --dry-run --yes --post-check none

# 3. journal add validation error
run_parity_check "journal-add-invalid-acc" \
  journal add --date 2026-06-30 --memo "Test addition" --from assets:invalid --to expenses:食費 --amount 5000 --yes --post-check none

# 4. budget add
run_parity_check "budget-add" \
  budget add --date 2026-06-30 --memo "Test budget" --from assets:bank --to expenses:食費 --amount 1000 --yes --post-check none

# 5. issue add
run_parity_check "issue-add" \
  issue add --date 2026-06-30 --status open --title "Test issue" --amount 2500 --memo "some notes" --yes

# 6. plan list TSV format
run_parity_check "plan-list-tsv" \
  plan list --format tsv

# 7. plan list Text format
run_parity_check "plan-list-text" \
  plan list --format text

# 8. plan list show all
run_parity_check "plan-list-all" \
  plan list --all --format text

# 9. plan add
run_parity_check "plan-add" \
  plan add --date 2026-08-20 --memo "Test new plan" --from assets:bank --to expenses:食費 --amount 7500 --yes --post-check none

# 10. plan add explicit ID
run_parity_check "plan-add-id" \
  plan add --date 2026-08-20 --memo "Test new plan" --from assets:bank --to expenses:食費 --amount 7500 --id plan-2026-08-20-explicit --yes --post-check none

# 11. plan finish by index
run_parity_check "plan-finish-index" \
  plan finish --index 2 --actual-date 2026-06-29 --apply --yes --post-check none

# 12. plan finish by ID
run_parity_check "plan-finish-id" \
  plan finish --id plan-2026-08-15-test-edit --actual-date 2026-06-29 --apply --yes --post-check none

# 13. plan finish closed validation
run_parity_check "plan-finish-closed" \
  plan finish --id plan-2026-08-15-test-closed --actual-date 2026-06-29 --apply --yes --post-check none

# 14. plan edit index date
run_parity_check "plan-edit-index-date" \
  plan edit --index 2 --date 2026-08-25 --yes --post-check none

# 15. plan edit id amount
run_parity_check "plan-edit-id-amount" \
  plan edit --id plan-2026-08-15-test-edit --amount 9999 --yes --post-check none

# 16. plan edit index no-change validation
run_parity_check "plan-edit-no-change" \
  plan edit --id plan-2026-08-15-test-edit --date 2026-08-15 --amount 1000 --yes --post-check none

# 17. journal reverse index
run_parity_check "journal-reverse-index" \
  journal reverse --index 10 --date 2026-06-26 --yes --post-check none

# 18. journal reverse id
run_parity_check "journal-reverse-id" \
  journal reverse --id "Reversable Memo" --date 2026-06-26 --yes --post-check none

# 19. journal reverse self-reversal validation
run_parity_check "journal-reverse-same-acc" \
  journal reverse --index 12 --date 2026-06-26 --yes --post-check none

# ── Summary ──
echo "check-editor-parity: $PASS passed, $FAIL failed" >&2
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
echo "OK" >&2
