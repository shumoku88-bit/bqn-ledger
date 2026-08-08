#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
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

# Explicit user metadata is preserved exactly.
exp_base=$(new_base explicit-meta); exp_out="$tmp_root/explicit-meta.out"
exp_args=(journal-block add --journal-file source.journal --date 2026-07-22 --description explicit-metadata --event-id explicit-metadata-001 --posting expenses:food:daily=1 --posting assets:cash=-1 --meta currency=JPY --meta note=explicit --meta trip_id=trip-synthetic-2026 --meta payment=card --dry-run)
run_ok "$exp_base" "$exp_out" "${exp_args[@]}"
grep -Fq '    ; currency: JPY' "$exp_out"
grep -Fq '    ; note: explicit' "$exp_out"
grep -Fq '    ; trip-id: trip-synthetic-2026' "$exp_out"
grep -Fq '    ; payment: card' "$exp_out"

# Ordinary Actuals stay identity-free while preserving explicit metadata.
ordinary=$(new_base ordinary-append); ordinary_before_events=$(grep -Fc '; event-id:' "$ordinary/source.journal" || true); ordinary_out="$tmp_root/ordinary-append.out"
run_ok "$ordinary" "$ordinary_out" journal-block add --identity ordinary --journal-file source.journal --date 2026-07-22 --description ordinary-append \
  --posting expenses:food:daily=1 --posting assets:cash=-1 --meta note=explicit --meta currency=JPY --yes --post-check none
[[ $(grep -Fc '; event-id:' "$ordinary/source.journal" || true) -eq "$ordinary_before_events" ]]
grep -Fq '2026-07-22 * ordinary-append' "$ordinary/source.journal"
grep -Fq '    ; note: explicit' "$ordinary/source.journal"
grep -Fq 'Mandatory native validation: OK' "$ordinary_out"
grep -Fq $'OK\tNATIVE_JOURNAL_CANDIDATE\tordinary\t-\t1\t2' "$ordinary_out"

# Exact bytes for the three supported source endings converge.
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
  { cat "$original"; printf '%s' "$sep"; printf '%s\n' "$expected_block"; } >"$tmp_root/$ending.expected"
  run_ok "$base" "$tmp_root/$ending.out" "${args[@]}" --yes --post-check none
  cmp "$tmp_root/$ending.expected" "$base/source.journal"
  grep -Fq 'Mandatory native validation: OK' "$tmp_root/$ending.out"
  current=$(sha_file "$base/source.journal"); [[ -z "$reference_sha" || "$reference_sha" == "$current" ]]; reference_sha=$current
done

# Explicit nested targets remain contained under BASE.
nested=$(new_base nested); mkdir "$nested/sub"; mv "$nested/source.journal" "$nested/sub/native.journal"
run_ok "$nested" "$tmp_root/nested.out" journal-block add --journal-file sub/native.journal --date 2026-07-22 --description スーパー --event-id purchase-nested-001 \
  --posting expenses:food:daily=1200 --posting expenses:household=500 --posting assets:cash=-1700 --yes
tail -n 3 "$nested/sub/native.journal" >"$tmp_root/nested.tail"
printf '%s\n' '    expenses:food:daily    1200 JPY' '    expenses:household    500 JPY' '    assets:cash    -1700 JPY' >"$tmp_root/nested.expected"
cmp "$tmp_root/nested.expected" "$tmp_root/nested.tail"

# Routed multi-add is fixed to canonical actual.journal. Legacy config cannot redirect it.
routed=$(new_base routed)
printf 'ACTUAL_JOURNAL_FILE=source.journal\nDEFAULT_CURRENCY=JPY\n' >"$routed/config.tsv"
routed_actual_before=$(sha_file "$routed/actual.journal")
routed_source_before=$(sha_file "$routed/source.journal")
routed_before_events=$(grep -Fc '; event-id:' "$routed/actual.journal" || true)
run_ok "$routed" "$tmp_root/routed.out" journal multi-add --date 2026-07-22 --description routed-split \
  --posting expenses:food:daily=1200 --posting expenses:household=500 --posting assets:cash=-1700 --yes --post-check none
[[ $(sha_file "$routed/actual.journal") != "$routed_actual_before" ]]
[[ $(sha_file "$routed/source.journal") == "$routed_source_before" ]]
grep -Fq '2026-07-22 * routed-split' "$routed/actual.journal"
tail -n 3 "$routed/actual.journal" >"$tmp_root/routed.tail"
printf '%s\n' '    expenses:food:daily    1200 JPY' '    expenses:household    500 JPY' '    assets:cash    -1700 JPY' >"$tmp_root/routed.expected"
cmp "$tmp_root/routed.expected" "$tmp_root/routed.tail"
grep -Fq 'Mandatory native validation: OK' "$tmp_root/routed.out"
grep -Fq $'OK\tNATIVE_JOURNAL_CANDIDATE\tordinary\t-' "$tmp_root/routed.out"
[[ $(grep -Fc '; event-id:' "$routed/actual.journal" || true) -eq "$routed_before_events" ]]
! grep -Fq 'entry-' "$routed/actual.journal"

