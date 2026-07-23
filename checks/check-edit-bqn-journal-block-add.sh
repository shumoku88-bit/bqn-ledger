#!/usr/bin/env bash
set -euo pipefail

if [[ -f src_next/report.bqn ]]; then ROOT_DIR=$PWD; else ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd); fi
cd "$ROOT_DIR"
tmp_root=$(mktemp -d)
trap 'rm -rf "$tmp_root"' EXIT
fixture=fixtures/journal-native-multi-posting-editor

sha_file() { shasum -a 256 "$1" | awk '{print $1}'; }
new_base() { local name=$1; local base="$tmp_root/$name"; mkdir -p "$base"; cp "$fixture"/* "$base/"; printf '%s\n' "$base"; }
assert_no_backups() { local base=$1 label=$2; if find "$base" -type f -path '*/.backup/*' | grep -q .; then echo "FAIL: $label created backup" >&2; find "$base" -type f -path '*/.backup/*' >&2; exit 1; fi; }
base_args() {
  printf '%s\0' journal-block add --journal-file source.journal --date 2026-07-22 --description スーパー --event-id purchase-20260722-001 \
    --posting expenses:food:daily=1200 --posting expenses:household=500 --posting assets:cash=-1700
}
run_ok() { local base=$1 out=$2; shift 2; ./tools/edit --base "$base" "$@" >"$out" 2>&1; }
run_fail() { local base=$1 out=$2; shift 2; set +e; ./tools/edit --base "$base" "$@" >"$out" 2>&1; local rc=$?; set -e; [[ $rc -ne 0 ]] || { echo "FAIL: expected rejection: $out" >&2; cat "$out" >&2; exit 1; }; }
assert_rejected_unchanged() {
  local label=$1 base=$2 before=$3 out=$4; shift 4
  run_fail "$base" "$out" "$@"
  [[ $(sha_file "$base/source.journal") == "$before" ]] || { echo "FAIL: $label changed source.journal" >&2; exit 1; }
  assert_no_backups "$base" "$label"
}

# Exact dry-run preview, with the transport separator intentionally absent.
dry=$(new_base dry); dry_before=$(sha_file "$dry/source.journal"); dry_out="$tmp_root/dry.out"
mapfile -d '' -t args < <(base_args)
run_ok "$dry" "$dry_out" "${args[@]}" --dry-run
cat >"$tmp_root/dry.expected" <<EOF
Native Journal block append preview
Target: $(cd -P "$dry" && pwd)/source.journal
Mode: dry-run
Post-check: lint
Candidate block:
2026-07-22 * スーパー
    ; event-id: purchase-20260722-001
    expenses:food:daily    1200 JPY
    expenses:household    500 JPY
    assets:cash    -1700 JPY
Dry-run only. No files were modified.
EOF
cmp "$tmp_root/dry.expected" "$dry_out"
[[ $(sha_file "$dry/source.journal") == "$dry_before" ]]
assert_no_backups "$dry" dry-run

# Explicit user metadata preservation case
exp_base=$(new_base explicit-meta); exp_out="$tmp_root/explicit-meta.out"
exp_args=(journal-block add --journal-file source.journal --date 2026-07-22 --description explicit-metadata --event-id explicit-metadata-001 --posting expenses:food:daily=1 --posting assets:cash=-1 --meta currency=JPY --meta note=explicit --dry-run)
run_ok "$exp_base" "$exp_out" "${exp_args[@]}"
cat >"$tmp_root/explicit-meta.expected" <<EOF
Native Journal block append preview
Target: $(cd -P "$exp_base" && pwd)/source.journal
Mode: dry-run
Post-check: lint
Candidate block:
2026-07-22 * explicit-metadata
    ; event-id: explicit-metadata-001
    ; currency: JPY
    ; note: explicit
    expenses:food:daily    1 JPY
    assets:cash    -1 JPY
Dry-run only. No files were modified.
EOF
cmp "$tmp_root/explicit-meta.expected" "$exp_out"

# Ordinary dry-run omits all automatic transaction metadata and preserves source bytes.
ordinary_dry=$(new_base ordinary-dry); ordinary_dry_before=$(sha_file "$ordinary_dry/source.journal"); ordinary_dry_out="$tmp_root/ordinary-dry.out"
ordinary_dry_args=(journal-block add --identity ordinary --journal-file source.journal --date 2026-07-22 --description ordinary-dry-run --posting expenses:food:daily=1 --posting assets:cash=-1 --dry-run)
run_ok "$ordinary_dry" "$ordinary_dry_out" "${ordinary_dry_args[@]}"
cat >"$tmp_root/ordinary-dry.expected" <<EOF
Native Journal block append preview
Target: $(cd -P "$ordinary_dry" && pwd)/source.journal
Mode: dry-run
Post-check: lint
Candidate block:
2026-07-22 * ordinary-dry-run
    expenses:food:daily    1 JPY
    assets:cash    -1 JPY
Dry-run only. No files were modified.
EOF
cmp "$tmp_root/ordinary-dry.expected" "$ordinary_dry_out"
[[ $(sha_file "$ordinary_dry/source.journal") == "$ordinary_dry_before" ]]
assert_no_backups "$ordinary_dry" ordinary-dry-run
! grep -Fq '; event-id:' "$ordinary_dry_out"
! grep -Fq '; layer: actual' "$ordinary_dry_out"
! grep -Fq '; currency: JPY' "$ordinary_dry_out"

# Ordinary append retains explicit metadata but remains identity-free.
ordinary=$(new_base ordinary-append); ordinary_before_events=$(grep -Fc '; event-id:' "$ordinary/source.journal" || true); ordinary_out="$tmp_root/ordinary-append.out"
run_ok "$ordinary" "$ordinary_out" journal-block add --identity ordinary --journal-file source.journal --date 2026-07-22 --description ordinary-append \
  --posting expenses:food:daily=1 --posting assets:cash=-1 --meta note=explicit --meta currency=JPY --yes --post-check none
ordinary_after_events=$(grep -Fc '; event-id:' "$ordinary/source.journal" || true)
[[ "$ordinary_after_events" -eq "$ordinary_before_events" ]]
grep -Fq '2026-07-22 * ordinary-append' "$ordinary/source.journal"
grep -Fq '    ; note: explicit' "$ordinary/source.journal"
grep -Fq '    ; currency: JPY' "$ordinary/source.journal"
grep -Fq 'Mandatory native validation: OK' "$ordinary_out"
grep -Fq $'OK\tNATIVE_JOURNAL_CANDIDATE\tordinary\t-\t1\t2' "$ordinary_out"

# Exact bytes for all three source endings. The completed bytes must converge.
expected_block='2026-07-22 * スーパー
    ; event-id: purchase-20260722-001
    expenses:food:daily    1200 JPY
    expenses:household    500 JPY
    assets:cash    -1700 JPY'
reference_sha=""
for ending in no-final-newline one-final-newline paragraph-separator; do
  base=$(new_base "ending-$ending")
  case "$ending" in
    no-final-newline) perl -0pi -e 's/\n\z//' "$base/source.journal" ;;
    one-final-newline) : ;;
    paragraph-separator) printf '\n' >>"$base/source.journal" ;;
  esac
  original="$tmp_root/$ending.original"; cp "$base/source.journal" "$original"
  case "$ending" in
    no-final-newline) sep=$'\n\n' ;;
    one-final-newline) sep=$'\n' ;;
    paragraph-separator) sep='' ;;
  esac
  before_layer_count=$(grep -Fc '; layer: actual' "$original" || true)
  before_currency_count=$(grep -Fc '; currency: JPY' "$original" || true)
  { cat "$original"; printf '%s' "$sep"; printf '%s\n' "$expected_block"; } >"$tmp_root/$ending.expected"
  run_ok "$base" "$tmp_root/$ending.out" "${args[@]}" --yes --post-check none
  cmp "$tmp_root/$ending.expected" "$base/source.journal"
  grep -Fq 'Mandatory native validation: OK' "$tmp_root/$ending.out"
  after_layer_count=$(grep -Fc '; layer: actual' "$base/source.journal" || true)
  after_currency_count=$(grep -Fc '; currency: JPY' "$base/source.journal" || true)
  [[ "$after_layer_count" -eq "$before_layer_count" ]]
  [[ "$after_currency_count" -eq "$before_currency_count" ]]
  count=$(grep -Fc '; event-id: purchase-20260722-001' "$base/source.journal")
  [[ $count -eq 1 ]]
  current=$(sha_file "$base/source.journal"); [[ -z "$reference_sha" || "$reference_sha" == "$current" ]]; reference_sha=$current
done

# Nested relative target is accepted and retains exact posting order.
nested=$(new_base nested); mkdir "$nested/sub"; mv "$nested/source.journal" "$nested/sub/native.journal"
nested_args=(journal-block add --journal-file sub/native.journal --date 2026-07-22 --description スーパー --event-id purchase-nested-001 --posting expenses:food:daily=1200 --posting expenses:household=500 --posting assets:cash=-1700 --yes)
run_ok "$nested" "$tmp_root/nested.out" "${nested_args[@]}"
grep -Fq 'OK' "$tmp_root/nested.out"
tail -n 3 "$nested/sub/native.journal" >"$tmp_root/nested.tail"
printf '%s\n' '    expenses:food:daily    1200 JPY' '    expenses:household    500 JPY' '    assets:cash    -1700 JPY' >"$tmp_root/nested.expected"
cmp "$tmp_root/nested.expected" "$tmp_root/nested.tail"

# Routed multi-add selects the configured native Journal without exposing file routing to the UI.
routed=$(new_base routed)
awk '
  /^ACTUAL_SOURCE=/ {print "ACTUAL_SOURCE=journal"; next}
  /^ACTUAL_JOURNAL_FILE=/ {print "ACTUAL_JOURNAL_FILE=source.journal"; next}
  {print}
  END {print "DEFAULT_CURRENCY=JPY"}
' config/default_config.tsv >"$routed/config.tsv"
routed_before=$(sha_file "$routed/source.journal")
routed_before_events=$(grep -Fc '; event-id:' "$routed/source.journal" || true)
run_ok "$routed" "$tmp_root/routed.out" journal multi-add --date 2026-07-22 --description routed-split \
  --posting expenses:food:daily=1200 --posting expenses:household=500 --posting assets:cash=-1700 --yes --post-check none
[[ $(sha_file "$routed/source.journal") != "$routed_before" ]]
grep -Fq '2026-07-22 * routed-split' "$routed/source.journal"
tail -n 3 "$routed/source.journal" >"$tmp_root/routed.tail"
printf '%s\n' '    expenses:food:daily    1200 JPY' '    expenses:household    500 JPY' '    assets:cash    -1700 JPY' >"$tmp_root/routed.expected"
cmp "$tmp_root/routed.expected" "$tmp_root/routed.tail"
grep -Fq 'Mandatory native validation: OK' "$tmp_root/routed.out"
grep -Fq $'OK\tNATIVE_JOURNAL_CANDIDATE\tordinary\t-' "$tmp_root/routed.out"
[[ $(grep -Fc '; event-id:' "$routed/source.journal" || true) -eq "$routed_before_events" ]]
! grep -Fq 'entry-' "$tmp_root/routed.out"
! grep -Fq 'entry-' "$routed/source.journal"
! grep -Fq 'stage0-line-' "$tmp_root/routed.out"

# TSV mode cannot flatten native multi-posting and must fail without writes.
tsv_multi="$tmp_root/tsv-multi"; cp -R data "$tsv_multi"; tsv_multi_before=$(sha_file "$tsv_multi/journal.tsv")
run_fail "$tsv_multi" "$tmp_root/tsv-multi.out" journal multi-add --date 2026-06-29 --description rejected \
  --posting expenses:食費=123 --posting assets:bank=-123 --yes
[[ $(sha_file "$tsv_multi/journal.tsv") == "$tsv_multi_before" ]]
grep -Fq 'journal multi-add requires ACTUAL_SOURCE=journal; no files changed' "$tmp_root/tsv-multi.out"
assert_no_backups "$tsv_multi" tsv-multi

# Existing TSV journal add remains the from/to/amount writer.
tsv="$tmp_root/tsv"; cp -R data "$tsv"; tsv_before=$(wc -l <"$tsv/journal.tsv")
./tools/edit --base "$tsv" journal add --date 2026-06-29 --memo native-boundary-regression --from assets:bank --to expenses:食費 --amount 123 --yes --post-check none >"$tmp_root/tsv.out" 2>&1
[[ $(wc -l <"$tsv/journal.tsv") -eq $((tsv_before + 1)) ]]
tail -n 1 "$tsv/journal.tsv" | grep -Fq $'2026-06-29\tnative-boundary-regression\tassets:bank\texpenses:食費\t123'

# Path rejection cases.
base=$(new_base path); before=$(sha_file "$base/source.journal")
assert_rejected_unchanged missing-journal-file "$base" "$before" "$tmp_root/missing-option.out" journal-block add --date 2026-07-22 --description x --event-id x --posting assets:cash=-1 --posting expenses:food:daily=1
assert_rejected_unchanged absolute "$base" "$before" "$tmp_root/absolute.out" journal-block add --journal-file "$base/source.journal" --date 2026-07-22 --description x --event-id x --posting assets:cash=-1 --posting expenses:food:daily=1
assert_rejected_unchanged traversal "$base" "$before" "$tmp_root/traversal.out" journal-block add --journal-file ../outside.journal --date 2026-07-22 --description x --event-id x --posting assets:cash=-1 --posting expenses:food:daily=1
assert_rejected_unchanged suffix "$base" "$before" "$tmp_root/suffix.out" journal-block add --journal-file source.txt --date 2026-07-22 --description x --event-id x --posting assets:cash=-1 --posting expenses:food:daily=1
assert_rejected_unchanged missing-target "$base" "$before" "$tmp_root/missing-target.out" journal-block add --journal-file missing.journal --date 2026-07-22 --description x --event-id x --posting assets:cash=-1 --posting expenses:food:daily=1
mkdir "$base/directory.journal"
assert_rejected_unchanged directory "$base" "$before" "$tmp_root/directory.out" journal-block add --journal-file directory.journal --date 2026-07-22 --description x --event-id x --posting assets:cash=-1 --posting expenses:food:daily=1
assert_rejected_unchanged journal-tsv "$base" "$before" "$tmp_root/journal-tsv.out" journal-block add --journal-file journal.tsv --date 2026-07-22 --description x --event-id x --posting assets:cash=-1 --posting expenses:food:daily=1
outside="$tmp_root/outside.journal"; cp "$base/source.journal" "$outside"; ln -s "$outside" "$base/escape.journal"
assert_rejected_unchanged symlink "$base" "$before" "$tmp_root/symlink.out" journal-block add --journal-file escape.journal --date 2026-07-22 --description x --event-id x --posting assets:cash=-1 --posting expenses:food:daily=1
mkdir "$base/link-target"; cp "$base/source.journal" "$base/link-target/deep.journal"; ln -s "$tmp_root" "$base/outside-link"
assert_rejected_unchanged canonical-outside "$base" "$before" "$tmp_root/canonical.out" journal-block add --journal-file outside-link/outside.journal --date 2026-07-22 --description x --event-id x --posting assets:cash=-1 --posting expenses:food:daily=1

# Semantic rejection helper: every prepared base remains byte-identical and backup-free.
noop_setup() { :; }
run_semantic_case() { local name=$1 setup=$2; shift 2; local base; base=$(new_base "reject-$name"); "$setup" "$base"; local before=$(sha_file "$base/source.journal"); assert_rejected_unchanged "$name" "$base" "$before" "$tmp_root/$name.out" "$@"; }
common_prefix=(journal-block add --journal-file source.journal)
run_semantic_case invalid-date noop_setup "${common_prefix[@]}" --date 2026-02-30 --description x --event-id new-id --posting expenses:food:daily=1 --posting assets:cash=-1
run_semantic_case blank-description noop_setup "${common_prefix[@]}" --date 2026-07-22 --description '   ' --event-id new-id --posting expenses:food:daily=1 --posting assets:cash=-1
run_semantic_case description-lf noop_setup "${common_prefix[@]}" --date 2026-07-22 --description $'bad\ninjection' --event-id new-id --posting expenses:food:daily=1 --posting assets:cash=-1
run_semantic_case missing-event noop_setup "${common_prefix[@]}" --date 2026-07-22 --description x --posting expenses:food:daily=1 --posting assets:cash=-1
run_semantic_case empty-event noop_setup "${common_prefix[@]}" --date 2026-07-22 --description x --event-id '' --posting expenses:food:daily=1 --posting assets:cash=-1
run_semantic_case invalid-identity noop_setup "${common_prefix[@]}" --identity invalid --date 2026-07-22 --description x --event-id new-id --posting expenses:food:daily=1 --posting assets:cash=-1
run_semantic_case ordinary-event noop_setup "${common_prefix[@]}" --identity ordinary --date 2026-07-22 --description x --event-id new-id --posting expenses:food:daily=1 --posting assets:cash=-1
run_semantic_case ordinary-plan-link noop_setup "${common_prefix[@]}" --identity ordinary --date 2026-07-22 --description x --posting expenses:food:daily=1 --posting assets:cash=-1 --meta plan_id=plan-x
run_semantic_case unsafe-event noop_setup "${common_prefix[@]}" --date 2026-07-22 --description x --event-id $'bad\rid' --posting expenses:food:daily=1 --posting assets:cash=-1
run_semantic_case duplicate-event noop_setup "${common_prefix[@]}" --date 2026-07-22 --description x --event-id opening-20260701-001 --posting expenses:food:daily=1 --posting assets:cash=-1
run_semantic_case one-posting noop_setup "${common_prefix[@]}" --date 2026-07-22 --description x --event-id new-id --posting assets:cash=-1
run_semantic_case malformed-posting noop_setup "${common_prefix[@]}" --date 2026-07-22 --description x --event-id new-id --posting expenses:food:daily=1=2 --posting assets:cash=-1
run_semantic_case implicit-posting noop_setup "${common_prefix[@]}" --date 2026-07-22 --description x --event-id new-id --posting expenses:food:daily= --posting assets:cash=-1
run_semantic_case zero-posting noop_setup "${common_prefix[@]}" --date 2026-07-22 --description x --event-id new-id --posting expenses:food:daily=0 --posting assets:cash=0
run_semantic_case decimal-posting noop_setup "${common_prefix[@]}" --date 2026-07-22 --description x --event-id new-id --posting expenses:food:daily=1.5 --posting assets:cash=-1
run_semantic_case noninteger-posting noop_setup "${common_prefix[@]}" --date 2026-07-22 --description x --event-id new-id --posting expenses:food:daily=abc --posting assets:cash=-1
run_semantic_case unbalanced noop_setup "${common_prefix[@]}" --date 2026-07-22 --description x --event-id new-id --posting expenses:food:daily=2 --posting assets:cash=-1
setup_registry_only() { printf '%s\n' $'expenses:registry-only\trole=expense\tcurrency=JPY' >>"$1/accounts.tsv"; }
run_semantic_case undeclared-account setup_registry_only "${common_prefix[@]}" --date 2026-07-22 --description x --event-id new-id --posting expenses:registry-only=1 --posting assets:cash=-1
setup_declared_missing_registry() { printf '\naccount expenses:declared-only\n    ; role: expense\n' >>"$1/source.journal"; }
run_semantic_case missing-registry setup_declared_missing_registry "${common_prefix[@]}" --date 2026-07-22 --description x --event-id new-id --posting expenses:declared-only=1 --posting assets:cash=-1
setup_usd() { printf '%s\n' $'expenses:usd\trole=expense\tcurrency=USD' >>"$1/accounts.tsv"; printf '\naccount expenses:usd\n    ; role: expense\n' >>"$1/source.journal"; }
run_semantic_case non-jpy setup_usd "${common_prefix[@]}" --date 2026-07-22 --description x --event-id new-id --posting expenses:usd=1 --posting assets:cash=-1
setup_missing_commodity() { perl -0pi -e 's/commodity JPY/; commodity removed/' "$1/source.journal"; }
run_semantic_case missing-commodity setup_missing_commodity "${common_prefix[@]}" --date 2026-07-22 --description x --event-id new-id --posting expenses:food:daily=1 --posting assets:cash=-1
setup_incompatible_commodity() { perl -0pi -e 's/commodity JPY/commodity USD/g; s/ JPY/ USD/g' "$1/source.journal"; }
run_semantic_case incompatible-commodity setup_incompatible_commodity "${common_prefix[@]}" --date 2026-07-22 --description x --event-id new-id --posting expenses:food:daily=1 --posting assets:cash=-1
setup_malformed() { printf '\ninclude unsupported.journal\n' >>"$1/source.journal"; }
run_semantic_case malformed-existing setup_malformed "${common_prefix[@]}" --date 2026-07-22 --description x --event-id new-id --posting expenses:food:daily=1 --posting assets:cash=-1
grep -Fq 'ERROR: --identity must be ordinary or durable' "$tmp_root/invalid-identity.out"
grep -Fq 'ERROR: --event-id must not be supplied for ordinary Journal actuals' "$tmp_root/ordinary-event.out"
grep -Fq 'ERROR: missing required option: --event-id' "$tmp_root/missing-event.out"
grep -Fq 'ERROR: missing required option: --event-id' "$tmp_root/empty-event.out"
grep -Fq $'ERROR\tordinary_plan_link_invalid' "$tmp_root/ordinary-plan-link.out"

# Cancellation has no backup or write.
cancel=$(new_base cancel); before=$(sha_file "$cancel/source.journal")
printf 'n\n' | ./tools/edit --base "$cancel" "${args[@]}" >"$tmp_root/cancel.out" 2>&1
[[ $(sha_file "$cancel/source.journal") == "$before" ]]; assert_no_backups "$cancel" cancellation
grep -Fq 'Cancelled. No files were modified.' "$tmp_root/cancel.out"

# Stale before helper and immediately before rename preserve concurrent bytes and do not publish candidate.
stale=$(new_base stale-before); stale_target="$stale/source.journal"
stale_hook() { printf '%s\n' '; concurrent-before-append' >>"$STALE_TARGET"; }
export -f stale_hook; export STALE_TARGET="$stale_target"
set +e
BQN_LEDGER_TEST_MODE=1 EDIT_BQN_TEST_BEFORE_JOURNAL_BLOCK_APPEND_HOOK=stale_hook ./tools/edit --base "$stale" "${args[@]}" --yes >"$tmp_root/stale-before.out" 2>&1
rc=$?
set -e
[[ $rc -ne 0 ]]; ! grep -Fq 'purchase-20260722-001' "$stale_target"; tail -n 1 "$stale_target" | grep -Fxq '; concurrent-before-append'; assert_no_backups "$stale" stale-before-append

rename_stale=$(new_base stale-rename); export STALE_TARGET="$rename_stale/source.journal"
set +e
BQN_LEDGER_TEST_MODE=1 SAFE_WRITE_TEST_BEFORE_APPEND_RENAME_HOOK=stale_hook ./tools/edit --base "$rename_stale" "${args[@]}" --yes >"$tmp_root/stale-rename.out" 2>&1
rc=$?
set -e
[[ $rc -ne 0 ]]; ! grep -Fq 'purchase-20260722-001' "$STALE_TARGET"; tail -n 1 "$STALE_TARGET" | grep -Fxq '; concurrent-before-append'; assert_no_backups "$rename_stale" stale-before-rename

# Forced mandatory failure restores the exact original and leaves backup evidence.
rollback=$(new_base rollback); rollback_before=$(sha_file "$rollback/source.journal")
set +e
BQN_LEDGER_TEST_MODE=1 EDIT_BQN_TEST_FORCE_NATIVE_POST_CHECK_FAIL=1 ./tools/edit --base "$rollback" "${args[@]}" --yes >"$tmp_root/rollback.out" 2>&1
rc=$?
set -e
[[ $rc -ne 0 && $(sha_file "$rollback/source.journal") == "$rollback_before" ]]
! grep -Fq 'purchase-20260722-001' "$rollback/source.journal"
find "$rollback" -type f -path '*/.backup/*' | grep -q .
grep -Fq 'Rollback: restored original bytes' "$tmp_root/rollback.out"

# A later writer defeats the digest guard; its bytes are preserved and recovery is required.
later=$(new_base later-writer); export LATER_TARGET="$later/source.journal"
later_hook() { printf '%s\n' '; later-writer-preserved' >>"$LATER_TARGET"; }
export -f later_hook
set +e
BQN_LEDGER_TEST_MODE=1 EDIT_BQN_TEST_FORCE_NATIVE_POST_CHECK_FAIL=1 EDIT_BQN_TEST_BEFORE_POSTCHECK_ROLLBACK_HOOK=later_hook ./tools/edit --base "$later" "${args[@]}" --yes >"$tmp_root/later.out" 2>&1
rc=$?
set -e
[[ $rc -ne 0 ]]; tail -n 1 "$later/source.journal" | grep -Fxq '; later-writer-preserved'
grep -Fq 'purchase-20260722-001' "$later/source.journal"
grep -Fq 'Rollback: refused; target changed after append; recovery required' "$tmp_root/later.out"

# none and lint always run mandatory native validation.
for mode in none lint; do
  mode_base=$(new_base "mode-$mode")
  run_ok "$mode_base" "$tmp_root/mode-$mode.out" "${args[@]}" --yes --post-check "$mode"
  grep -Fq 'Mandatory native validation: OK' "$tmp_root/mode-$mode.out"
done

# Full runs mandatory validation first, then a deterministic test-only full-check seam.
full=$(new_base mode-full); export FULL_MARKER="$tmp_root/full.marker"
full_hook() { printf 'ran\n' >"$FULL_MARKER"; }
export -f full_hook
BQN_LEDGER_TEST_MODE=1 EDIT_BQN_JOURNAL_BLOCK_FULL_CHECK_HOOK=full_hook ./tools/edit --base "$full" "${args[@]}" --yes --post-check full >"$tmp_root/full.out" 2>&1
grep -Fq 'Mandatory native validation: OK' "$tmp_root/full.out"
grep -Fq 'Additional full check: starting' "$tmp_root/full.out"
[[ -f "$FULL_MARKER" ]]

# A selected additional full-check failure uses the same guarded rollback.
full_fail=$(new_base mode-full-fail); full_fail_before=$(sha_file "$full_fail/source.journal")
full_fail_hook() { return 1; }
export -f full_fail_hook
set +e
BQN_LEDGER_TEST_MODE=1 EDIT_BQN_JOURNAL_BLOCK_FULL_CHECK_HOOK=full_fail_hook ./tools/edit --base "$full_fail" "${args[@]}" --yes --post-check full >"$tmp_root/full-fail.out" 2>&1
rc=$?
set -e
[[ $rc -ne 0 && $(sha_file "$full_fail/source.journal") == "$full_fail_before" ]]
grep -Fq 'Rollback: restored original bytes' "$tmp_root/full-fail.out"

# Native validation failure prevents the optional full check and rolls back.
blocked=$(new_base mode-full-blocked); export FULL_MARKER="$tmp_root/full-blocked.marker"; rm -f "$FULL_MARKER"
set +e
BQN_LEDGER_TEST_MODE=1 EDIT_BQN_TEST_FORCE_NATIVE_POST_CHECK_FAIL=1 EDIT_BQN_JOURNAL_BLOCK_FULL_CHECK_HOOK=full_hook ./tools/edit --base "$blocked" "${args[@]}" --yes --post-check full >"$tmp_root/full-blocked.out" 2>&1
rc=$?
set -e
[[ $rc -ne 0 && ! -e "$FULL_MARKER" ]]
! grep -Fq 'Additional full check: starting' "$tmp_root/full-blocked.out"
grep -Fq 'Rollback: restored original bytes' "$tmp_root/full-blocked.out"

# Renderer protocol ordinal
echo "Checking renderer protocol ordinal..." >&2
protocol_out="$tmp_root/protocol.out"
bqn src_edit/journal_block_add_cmd.bqn "$dry" "$dry/source.journal" 2026-07-22 スーパー durable purchase-20260722-001 3 expenses:food:daily=1200 expenses:household=500 assets:cash=-1700 >"$protocol_out" 2>"$tmp_root/protocol.err"
first_line=$(head -n 1 "$protocol_out" | tr -d '\r')
IFS=$'\t' read -r p_status p_op p_prefix p_identity p_event p_count p_ordinal p_extra <<< "$first_line"
[[ "$p_status" == "OK" && "$p_op" == "APPEND_BLOCK" && "$p_identity" == "durable" && "$p_event" == "purchase-20260722-001" && "$p_count" == "3" && "$p_ordinal" == "1" && -z "${p_extra:-}" ]] || { echo "FAIL renderer protocol header: line='$first_line'" >&2; exit 1; }
ordinary_protocol_out="$tmp_root/ordinary-protocol.out"
bqn src_edit/journal_block_add_cmd.bqn "$ordinary_dry" "$ordinary_dry/source.journal" 2026-07-22 ordinary-protocol ordinary '' 2 expenses:food:daily=1 assets:cash=-1 >"$ordinary_protocol_out"
ordinary_first_line=$(head -n 1 "$ordinary_protocol_out" | tr -d '\r')
[[ "$ordinary_first_line" == $'OK\tAPPEND_BLOCK\t1\tordinary\t-\t2\t1' ]] || { echo "FAIL ordinary renderer protocol header: line='$ordinary_first_line'" >&2; exit 1; }
! grep -Fq 'stage0-line-' "$ordinary_protocol_out"

# Direct validator success protocol
echo "Checking direct validator success protocol..." >&2
v_base=$(new_base validator-success)
v_journal="$v_base/source.journal"
printf '\n%s\n' "$expected_block" >>"$v_journal"
v_out="$tmp_root/v-success.out"
bqn src_edit/journal_native_source_check.bqn "$v_base" "$v_journal" 2026-07-22 スーパー durable purchase-20260722-001 1 expenses:food:daily=1200 expenses:household=500 assets:cash=-1700 >"$v_out" 2>&1 || { echo "FAIL validator success command rc=$? output:" >&2; cat "$v_out" >&2; exit 1; }
grep -Fq $'OK\tNATIVE_JOURNAL_CANDIDATE\tdurable\tpurchase-20260722-001\t1\t3' "$v_out" || { echo "FAIL validator success grep output:" >&2; cat "$v_out" >&2; exit 1; }

# Identity mode mismatches are classified after ordinal candidate selection.
mode_out="$tmp_root/durable-as-ordinary.out"
set +e
bqn src_edit/journal_native_source_check.bqn "$v_base" "$v_journal" 2026-07-22 スーパー ordinary '' 1 expenses:food:daily=1200 expenses:household=500 assets:cash=-1700 >"$mode_out" 2>&1
rc=$?
set -e
[[ $rc -ne 0 ]]; grep -Fq $'ERROR\tnative_candidate_mismatch' "$mode_out"
mode_out="$tmp_root/ordinary-as-durable.out"
set +e
bqn src_edit/journal_native_source_check.bqn "$ordinary" "$ordinary/source.journal" 2026-07-22 ordinary-append durable wrong-durable-id 1 expenses:food:daily=1 assets:cash=-1 >"$mode_out" 2>&1
rc=$?
set -e
[[ $rc -ne 0 ]]; grep -Fq $'ERROR\tnative_candidate_mismatch' "$mode_out"

# Wrong event-id classification
echo "Checking wrong event-id classification..." >&2
w_event_out="$tmp_root/wrong-event.out"
set +e
bqn src_edit/journal_native_source_check.bqn "$v_base" "$v_journal" 2026-07-22 スーパー durable wrong-event-id 1 expenses:food:daily=1200 expenses:household=500 assets:cash=-1700 >"$w_event_out" 2>&1
rc=$?
set -e
[[ $rc -ne 0 ]] || { echo "FAIL wrong-event expected non-zero rc" >&2; exit 1; }
grep -Fq $'ERROR\tnative_candidate_mismatch' "$w_event_out" || { echo "FAIL wrong-event output:" >&2; cat "$w_event_out" >&2; exit 1; }
if grep -Fq 'native_candidate_identity_invalid' "$w_event_out"; then echo "FAIL: unexpected native_candidate_identity_invalid" >&2; exit 1; fi

# Wrong ordinal count guard
echo "Checking wrong ordinal count guard..." >&2
for w_ord in 0 2; do
  w_ord_out="$tmp_root/wrong-ord-$w_ord.out"
  set +e
  bqn src_edit/journal_native_source_check.bqn "$v_base" "$v_journal" 2026-07-22 スーパー durable purchase-20260722-001 "$w_ord" expenses:food:daily=1200 expenses:household=500 assets:cash=-1700 >"$w_ord_out" 2>&1
  rc=$?
  set -e
  [[ $rc -ne 0 ]] || { echo "FAIL wrong-ord $w_ord expected non-zero rc" >&2; exit 1; }
  grep -Fq $'ERROR\tnative_candidate_count_invalid' "$w_ord_out" || { echo "FAIL wrong-ord $w_ord output:" >&2; cat "$w_ord_out" >&2; exit 1; }
done

# Invalid ordinal syntax
echo "Checking invalid ordinal syntax..." >&2
for inv_ord in -1 01 1.0 abc; do
  inv_ord_out="$tmp_root/inv-ord-${inv_ord//./_}.out"
  set +e
  bqn src_edit/journal_native_source_check.bqn "$v_base" "$v_journal" 2026-07-22 スーパー durable purchase-20260722-001 "$inv_ord" expenses:food:daily=1200 expenses:household=500 assets:cash=-1700 >"$inv_ord_out" 2>&1
  rc=$?
  set -e
  [[ $rc -ne 0 ]] || { echo "FAIL inv-ord $inv_ord expected non-zero rc" >&2; exit 1; }
  grep -Fq $'ERROR\tcandidate_ordinal_invalid' "$inv_ord_out" || { echo "FAIL inv-ord $inv_ord output:" >&2; cat "$inv_ord_out" >&2; exit 1; }
done

# Multiple append guard
echo "Checking multiple append guard..." >&2
m_base=$(new_base multi-append)
m_journal="$m_base/source.journal"
expected_block2='2026-07-22 * スーパー
    ; event-id: purchase-20260722-002
    expenses:food:daily    1200 JPY
    expenses:household    500 JPY
    assets:cash    -1700 JPY'
printf '\n%s\n\n%s\n' "$expected_block" "$expected_block2" >>"$m_journal"
m_out="$tmp_root/multi-append.out"
set +e
bqn src_edit/journal_native_source_check.bqn "$m_base" "$m_journal" 2026-07-22 スーパー durable purchase-20260722-001 1 expenses:food:daily=1200 expenses:household=500 assets:cash=-1700 >"$m_out" 2>&1
rc=$?
set -e
[[ $rc -ne 0 ]] || { echo "FAIL multi-append expected non-zero rc" >&2; exit 1; }
grep -Fq $'ERROR\tnative_candidate_count_invalid' "$m_out" || { echo "FAIL multi-append output:" >&2; cat "$m_out" >&2; exit 1; }

printf 'check-edit-bqn-journal-block-add: OK\n'
