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
  assert_no_backup "$base" "$label"
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
if ./tools/edit --base "$fixture" account list --currency EUR >"$tmp_root/list-eur.out" 2>&1; then
  echo 'FAIL: account list accepted unsupported EUR' >&2
  exit 1
fi

# A multi-currency canonical Account root cannot guess one Commodity from legacy config.
expect_fail_unchanged account-missing-currency accounts.journal \
  account add --name 'expenses:travel' --role expense --dry-run --post-check none
grep -Fq -- '--currency is required when canonical Accounts do not determine exactly one Commodity' "$tmp_root/fail-account-missing-currency.out"

jpy_account_base="$(copy_fixture account-jpy)"
jpy_preview="$(./tools/edit --base "$jpy_account_base" account add --name 'expenses:travel' --role expense --currency JPY --dry-run --post-check none)"
grep -Fq 'account expenses:travel' <<<"$jpy_preview"
grep -Fq '  type: Expense' <<<"$jpy_preview"
grep -Fq '  commodity: JPY' <<<"$jpy_preview"
if grep -Fq 'account expenses:travel' "$jpy_account_base/accounts.journal"; then
  echo 'FAIL: JPY Account dry-run modified accounts.journal' >&2
  exit 1
fi

ils_account_base="$(copy_fixture account-ils)"
legacy_before="$(sha_file "$ils_account_base/accounts.tsv")"
./tools/edit --base "$ils_account_base" account add --name 'expenses:transit-ils' --role expense --currency ILS --yes --post-check none >"$tmp_root/ils.out"
grep -Fq 'Mandatory Account validation: OK' "$tmp_root/ils.out"
grep -Fq 'account expenses:transit-ils' "$ils_account_base/accounts.journal"
grep -Fq '  commodity: ILS' "$ils_account_base/accounts.journal"
[[ "$(sha_file "$ils_account_base/accounts.tsv")" == "$legacy_before" ]] || { echo 'FAIL: ILS Account write modified legacy accounts.tsv' >&2; exit 1; }

expect_fail_unchanged account-unsupported accounts.journal \
  account add --name 'assets:eur' --role asset --currency EUR --yes --post-check none

printf 'OK: M2 currency-aware account editor contracts passed\n'
