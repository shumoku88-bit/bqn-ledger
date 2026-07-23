#!/usr/bin/env bash
set -euo pipefail

if [ -f "src_next/report.bqn" ]; then
  ROOT_DIR="$PWD"
else
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
fi
cd "$ROOT_DIR"

tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

sha_file() { shasum -a 256 "$1" | awk '{print $1}'; }
file_list() { find "$1" -type f -print | sed "s#^$1/##" | LC_ALL=C sort; }

make_base() {
  local base="$1" journal="$2"
  mkdir -p "$base"
  cp fixtures/journal-legacy-entry-id-removal-boundary/accounts.tsv "$base/accounts.tsv"
  cp "$journal" "$base/actual.journal"
  awk '
    /^ACTUAL_JOURNAL_FILE=/ { print "ACTUAL_JOURNAL_FILE=actual.journal"; next }
    { print }
  ' config/default_config.tsv >"$base/config.tsv"
}

snapshot() {
  local base="$1" prefix="$2"
  sha_file "$base/actual.journal" >"$prefix.journal.sha"
  sha_file "$base/accounts.tsv" >"$prefix.accounts.sha"
  sha_file "$base/config.tsv" >"$prefix.config.sha"
  file_list "$base" >"$prefix.files"
}

assert_snapshot() {
  local base="$1" prefix="$2"
  test "$(cat "$prefix.journal.sha")" = "$(sha_file "$base/actual.journal")" || { echo "FAIL: Journal bytes changed" >&2; exit 1; }
  test "$(cat "$prefix.accounts.sha")" = "$(sha_file "$base/accounts.tsv")" || { echo "FAIL: accounts bytes changed" >&2; exit 1; }
  test "$(cat "$prefix.config.sha")" = "$(sha_file "$base/config.tsv")" || { echo "FAIL: config bytes changed" >&2; exit 1; }
  diff -u "$prefix.files" <(file_list "$base") || { echo "FAIL: base file list changed" >&2; exit 1; }
  test ! -e "$base/.backup" || { echo "FAIL: cleanup-plan created .backup" >&2; exit 1; }
}

base="$tmp_root/before"
make_base "$base" fixtures/journal-legacy-entry-id-removal-boundary/before.journal
snapshot "$base" "$tmp_root/before-snapshot"

./tools/edit-bqn --base "$base" journal cleanup-plan --format tsv >"$tmp_root/plan.tsv"
assert_snapshot "$base" "$tmp_root/before-snapshot"
[ "$(wc -l <"$tmp_root/plan.tsv" | tr -d ' ')" -eq 5 ] || { echo "FAIL: expected 5 TSV rows" >&2; exit 1; }
awk -F '\t' 'NF != 10 { print "FAIL: TSV row " NR " has " NF " fields" > "/dev/stderr"; exit 1 }' "$tmp_root/plan.tsv"
expected_row=$'2\tREMOVABLE\tunreferenced-ordinary\t2026-07-10\tLegacy ordinary groceries\tentry-0123456789abcdef01234567\t27\t26\t0\t-'
grep -Fqx "$expected_row" "$tmp_root/plan.tsv" || { echo "FAIL: removable row mismatch" >&2; exit 1; }
awk -F '\t' '
  NR==1 && $2=="NOT_LEGACY" && $7==22 && $8==21 { opening=1 }
  NR==3 && $2=="REFERENCED" && $7==34 && $8==33 && $9==1 { referenced=1 }
  NR==4 && $2=="NOT_LEGACY" && $7==39 && $8==38 { companion=1 }
  NR==5 && $2=="PLAN_LINKED" && $7==46 && $8==45 && $9==0 && $10=="plan-legacy-household-001" { plan=1 }
  END { exit (opening && referenced && companion && plan) ? 0 : 1 }
' "$tmp_root/plan.tsv" || { echo "FAIL: TSV classification/order/line contract mismatch" >&2; exit 1; }
if grep -E 'stage0-line-|:0|:1|posting_id' "$tmp_root/plan.tsv"; then echo "FAIL: internal identity leaked in TSV" >&2; exit 1; fi

./tools/edit --base "$base" journal cleanup-plan --format tsv >"$tmp_root/wrapper.tsv"
cmp -s "$tmp_root/plan.tsv" "$tmp_root/wrapper.tsv" || { echo "FAIL: public wrapper output differs" >&2; exit 1; }
assert_snapshot "$base" "$tmp_root/before-snapshot"

