#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

fixture="fixtures/currency-m15-migration"
tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

fail_output() {
  local label="$1" expected="$2" actual="$3"
  printf 'FAIL: %s\nexpected: %s\nactual output:\n%s\n' "$label" "$expected" "$actual" >&2
  exit 1
}

assert_line() {
  local expected="$1" actual="$2" label="$3"
  grep -Fxq -- "$expected" <<<"$actual" || fail_output "$label" "$expected" "$actual"
}

assert_contains() {
  local expected="$1" actual="$2" label="$3"
  grep -Fq -- "$expected" <<<"$actual" || fail_output "$label" "$expected" "$actual"
}

sha_file() {
  shasum -a 256 "$1" | awk '{print $1}'
}

capture_setup() {
  local mode="$1" output status
  set +e
  output="$(bash tools/currency-setup "$mode" "$fixture" 2>&1)"
  status=$?
  set -e
  if [[ "$status" -ne 0 ]]; then
    fail_output "$mode command exit" 'status=0' "status=$status
$output"
  fi
  printf '%s' "$output"
}

python3 -m py_compile tools/currency_setup_apply.py

# Existing M1.5 audit and dry-run remain read-only and exact.
audit_out="$(capture_setup audit)"
assert_line 'state=ok' "$audit_out" 'audit state'
assert_line 'default_key=DEFAULT_CURRENCY' "$audit_out" 'default key'
assert_line 'default_state=ok' "$audit_out" 'default state'
assert_line 'default_currency=JPY' "$audit_out" 'default currency'
assert_line 'default_provenance=ledger_config' "$audit_out" 'default provenance'
assert_line 'migration_target=JPY' "$audit_out" 'migration target'
assert_line 'changed_count=5' "$audit_out" 'audit changed count'
assert_line 'error_count=0' "$audit_out" 'audit error count'
if grep -q '^FILE ' <<<"$audit_out"; then
  echo 'FAIL: audit mode emitted migration replacement preview' >&2
  printf '%s\n' "$audit_out" >&2
  exit 1
fi

dry_out="$(capture_setup dry-run)"
assert_line 'changed_count=5' "$dry_out" 'dry-run changed count'
assert_contains 'FILE accounts.tsv ROW 1' "$dry_out" 'accounts preview row'
assert_contains $'+assets:bank\trole=asset\ttype=liquid\tcurrency=JPY' "$dry_out" 'accounts proposed line'
assert_contains 'FILE journal.tsv ROW 1' "$dry_out" 'journal preview row'
assert_contains $'+2026-07-01\t\tassets:bank\texpenses:food\t1200\tparty=shop\tcurrency=JPY' "$dry_out" 'journal proposed line'
assert_contains 'FILE plan.tsv ROW 0' "$dry_out" 'plan preview row'
assert_contains 'FILE budget_alloc.tsv ROW 0' "$dry_out" 'budget preview row'

before="$(find "$fixture" -type f -print0 | sort -z | xargs -0 sha256sum)"
capture_setup dry-run >/dev/null
after="$(find "$fixture" -type f -print0 | sort -z | xargs -0 sha256sum)"
if [[ "$before" != "$after" ]]; then
  echo 'FAIL: currency setup dry-run modified fixture data' >&2
  exit 1
fi

# Apply against a complete public-data copy. Remove the default first so the
# operation must add DEFAULT_CURRENCY=JPY and migrate source rows together.
apply_base="$tmp_root/apply"
cp -R data "$apply_base"
awk '!/^DEFAULT_CURRENCY([[:space:]]|=)/' "$apply_base/config.tsv" > "$tmp_root/config-no-default.tsv"
mv "$tmp_root/config-no-default.tsv" "$apply_base/config.tsv"

cut -f1 "$apply_base/accounts.tsv" > "$tmp_root/accounts-before.txt"
for file in journal.tsv plan.tsv budget_alloc.tsv; do
  cut -f1-5 "$apply_base/$file" > "$tmp_root/$file.before-five"
done

set +e
pre_apply_dry="$(tools/currency-setup dry-run "$apply_base" 2>&1)"
pre_apply_rc=$?
set -e
if [[ "$pre_apply_rc" -eq 0 ]]; then
  echo 'FAIL: missing-default dry-run unexpectedly returned success' >&2
  exit 1
fi
assert_contains 'ERROR: missing ledger config key: DEFAULT_CURRENCY' "$pre_apply_dry" 'missing default evidence'
pre_changed="$(awk -F= '/^changed_count=/{print $2; exit}' <<<"$pre_apply_dry")"
if [[ -z "$pre_changed" || "$pre_changed" -le 0 ]]; then
  fail_output 'pre-apply changed count' 'positive changed_count' "$pre_apply_dry"
fi

apply_out="$(tools/currency-setup apply "$apply_base" --yes --post-check lint 2>&1)"
assert_contains 'Migration applied successfully.' "$apply_out" 'apply success'
assert_contains 'Idempotence: audit reports changed_count=0' "$apply_out" 'apply idempotence proof'
if [[ "$(grep -Ec '^DEFAULT_CURRENCY=JPY$' "$apply_base/config.tsv")" -ne 1 ]]; then
  echo 'FAIL: apply did not add exactly one DEFAULT_CURRENCY=JPY' >&2
  exit 1
fi

