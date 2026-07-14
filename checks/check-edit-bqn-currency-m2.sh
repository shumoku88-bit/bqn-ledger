#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
unset LEDGER_DATA_DIR

fixture="fixtures/editor-currency-m2"
tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

sha_file() {
  shasum -a 256 "$1" | awk '{print $1}'
}

assert_no_backup() {
  local base="$1" label="$2"
  if [[ -d "$base/.backup" ]] && find "$base/.backup" -type f | grep -q .; then
    echo "FAIL: $label created a backup" >&2
    find "$base/.backup" -type f >&2
    exit 1
  fi
}

copy_fixture() {
  local name="$1"
  local target="$tmp_root/$name"
  cp -R "$fixture" "$target"
  printf '%s' "$target"
}

expect_fail_unchanged() {
  local label="$1" target_file="$2"
  shift 2
  local base out before after rc
  base="$(copy_fixture "fail-$label")"
  out="$tmp_root/fail-$label.out"
  before="$(sha_file "$base/$target_file")"
  set +e
  ./tools/edit --base "$base" "$@" >"$out" 2>&1
  rc=$?
  set -e
  if [[ "$rc" -eq 0 ]]; then
    echo "FAIL: $label unexpectedly succeeded" >&2
    cat "$out" >&2
    exit 1
  fi
  after="$(sha_file "$base/$target_file")"
  if [[ "$before" != "$after" ]]; then
    echo "FAIL: $label modified $target_file" >&2
    exit 1
  fi
  if [[ -d "$base/.backup" ]] && find "$base/.backup" -type f | grep -q .; then
    echo "FAIL: $label created a backup" >&2
    find "$base/.backup" -type f >&2
    exit 1
  fi
}

# Role and currency filters compose without leaking the other domain.
ils_assets="$(./tools/edit --base "$fixture" account list --role asset --currency ILS)"
grep -Fxq 'assets:cash-ils' <<<"$ils_assets"
if grep -Fxq 'assets:bank' <<<"$ils_assets"; then
  echo 'FAIL: ILS asset list included JPY account' >&2
  exit 1
fi
jpy_expenses="$(./tools/edit --base "$fixture" account list --role expense --currency JPY)"
grep -Fxq 'expenses:food' <<<"$jpy_expenses"
if grep -Fxq 'expenses:food-ils' <<<"$jpy_expenses"; then
  echo 'FAIL: JPY expense list included ILS account' >&2
  exit 1
fi
if ./tools/edit --base "$fixture" account list --currency EUR >"$tmp_root/list-usd.out" 2>&1; then
  echo 'FAIL: account list accepted unsupported EUR' >&2
  exit 1
fi

# Account add uses ledger default only as initial selection and always writes it.
default_account_base="$(copy_fixture account-default)"
default_preview="$(./tools/edit --base "$default_account_base" account add --name 'expenses:travel' --role expense --dry-run --post-check none)"
grep -Fq $'expenses:travel\trole=expense\tcurrency=JPY' <<<"$default_preview"
if grep -Fq 'expenses:travel' "$default_account_base/accounts.tsv"; then
  echo 'FAIL: default account dry-run modified accounts.tsv' >&2
  exit 1
fi

ils_account_base="$(copy_fixture account-ils)"
./tools/edit --base "$ils_account_base" account add --name 'expenses:transit-ils' --role expense --currency ILS --yes --post-check none >/dev/null
grep -Fxq $'expenses:transit-ils\trole=expense\tcurrency=ILS' "$ils_account_base/accounts.tsv"

expect_fail_unchanged account-unsupported accounts.tsv \
  account add --name 'assets:eur' --role asset --type liquid --currency EUR --yes --post-check none

# Default JPY journal input accepts exact decimals and emits explicit metadata.
jpy_base="$(copy_fixture journal-jpy)"
./tools/edit --base "$jpy_base" journal add \
  --date 2026-07-02 --memo 'JPY decimal' \
  --from assets:bank --to expenses:food --amount 12.34 \
  --yes --post-check none >/dev/null
grep -Fxq $'2026-07-02\tJPY decimal\tassets:bank\texpenses:food\t12.34\tcurrency=JPY' "$jpy_base/journal.tsv"

