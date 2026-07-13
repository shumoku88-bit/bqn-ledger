#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

fixture="fixtures/editor-currency-m2"
tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

sha_file() {
  shasum -a 256 "$1" | awk '{print $1}'
}

copy_fixture() {
  local name="$1" target="$tmp_root/$name"
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
if ./tools/edit --base "$fixture" account list --currency USD >"$tmp_root/list-usd.out" 2>&1; then
  echo 'FAIL: account list accepted unsupported USD' >&2
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
  account add --name 'assets:usd' --role asset --type liquid --currency USD --yes --post-check none

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
  journal add --date 2026-07-02 --memo usd \
  --from assets:bank --to expenses:food --amount 1 --currency USD --yes --post-check none

printf 'OK: M2 currency-aware account and journal editor contracts passed\n'