# Path rejection cases.
base=$(new_base path); before=$(sha_file "$base/source.journal")
assert_rejected_unchanged missing-journal-file "$base" "$before" "$tmp_root/missing-option.out" journal-block add --date 2026-07-22 --description x --event-id x --posting assets:cash=-1 --posting expenses:food:daily=1
assert_rejected_unchanged absolute "$base" "$before" "$tmp_root/absolute.out" journal-block add --journal-file "$base/source.journal" --date 2026-07-22 --description x --event-id x --posting assets:cash=-1 --posting expenses:food:daily=1
assert_rejected_unchanged traversal "$base" "$before" "$tmp_root/traversal.out" journal-block add --journal-file ../outside.journal --date 2026-07-22 --description x --event-id x --posting assets:cash=-1 --posting expenses:food:daily=1
assert_rejected_unchanged suffix "$base" "$before" "$tmp_root/suffix.out" journal-block add --journal-file source.txt --date 2026-07-22 --description x --event-id x --posting assets:cash=-1 --posting expenses:food:daily=1
assert_rejected_unchanged missing-target "$base" "$before" "$tmp_root/missing-target.out" journal-block add --journal-file missing.journal --date 2026-07-22 --description x --event-id x --posting assets:cash=-1 --posting expenses:food:daily=1
mkdir "$base/directory.journal"
assert_rejected_unchanged directory "$base" "$before" "$tmp_root/directory.out" journal-block add --journal-file directory.journal --date 2026-07-22 --description x --event-id x --posting assets:cash=-1 --posting expenses:food:daily=1
outside="$tmp_root/outside.journal"; cp "$base/source.journal" "$outside"; ln -s "$outside" "$base/escape.journal"
assert_rejected_unchanged symlink "$base" "$before" "$tmp_root/symlink.out" journal-block add --journal-file escape.journal --date 2026-07-22 --description x --event-id x --posting assets:cash=-1 --posting expenses:food:daily=1

# Semantic rejection helper: every rejected source stays byte-identical and backup-free.
noop_setup() { :; }
run_semantic_case() { local name=$1 setup=$2; shift 2; local base; base=$(new_base "reject-$name"); "$setup" "$base"; local before=$(sha_file "$base/source.journal"); assert_rejected_unchanged "$name" "$base" "$before" "$tmp_root/$name.out" "$@"; }
common_prefix=(journal-block add --journal-file source.journal)
run_semantic_case invalid-date noop_setup "${common_prefix[@]}" --date 2026-02-30 --description x --event-id new-id --posting expenses:food:daily=1 --posting assets:cash=-1
run_semantic_case blank-description noop_setup "${common_prefix[@]}" --date 2026-07-22 --description '   ' --event-id new-id --posting expenses:food:daily=1 --posting assets:cash=-1
run_semantic_case missing-event noop_setup "${common_prefix[@]}" --date 2026-07-22 --description x --posting expenses:food:daily=1 --posting assets:cash=-1
run_semantic_case ordinary-event noop_setup "${common_prefix[@]}" --identity ordinary --date 2026-07-22 --description x --event-id new-id --posting expenses:food:daily=1 --posting assets:cash=-1
run_semantic_case one-posting noop_setup "${common_prefix[@]}" --date 2026-07-22 --description x --event-id new-id --posting assets:cash=-1
run_semantic_case zero-posting noop_setup "${common_prefix[@]}" --date 2026-07-22 --description x --event-id new-id --posting expenses:food:daily=0 --posting assets:cash=0
run_semantic_case noninteger-posting noop_setup "${common_prefix[@]}" --date 2026-07-22 --description x --event-id new-id --posting expenses:food:daily=abc --posting assets:cash=-1
run_semantic_case unbalanced noop_setup "${common_prefix[@]}" --date 2026-07-22 --description x --event-id new-id --posting expenses:food:daily=2 --posting assets:cash=-1
setup_registry_only() { cat >>"$1/accounts.journal" <<'EOF'

account expenses:registry-only
  type: Expense
  commodity: JPY
EOF
}
run_semantic_case undeclared-account setup_registry_only "${common_prefix[@]}" --date 2026-07-22 --description x --event-id new-id --posting expenses:registry-only=1 --posting assets:cash=-1
setup_declared_missing_registry() { printf '\naccount expenses:declared-only\n    ; role: expense\n' >>"$1/source.journal"; }
run_semantic_case missing-registry setup_declared_missing_registry "${common_prefix[@]}" --date 2026-07-22 --description x --event-id new-id --posting expenses:declared-only=1 --posting assets:cash=-1
setup_usd() { cat >>"$1/accounts.journal" <<'EOF'

account expenses:usd
  type: Expense
  commodity: USD
EOF
printf '\naccount expenses:usd\n    ; role: expense\n' >>"$1/source.journal"; }
run_semantic_case non-jpy setup_usd "${common_prefix[@]}" --date 2026-07-22 --description x --event-id new-id --posting expenses:usd=1 --posting assets:cash=-1
setup_malformed() { printf '\ninclude unsupported.journal\n' >>"$1/source.journal"; }
run_semantic_case malformed-existing setup_malformed "${common_prefix[@]}" --date 2026-07-22 --description x --event-id new-id --posting expenses:food:daily=1 --posting assets:cash=-1

