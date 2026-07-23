#!/usr/bin/env bash
set -euo pipefail
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
sha() { shasum -a 256 "$1" | awk '{print $1}'; }
files() { find "$1" -type f -print | sed "s#^$1/##" | LC_ALL=C sort; }
make_base() {
  local base="$1" mode="${2:-journal}"
  mkdir -p "$base"; cp fixtures/journal-legacy-entry-id-removal-boundary/before.journal "$base/actual.journal"; cp fixtures/journal-legacy-entry-id-removal-boundary/accounts.tsv "$base/accounts.tsv"
  awk -v mode="$mode" '/^ACTUAL_SOURCE=/{print "ACTUAL_SOURCE="mode;next}/^ACTUAL_JOURNAL_FILE=/{print "ACTUAL_JOURNAL_FILE=actual.journal";next}{print}' config/default_config.tsv >"$base/config.tsv"
}
backup_count() { if [[ -d "$1/.backup" ]]; then find "$1/.backup" -type f | wc -l | tr -d ' '; else echo 0; fi; }

# Dry-run and wrapper parity: exact preview fields, bytes and file list unchanged.
base="$tmp/dry"; make_base "$base"; before="$(sha "$base/actual.journal")"; files "$base" >"$tmp/files.before"
./tools/edit --base "$base" journal cleanup-apply --dry-run >"$tmp/wrapper.out"
./tools/edit-bqn --base "$base" journal cleanup-apply --dry-run >"$tmp/direct.out"
cmp -s "$tmp/wrapper.out" "$tmp/direct.out" || { echo 'FAIL: wrapper parity' >&2; exit 1; }
grep -Fqx 'Removal count: 1' "$tmp/wrapper.out"; grep -Fqx '#2 date=2026-07-10 id=entry-0123456789abcdef01234567 event-line=27 Legacy ordinary groceries' "$tmp/wrapper.out"
[[ "$(sha "$base/actual.journal")" == "$before" && "$(backup_count "$base")" == 0 ]] || { echo 'FAIL: dry-run changed data' >&2; exit 1; }
diff -u "$tmp/files.before" <(files "$base")

# Interactive cancel.
printf 'n\n' | ./tools/edit --base "$base" journal cleanup-apply >"$tmp/cancel.out"
grep -Fq 'Cancelled. No files were modified.' "$tmp/cancel.out"; [[ "$(sha "$base/actual.journal")" == "$before" && "$(backup_count "$base")" == 0 ]]

# Apply, exact one-line candidate, one backup, mandatory verifier, and lint.
./tools/edit --base "$base" journal cleanup-apply --yes >"$tmp/apply.out"
cmp -s "$base/actual.journal" fixtures/journal-legacy-entry-id-removal-boundary/after-unreferenced.journal || { echo 'FAIL: apply bytes' >&2; exit 1; }
[[ "$(backup_count "$base")" == 1 ]] || { echo 'FAIL: expected one backup' >&2; exit 1; }
backup="$(find "$base/.backup" -type f)"; [[ "$(sha "$backup")" == "$before" ]] || { echo 'FAIL: backup bytes' >&2; exit 1; }
grep -Fq 'Mandatory cleanup equivalence: OK' "$tmp/apply.out"; grep -Fq 'Post-check: OK' "$tmp/apply.out"
./tools/edit --base "$base" journal cleanup-plan --format text >"$tmp/after-plan"
grep -Fq 'removable=0' "$tmp/after-plan"; grep -Fq 'identity-free=1' "$tmp/after-plan"
bqn src_edit/journal_cleanup_verify_cmd.bqn "$backup" "$base/actual.journal" | grep -Fqx $'OK\tCLEANUP_EQUIVALENT\t5\t1'

# Idempotent second run creates no backup.
after="$(sha "$base/actual.journal")"; count="$(backup_count "$base")"
./tools/edit --base "$base" journal cleanup-apply --yes >"$tmp/noop.out"
grep -Fqx 'No removable legacy event IDs. No files were modified.' "$tmp/noop.out"; [[ "$(sha "$base/actual.journal")" == "$after" && "$(backup_count "$base")" == "$count" ]]

# Source and CLI rejection remain read-only.
tsv="$tmp/tsv"; make_base "$tsv" tsv; tsvsha="$(sha "$tsv/actual.journal")"
if ./tools/edit --base "$tsv" journal cleanup-apply --yes >"$tmp/tsv.out" 2>&1; then echo 'FAIL: TSV accepted' >&2; exit 1; fi
[[ "$(sha "$tsv/actual.journal")" == "$tsvsha" && "$(backup_count "$tsv")" == 0 ]]
invalid="$tmp/invalid"; make_base "$invalid"; printf '\nunsupported synthetic group\n' >>"$invalid/actual.journal"; invalidsha="$(sha "$invalid/actual.journal")"
if ./tools/edit --base "$invalid" journal cleanup-apply --yes >"$tmp/invalid.out" 2>&1; then echo 'FAIL: invalid Journal accepted' >&2; exit 1; fi
[[ "$(sha "$invalid/actual.journal")" == "$invalidsha" && "$(backup_count "$invalid")" == 0 ]]
for args in '--event-id x' '--index 1' '--apply' '--format text' '--unknown'; do
  set +e; ./tools/edit --base "$invalid" journal cleanup-apply $args >"$tmp/option.out" 2>&1; rc=$?; set -e
  [[ "$rc" == 2 ]] || { echo "FAIL: unsupported option rc: $args" >&2; exit 1; }
done

# Mandatory verifier and configured post-check failures restore original bytes.
for kind in verify post; do
  base="$tmp/rollback-$kind"; make_base "$base"; original="$(sha "$base/actual.journal")"
  set +e
  if [[ "$kind" == verify ]]; then BQN_LEDGER_TEST_MODE=1 EDIT_BQN_TEST_FORCE_CLEANUP_VERIFY_FAIL=1 ./tools/edit --base "$base" journal cleanup-apply --yes --post-check none >"$tmp/$kind.out" 2>&1
  else BQN_LEDGER_TEST_MODE=1 EDIT_BQN_TEST_FORCE_POST_CHECK_FAIL=1 ./tools/edit --base "$base" journal cleanup-apply --yes >"$tmp/$kind.out" 2>&1; fi
  rc=$?; set -e
  [[ "$rc" != 0 && "$(sha "$base/actual.journal")" == "$original" ]] || { echo "FAIL: $kind rollback" >&2; exit 1; }
  grep -Fq 'Rollback: restored original bytes' "$tmp/$kind.out"
done

# A later writer wins over rollback; its bytes are preserved.
base="$tmp/later"; make_base "$base"
later_writer() { printf '\nlater-writer\n' >>"$base/actual.journal"; }
export -f later_writer; export base
set +e
BQN_LEDGER_TEST_MODE=1 EDIT_BQN_TEST_FORCE_CLEANUP_VERIFY_FAIL=1 EDIT_BQN_TEST_BEFORE_POSTCHECK_ROLLBACK_HOOK=later_writer ./tools/edit --base "$base" journal cleanup-apply --yes --post-check none >"$tmp/later.out" 2>&1
rc=$?; set -e
[[ "$rc" != 0 ]] || { echo 'FAIL: later writer rollback succeeded' >&2; exit 1; }
grep -Fqx 'later-writer' "$base/actual.journal"; grep -Fq 'Rollback: refused' "$tmp/later.out"

printf 'OK edit-bqn journal cleanup-apply\n'