# Explicit ILS override selects only ILS accounts and preserves source text.
ils_base="$(copy_fixture journal-ils)"
./tools/edit --base "$ils_base" journal add \
  --date 2026-07-02 --memo 'ILS bread' \
  --from assets:cash-ils --to expenses:food-ils --amount 12.50 --currency ILS \
  --yes --post-check none >/dev/null
grep -Fxq $'2026-07-02\tILS bread\tassets:cash-ils\texpenses:food-ils\t12.50\tcurrency=ILS' "$ils_base/journal.tsv"

small_preview="$(./tools/edit --base "$ils_base" journal add \
  --date 2026-07-03 --memo 'ILS small' \
  --from assets:cash-ils --to expenses:food-ils --amount 0.05 --currency ILS \
  --dry-run --post-check none)"
grep -Fq $'2026-07-03\tILS small\tassets:cash-ils\texpenses:food-ils\t0.05\tcurrency=ILS' <<<"$small_preview"

# ILS lexical precision is closed at two digits. No rounding or writes occur.
expect_fail_unchanged ils-three-digits journal.tsv \
  journal add --date 2026-07-02 --memo bad \
  --from assets:cash-ils --to expenses:food-ils --amount 1.234 --currency ILS --yes --post-check none
expect_fail_unchanged ils-trailing-three-digits journal.tsv \
  journal add --date 2026-07-02 --memo bad \
  --from assets:cash-ils --to expenses:food-ils --amount 1.000 --currency ILS --yes --post-check none

# Account-domain mismatch and manual currency metadata both fail before write.
expect_fail_unchanged account-currency-mismatch journal.tsv \
  journal add --date 2026-07-02 --memo mismatch \
  --from assets:bank --to expenses:food-ils --amount 1.00 --currency ILS --yes --post-check none
expect_fail_unchanged manual-currency-meta journal.tsv \
  journal add --date 2026-07-02 --memo duplicate-authority \
  --from assets:cash-ils --to expenses:food-ils --amount 1.00 --currency ILS \
  --meta currency=ILS --yes --post-check none
expect_fail_unchanged unsupported-selector journal.tsv \
  journal add --date 2026-07-02 --memo eur \
  --from assets:bank --to expenses:food --amount 1 --currency EUR --yes --post-check none

# Israel predeparture readiness reuses the ordinary journal owner unchanged.
travel_base="$(copy_fixture israel-travel)"
travel_before="$(sha_file "$travel_base/journal.tsv")"
travel_lines_before="$(wc -l < "$travel_base/journal.tsv" | tr -d ' ')"

cash_preview="$(./tools/edit --base "$travel_base" journal add \
  --date 2026-07-20 --memo 'synthetic meal' \
  --from assets:cash-ils --to expenses:food-ils --amount 42.50 --currency ILS \
  --meta trip_id=israel-2026 --meta payment=cash --dry-run --post-check none)"
grep -Fq $'2026-07-20\tsynthetic meal\tassets:cash-ils\texpenses:food-ils\t42.50\ttrip_id=israel-2026\tpayment=cash\tcurrency=ILS' <<<"$cash_preview"
[[ "$travel_before" == "$(sha_file "$travel_base/journal.tsv")" ]]
assert_no_backup "$travel_base" 'Israel cash dry-run'

card_preview="$(./tools/edit --base "$travel_base" journal add \
  --date 2026-07-20 --memo 'synthetic transit' \
  --from liabilities:card-jpy --to expenses:transit-jpy --amount 1800 --currency JPY \
  --meta trip_id=israel-2026 --meta payment=card --dry-run --post-check none)"
grep -Fq $'2026-07-20\tsynthetic transit\tliabilities:card-jpy\texpenses:transit-jpy\t1800\ttrip_id=israel-2026\tpayment=card\tcurrency=JPY' <<<"$card_preview"
[[ "$travel_before" == "$(sha_file "$travel_base/journal.tsv")" ]]
assert_no_backup "$travel_base" 'Israel card dry-run'

./tools/edit --base "$travel_base" journal add \
  --date 2026-07-20 --memo 'synthetic meal' \
  --from assets:cash-ils --to expenses:food-ils --amount 42.50 --currency ILS \
  --meta trip_id=israel-2026 --meta payment=cash --yes --post-check none >/dev/null