./tools/edit-bqn --base "$base" journal cleanup-plan --format text >"$tmp_root/plan.txt"
assert_snapshot "$base" "$tmp_root/before-snapshot"
[ "$(head -n 1 "$tmp_root/plan.txt")" = "Journal legacy entry-id cleanup plan" ] || { echo "FAIL: text header mismatch" >&2; exit 1; }
grep -Fqx 'Summary total=5 removable=1 referenced=1 plan-linked=1 other-linked=0 identity-free=0 not-legacy=2' "$tmp_root/plan.txt" || { echo "FAIL: text summary mismatch" >&2; exit 1; }
[ "$(grep -c '^#[1-5] ' "$tmp_root/plan.txt")" -eq 5 ] || { echo "FAIL: text transaction count mismatch" >&2; exit 1; }
./tools/edit-bqn --base "$base" journal cleanup-plan >"$tmp_root/default.txt"
cmp -s "$tmp_root/plan.txt" "$tmp_root/default.txt" || { echo "FAIL: default format is not text" >&2; exit 1; }
assert_snapshot "$base" "$tmp_root/before-snapshot"

empty_base="$tmp_root/empty"
make_base "$empty_base" fixtures/journal-legacy-entry-id-removal-boundary/before.journal
awk '/^[0-9]{4}-[0-9]{2}-[0-9]{2} / { exit } { print }' "$empty_base/actual.journal" >"$tmp_root/empty.journal"
mv "$tmp_root/empty.journal" "$empty_base/actual.journal"
snapshot "$empty_base" "$tmp_root/empty-snapshot"
./tools/edit-bqn --base "$empty_base" journal cleanup-plan --format text >"$tmp_root/empty.txt"
grep -Fqx 'Summary total=0 removable=0 referenced=0 plan-linked=0 other-linked=0 identity-free=0 not-legacy=0' "$tmp_root/empty.txt" || { echo "FAIL: empty Journal summary mismatch" >&2; exit 1; }
assert_snapshot "$empty_base" "$tmp_root/empty-snapshot"

identity_base="$tmp_root/identity-free"
make_base "$identity_base" fixtures/journal-legacy-entry-id-removal-boundary/after-unreferenced.journal
snapshot "$identity_base" "$tmp_root/identity-snapshot"
./tools/edit-bqn --base "$identity_base" journal cleanup-plan --format tsv >"$tmp_root/identity.tsv"
awk -F '\t' 'NR==2 && $2=="IDENTITY_FREE" && $6=="-" && $7==0 && $8==26 && $9==0 { found=1 } END { exit found ? 0 : 1 }' "$tmp_root/identity.tsv" || { echo "FAIL: identity-free row mismatch" >&2; exit 1; }
! grep -q 'stage0-line-' "$tmp_root/identity.tsv" || { echo "FAIL: fallback identity leaked" >&2; exit 1; }
assert_snapshot "$identity_base" "$tmp_root/identity-snapshot"

# CLI-only errors are exit 2 and remain read-only.
for args in '--format json' '--apply' '--yes' '--dry-run' '--post-check none' '--event-id entry-0123456789abcdef01234567' '--index 1'; do
  set +e
  # shellcheck disable=SC2086
  ./tools/edit-bqn --base "$base" journal cleanup-plan $args >"$tmp_root/unsupported.out" 2>&1
  rc=$?
  set -e
  [ "$rc" -eq 2 ] || { echo "FAIL: unsupported options '$args' returned $rc" >&2; exit 1; }
  assert_snapshot "$base" "$tmp_root/before-snapshot"
done

invalid_base="$tmp_root/invalid"
make_base "$invalid_base" fixtures/journal-legacy-entry-id-removal-boundary/before.journal
printf '\nunsupported synthetic group\n' >>"$invalid_base/actual.journal"
snapshot "$invalid_base" "$tmp_root/invalid-snapshot"
set +e
./tools/edit-bqn --base "$invalid_base" journal cleanup-plan --format tsv >"$tmp_root/invalid.out" 2>&1
rc=$?
set -e
[ "$rc" -ne 0 ] || { echo "FAIL: invalid Journal unexpectedly accepted" >&2; exit 1; }
grep -q $'^ERROR\tjournal_invalid\t' "$tmp_root/invalid.out" || { echo "FAIL: invalid Journal protocol mismatch" >&2; exit 1; }
! grep -q $'\tREMOVABLE\t' "$tmp_root/invalid.out" || { echo "FAIL: partial cleanup rows emitted" >&2; exit 1; }
assert_snapshot "$invalid_base" "$tmp_root/invalid-snapshot"

printf 'OK edit-bqn journal cleanup-plan contract\n'
