#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
unset LEDGER_DATA_DIR

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
sha() { shasum -a 256 "$1" | awk '{print $1}'; }
make_base() {
  local name="$1" base
  base="$tmp/$name"; mkdir "$base"
  printf '%s\n' \
    $'assets:jpy\trole=asset\tcurrency=JPY' $'expenses:jpy\trole=expense\tcurrency=JPY' \
    $'assets:ils\trole=asset\tcurrency=ILS' $'expenses:ils\trole=expense\tcurrency=ILS' > "$base/accounts.tsv"
  : > "$base/journal.tsv"; printf '%s' "$base"
}
add_jpy() { tools/edit --base "$1" journal add --date 2026-07-21 --memo jpy --from assets:jpy --to expenses:jpy --amount 100 --currency JPY --yes --post-check lint; }
add_ils() { tools/edit --base "$1" journal add --date 2026-07-20 --memo ils --from assets:ils --to expenses:ils --amount 42.50 --currency ILS --yes --post-check lint; }

# Valid single and mixed orders all use journal source lint, never full report.
base="$(make_base jpy-only)"; add_jpy "$base" >"$tmp/jpy-only.out"; grep -Fq 'journal_source_check.bqn' "$tmp/jpy-only.out"
base="$(make_base ils-only)"; add_ils "$base" >"$tmp/ils-only.out"
base="$(make_base ils-jpy)"; add_ils "$base" >/dev/null; add_jpy "$base" >/dev/null; [[ "$(wc -l < "$base/journal.tsv" | tr -d ' ')" == 2 ]]
base="$(make_base jpy-ils)"; add_jpy "$base" >/dev/null; add_ils "$base" >/dev/null
base="$(make_base many)"; add_jpy "$base" >/dev/null; add_ils "$base" >/dev/null; add_jpy "$base" >/dev/null; add_ils "$base" >/dev/null; [[ "$(wc -l < "$base/journal.tsv" | tr -d ' ')" == 4 ]]
base="$(make_base legacy-ils)"; printf '%s\n' $'2026-07-19\tlegacy\tassets:jpy\texpenses:jpy\t50' > "$base/journal.tsv"; add_ils "$base" >/dev/null

# Existing malformed source is detected after append and restored byte-exactly.
expect_postcheck_rollback() {
  local label="$1" bad_row="$2" base before rc out
  base="$(make_base "bad-$label")"; printf '%s\n' "$bad_row" > "$base/journal.tsv"
  before="$(sha "$base/journal.tsv")"; out="$tmp/bad-$label.out"
  set +e; add_jpy "$base" >"$out" 2>&1; rc=$?; set -e
  [[ "$rc" -ne 0 ]] || { echo "FAIL: $label unexpectedly succeeded" >&2; exit 1; }
  [[ "$before" == "$(sha "$base/journal.tsv")" ]] || { echo "FAIL: $label rollback bytes differ" >&2; exit 1; }
  grep -Fq 'Post-check failed.' "$out"
  grep -Fq 'Rollback: restored original bytes' "$out"
  grep -Fq 'Backup:' "$out"
  ! grep -Fq $'\tjpy\tassets:jpy\texpenses:jpy\t100\t' "$base/journal.tsv"
}
expect_postcheck_rollback unknown $'2026-07-19\tbad\tassets:missing\texpenses:jpy\t1\tcurrency=JPY'
expect_postcheck_rollback mismatch $'2026-07-19\tbad\tassets:jpy\texpenses:ils\t1\tcurrency=JPY'
expect_postcheck_rollback unsupported $'2026-07-19\tbad\tassets:jpy\texpenses:jpy\t1\tcurrency=USD'
expect_postcheck_rollback duplicate $'2026-07-19\tbad\tassets:jpy\texpenses:jpy\t1\tcurrency=JPY\tcurrency=JPY'
expect_postcheck_rollback amount $'2026-07-19\tbad\tassets:jpy\texpenses:jpy\t1x\tcurrency=JPY'
expect_postcheck_rollback precision $'2026-07-19\tbad\tassets:ils\texpenses:ils\t1.001\tcurrency=ILS'
expect_postcheck_rollback columns $'2026-07-19\tbroken'
expect_postcheck_rollback date $'2026-02-30\tbad\tassets:jpy\texpenses:jpy\t1\tcurrency=JPY'

# Injected failure also restores original digest and retains backup evidence.
base="$(make_base injected)"; printf '%s\n' '# original' > "$base/journal.tsv"; original="$(sha "$base/journal.tsv")"
set +e
BQN_LEDGER_TEST_MODE=1 EDIT_BQN_TEST_FORCE_POST_CHECK_FAIL=1 add_jpy "$base" >"$tmp/injected.out" 2>&1; rc=$?
set -e
[[ "$rc" -ne 0 && "$original" == "$(sha "$base/journal.tsv")" ]]
grep -Fq 'Rollback: restored original bytes' "$tmp/injected.out"
backup="$(awk -F': ' '$1=="Backup" {print $2}' "$tmp/injected.out" | tail -n1)"; [[ -f "$backup" ]]

# A later writer mutation makes checked rollback refuse recovery.
base="$(make_base concurrent)"; printf '%s\n' '# original' > "$base/journal.tsv"; original="$(sha "$base/journal.tsv")"
after_failure_mutation() { printf '%s\n' '# later writer' >> "$JOURNAL_ROLLBACK_TARGET"; }
export -f after_failure_mutation
set +e
BQN_LEDGER_TEST_MODE=1 EDIT_BQN_TEST_FORCE_POST_CHECK_FAIL=1 EDIT_BQN_TEST_BEFORE_POSTCHECK_ROLLBACK_HOOK=after_failure_mutation JOURNAL_ROLLBACK_TARGET="$base/journal.tsv" add_jpy "$base" >"$tmp/concurrent.out" 2>&1; rc=$?
set -e
[[ "$rc" -ne 0 && "$original" != "$(sha "$base/journal.tsv")" ]]
tail -n1 "$base/journal.tsv" | grep -Fxq '# later writer'
grep -Fq 'Rollback: refused; target changed after append; recovery required' "$tmp/concurrent.out"
backup="$(awk -F': ' '$1=="Backup" {print $2}' "$tmp/concurrent.out" | tail -n1)"; [[ -f "$backup" ]]

printf 'OK: mixed-currency journal source lint and checked rollback passed\n'