[[ "$((travel_lines_before + 1))" -eq "$(wc -l < "$travel_base/journal.tsv" | tr -d ' ')" ]]
grep -Fxq $'2026-07-20\tsynthetic meal\tassets:cash-ils\texpenses:food-ils\t42.50\ttrip_id=israel-2026\tpayment=cash\tcurrency=ILS' "$travel_base/journal.tsv"

./tools/edit --base "$travel_base" journal add \
  --date 2026-07-20 --memo 'synthetic transit' \
  --from liabilities:card-jpy --to expenses:transit-jpy --amount 1800 --currency JPY \
  --meta trip_id=israel-2026 --meta payment=card --yes --post-check none >/dev/null
[[ "$((travel_lines_before + 2))" -eq "$(wc -l < "$travel_base/journal.tsv" | tr -d ' ')" ]]
grep -Fxq $'2026-07-20\tsynthetic transit\tliabilities:card-jpy\texpenses:transit-jpy\t1800\ttrip_id=israel-2026\tpayment=card\tcurrency=JPY' "$travel_base/journal.tsv"

# The public read-only loader can reload both ordinary rows.
travel_list="$(./tools/edit --base "$travel_base" journal list --format tsv)"
grep -Fq $'2\t2026-07-20\tsynthetic meal\tassets:cash-ils\texpenses:food-ils\t42.50\t' <<<"$travel_list"
grep -Fq $'3\t2026-07-20\tsynthetic transit\tliabilities:card-jpy\texpenses:transit-jpy\t1800\t' <<<"$travel_list"

expect_fail_unchanged travel-mismatch journal.tsv \
  journal add --date 2026-07-20 --memo mismatch \
  --from assets:cash-ils --to expenses:food --amount 1 --currency ILS \
  --meta trip_id=israel-2026 --meta payment=cash --yes --post-check none
expect_fail_unchanged travel-ils-precision journal.tsv \
  journal add --date 2026-07-20 --memo precision \
  --from assets:cash-ils --to expenses:food-ils --amount 42.501 --currency ILS \
  --meta trip_id=israel-2026 --meta payment=cash --yes --post-check none
expect_fail_unchanged travel-invalid-meta journal.tsv \
  journal add --date 2026-07-20 --memo meta \
  --from assets:cash-ils --to expenses:food-ils --amount 42.50 --currency ILS \
  --meta trip_id --meta payment=cash --yes --post-check none

# Existing snapshot-hook semantics reject a stale travel append. Only the
# simulated concurrent marker may change the file; the candidate never lands.
stale_travel_base="$(copy_fixture israel-stale)"
append_israel_stale_marker() {
  printf '%s\n' '# synthetic concurrent edit' >> "$EDIT_BQN_TEST_STALE_JOURNAL"
}
export -f append_israel_stale_marker
set +e
BQN_LEDGER_TEST_MODE=1 \
EDIT_BQN_TEST_STALE_JOURNAL="$stale_travel_base/journal.tsv" \
EDIT_BQN_TEST_BEFORE_APPEND_HOOK=append_israel_stale_marker \
  ./tools/edit --base "$stale_travel_base" journal add \
    --date 2026-07-20 --memo 'stale synthetic meal' \
    --from assets:cash-ils --to expenses:food-ils --amount 42.50 --currency ILS \
    --meta trip_id=israel-2026 --meta payment=cash --yes --post-check none \
    >"$tmp_root/israel-stale.out" 2>&1
stale_travel_rc=$?
set -e
if [[ "$stale_travel_rc" -eq 0 ]] || grep -Fq 'stale synthetic meal' "$stale_travel_base/journal.tsv"; then
  echo 'FAIL: stale Israel journal candidate was accepted' >&2
  cat "$tmp_root/israel-stale.out" >&2
  exit 1
fi
tail -n 1 "$stale_travel_base/journal.tsv" | grep -Fxq '# synthetic concurrent edit'
assert_no_backup "$stale_travel_base" 'stale Israel journal append'

printf 'OK: M2 currency-aware account and journal editor contracts passed\n'
