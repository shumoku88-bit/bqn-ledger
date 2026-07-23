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

printf 'OK: M2 currency-aware account editor contracts passed\n'