cut -f1 "$apply_base/accounts.tsv" > "$tmp_root/accounts-after.txt"
cmp -s "$tmp_root/accounts-before.txt" "$tmp_root/accounts-after.txt" || {
  echo 'FAIL: apply changed account names or order' >&2
  exit 1
}
for file in journal.tsv plan.tsv budget_alloc.tsv; do
  cut -f1-5 "$apply_base/$file" > "$tmp_root/$file.after-five"
  cmp -s "$tmp_root/$file.before-five" "$tmp_root/$file.after-five" || {
    echo "FAIL: apply changed first five columns in $file" >&2
    exit 1
  }
done

post_audit="$(tools/currency-setup audit "$apply_base")"
assert_line 'state=ok' "$post_audit" 'post-apply state'
assert_line 'changed_count=0' "$post_audit" 'post-apply changed count'
assert_line 'error_count=0' "$post_audit" 'post-apply error count'

for file in config.tsv accounts.tsv journal.tsv plan.tsv budget_alloc.tsv; do
  if ! find "$apply_base/.backup" -type f -name "$file.*.currency-m25.bak" | grep -q .; then
    echo "FAIL: apply did not create recoverable backup for $file" >&2
    exit 1
  fi
done
backup_count_before="$(find "$apply_base/.backup" -type f | wc -l | tr -d ' ')"
second_out="$(tools/currency-setup apply "$apply_base" --yes --post-check lint 2>&1)"
assert_contains 'Already migrated. No files were modified.' "$second_out" 'second apply no-op'
backup_count_after="$(find "$apply_base/.backup" -type f | wc -l | tr -d ' ')"
if [[ "$backup_count_before" != "$backup_count_after" ]]; then
  echo 'FAIL: idempotent apply created extra backups' >&2
  exit 1
fi

# Stale source after backup but before replacement aborts without overwriting
# the concurrent edit. Other source files and config remain untouched.
stale_base="$tmp_root/stale"
cp -R data "$stale_base"
awk '!/^DEFAULT_CURRENCY([[:space:]]|=)/' "$stale_base/config.tsv" > "$tmp_root/stale-config.tsv"
mv "$tmp_root/stale-config.tsv" "$stale_base/config.tsv"
stale_config_before="$(sha_file "$stale_base/config.tsv")"
stale_journal_before="$(sha_file "$stale_base/journal.tsv")"
stale_plan_before="$(sha_file "$stale_base/plan.tsv")"
stale_budget_before="$(sha_file "$stale_base/budget_alloc.tsv")"
stale_hook="printf '\n# concurrent edit\n' >> '$stale_base/accounts.tsv'"
set +e
stale_out="$(BQN_LEDGER_TEST_MODE=1 CURRENCY_SETUP_TEST_BEFORE_COMMIT_HOOK="$stale_hook" \
  tools/currency-setup apply "$stale_base" --yes --post-check lint 2>&1)"
stale_rc=$?
set -e
if [[ "$stale_rc" -eq 0 ]]; then
  fail_output 'stale apply' 'non-zero exit' "$stale_out"
fi
assert_contains 'Migration aborted before replacement because a source became stale.' "$stale_out" 'stale abort message'
grep -Fxq '# concurrent edit' "$stale_base/accounts.tsv" || {
  echo 'FAIL: stale apply did not preserve concurrent edit' >&2
  exit 1
}
[[ "$(sha_file "$stale_base/config.tsv")" == "$stale_config_before" ]]
[[ "$(sha_file "$stale_base/journal.tsv")" == "$stale_journal_before" ]]
[[ "$(sha_file "$stale_base/plan.tsv")" == "$stale_plan_before" ]]
[[ "$(sha_file "$stale_base/budget_alloc.tsv")" == "$stale_budget_before" ]]

# A post-check failure after replacement restores the entire migrated source set.
rollback_base="$tmp_root/rollback"
cp -R data "$rollback_base"
awk '!/^DEFAULT_CURRENCY([[:space:]]|=)/' "$rollback_base/config.tsv" > "$tmp_root/rollback-config.tsv"
mv "$tmp_root/rollback-config.tsv" "$rollback_base/config.tsv"
rm -f "$rollback_base/cycle.tsv"
for file in config.tsv accounts.tsv journal.tsv plan.tsv budget_alloc.tsv; do
  sha_file "$rollback_base/$file" > "$tmp_root/rollback-$file.sha"
done
set +e
rollback_out="$(tools/currency-setup apply "$rollback_base" --yes --post-check lint 2>&1)"
rollback_rc=$?
set -e
if [[ "$rollback_rc" -eq 0 ]]; then
  fail_output 'post-check rollback' 'non-zero exit' "$rollback_out"
fi
assert_contains 'Post-check failed; the complete source set was restored from backups.' "$rollback_out" 'rollback message'
for file in config.tsv accounts.tsv journal.tsv plan.tsv budget_alloc.tsv; do
  expected_sha="$(cat "$tmp_root/rollback-$file.sha")"
  actual_sha="$(sha_file "$rollback_base/$file")"
  if [[ "$expected_sha" != "$actual_sha" ]]; then
    echo "FAIL: post-check rollback did not restore $file" >&2
    exit 1
  fi
done

printf 'OK: M1.5 audit/preview and M2.5 safe apply contracts passed\n'