# Cancellation has no backup or write.
cancel=$(new_base cancel); before=$(sha_file "$cancel/source.journal")
printf 'n\n' | ./tools/edit --base "$cancel" "${args[@]}" >"$tmp_root/cancel.out" 2>&1
[[ $(sha_file "$cancel/source.journal") == "$before" ]]; assert_no_backups "$cancel" cancellation

# Stale writes are rejected before append publication.
stale=$(new_base stale-before); stale_target="$stale/source.journal"
stale_hook() { printf '%s\n' '; concurrent-before-append' >>"$STALE_TARGET"; }
export -f stale_hook; export STALE_TARGET="$stale_target"
set +e
BQN_LEDGER_TEST_MODE=1 EDIT_BQN_TEST_BEFORE_JOURNAL_BLOCK_APPEND_HOOK=stale_hook ./tools/edit --base "$stale" "${args[@]}" --yes >"$tmp_root/stale-before.out" 2>&1
rc=$?
set -e
[[ $rc -ne 0 ]]; ! grep -Fq 'purchase-20260722-001' "$stale_target"; tail -n 1 "$stale_target" | grep -Fxq '; concurrent-before-append'; assert_no_backups "$stale" stale-before-append

# Mandatory failure restores exact original bytes and leaves backup evidence.
rollback=$(new_base rollback); rollback_before=$(sha_file "$rollback/source.journal")
set +e
BQN_LEDGER_TEST_MODE=1 EDIT_BQN_TEST_FORCE_NATIVE_POST_CHECK_FAIL=1 ./tools/edit --base "$rollback" "${args[@]}" --yes >"$tmp_root/rollback.out" 2>&1
rc=$?
set -e
[[ $rc -ne 0 && $(sha_file "$rollback/source.journal") == "$rollback_before" ]]
find "$rollback" -type f -path '*/.backup/*' | grep -q .
grep -Fq 'Rollback: restored original bytes' "$tmp_root/rollback.out"

# none and lint both retain mandatory native validation.
for mode in none lint; do
  mode_base=$(new_base "mode-$mode")
  run_ok "$mode_base" "$tmp_root/mode-$mode.out" "${args[@]}" --yes --post-check "$mode"
  grep -Fq 'Mandatory native validation: OK' "$tmp_root/mode-$mode.out"
done

# Full runs mandatory validation first, then the deterministic full-check seam.
full=$(new_base mode-full); export FULL_MARKER="$tmp_root/full.marker"
full_hook() { printf 'ran\n' >"$FULL_MARKER"; }
export -f full_hook
BQN_LEDGER_TEST_MODE=1 EDIT_BQN_JOURNAL_BLOCK_FULL_CHECK_HOOK=full_hook ./tools/edit --base "$full" "${args[@]}" --yes --post-check full >"$tmp_root/full.out" 2>&1
grep -Fq 'Mandatory native validation: OK' "$tmp_root/full.out"
[[ -f "$FULL_MARKER" ]]

# Direct validator preserves ordinal and durable identity checks.
v_base=$(new_base validator-success)
v_journal="$v_base/source.journal"
printf '\n%s\n' "$expected_block" >>"$v_journal"
bqn src_edit/journal_native_source_check.bqn "$v_base" "$v_journal" 2026-07-22 スーパー durable purchase-20260722-001 1 \
  expenses:food:daily=1200 expenses:household=500 assets:cash=-1700 >"$tmp_root/v-success.out"
grep -Fq $'OK\tNATIVE_JOURNAL_CANDIDATE\tdurable\tpurchase-20260722-001\t1\t3' "$tmp_root/v-success.out"
for w_ord in 0 2; do
  set +e
  bqn src_edit/journal_native_source_check.bqn "$v_base" "$v_journal" 2026-07-22 スーパー durable purchase-20260722-001 "$w_ord" \
    expenses:food:daily=1200 expenses:household=500 assets:cash=-1700 >"$tmp_root/wrong-ord-$w_ord.out" 2>&1
  rc=$?
  set -e
  [[ $rc -ne 0 ]]
  grep -Fq $'ERROR\tnative_candidate_count_invalid' "$tmp_root/wrong-ord-$w_ord.out"
done

# The validator itself must not regain a legacy Account source.
if rg -n 'accounts\.tsv|editor_accounts' src_edit/journal_native_source_check.bqn; then
  echo 'FAIL: native Journal validator still depends on legacy Accounts' >&2
  exit 1
fi

printf 'check-edit-bqn-journal-block-add: OK\n'
