#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

list_base="fixtures/canonical-household-v1"
out_dir="$(mktemp -d)"
trap 'rm -rf "$out_dir"' EXIT

actual_asset="$(./tools/edit --base "$list_base" account list --role asset)"
if ! grep -Fxq 'Assets:Bank' <<< "$actual_asset"; then
  echo "FAIL: canonical account list --role asset missing Assets:Bank" >&2
  printf '%s\n' "$actual_asset" >&2
  exit 1
fi
if grep -Fxq 'Expenses:Groceries' <<< "$actual_asset"; then
  echo "FAIL: canonical account list --role asset included expense account" >&2
  printf '%s\n' "$actual_asset" >&2
  exit 1
fi

actual_expense="$(./tools/edit --base "$list_base" account list --role expense)"
if ! grep -Fxq 'Expenses:Groceries' <<< "$actual_expense"; then
  echo "FAIL: canonical account list --role expense missing Expenses:Groceries" >&2
  printf '%s\n' "$actual_expense" >&2
  exit 1
fi
if grep -Fxq 'Assets:Bank' <<< "$actual_expense"; then
  echo "FAIL: canonical account list --role expense included asset account" >&2
  printf '%s\n' "$actual_expense" >&2
  exit 1
fi

actual_missing_role="$(./tools/edit --base "$list_base" account list --role does-not-exist)"
if [[ -n "$actual_missing_role" ]]; then
  echo "FAIL: canonical account list --role does-not-exist should be empty" >&2
  printf '%s\n' "$actual_missing_role" >&2
  exit 1
fi

actual_all="$(./tools/edit --base "$list_base" account list)"
for account in 'Assets:Bank' 'Equity:Opening' 'Income:Salary' 'Expenses:Groceries' 'Budget:Unassigned' 'Budget:Daily'; do
  if ! grep -Fxq "$account" <<< "$actual_all"; then
    echo "FAIL: canonical account list missing $account" >&2
    printf '%s\n' "$actual_all" >&2
    exit 1
  fi
done

preferred_expense="$(./tools/edit --base "$list_base" account list --prefer-role expense)"
expected_preferred_expense=$'Expenses:Groceries\nAssets:Bank\nEquity:Opening\nIncome:Salary\nBudget:Unassigned\nBudget:Daily'
if [[ "$preferred_expense" != "$expected_preferred_expense" ]]; then
  echo "FAIL: canonical account list --prefer-role expense must stably place expenses first" >&2
  printf '%s\n' "$preferred_expense" >&2
  exit 1
fi

if ! grep -Fq "select_account '' 'posting account' 'expense'" tools/add-ui.sh; then
  echo "FAIL: multi-posting selector must request expense-preferred account order" >&2
  exit 1
fi

if ./tools/edit --base "$list_base" account list --bad > "$out_dir/account-list.out" 2>&1; then
  echo "FAIL: account list accepted unknown option" >&2
  cat "$out_dir/account-list.out" >&2
  exit 1
fi

# Account mutation is a separate writer qualification. During Phase 1 the
# existing account-add path remains on legacy accounts.tsv and is characterized
# independently from the canonical read-only selector above.
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp" "$out_dir"' EXIT
cp data/*.tsv "$tmp/"

preview="$(./tools/edit --base "$tmp" account add --name 'income:友人精算' --role income --dry-run --post-check none)"
grep -Fq $'income:友人精算\trole=income\tcurrency=JPY' <<< "$preview"
if grep -Fq 'income:友人精算' "$tmp/accounts.tsv"; then
  echo "FAIL: account add dry-run modified accounts.tsv" >&2
  exit 1
fi

./tools/edit --base "$tmp" account add --name 'income:友人精算' --role income --yes --post-check none >/dev/null
grep -Fxq $'income:友人精算\trole=income\tcurrency=JPY' "$tmp/accounts.tsv"
compgen -G "$tmp/.backup/accounts.tsv.*.bak" >/dev/null

if ./tools/edit --base "$tmp" account add --name 'income:友人精算' --role income --dry-run --post-check none >"$out_dir/account-add-duplicate.out" 2>&1; then
  echo "FAIL: account add accepted duplicate account" >&2
  exit 1
fi
if ./tools/edit --base "$tmp" account add --name 'expenses:食費2' --role income --dry-run --post-check none >"$out_dir/account-add-role.out" 2>&1; then
  echo "FAIL: account add accepted mismatched namespace and role" >&2
  exit 1
fi
if ./tools/edit --base "$tmp" account add --name 'assets:test' --role asset --type crypto --dry-run --post-check none >"$out_dir/account-add-type.out" 2>&1; then
  echo "FAIL: account add accepted unknown asset type" >&2
  exit 1
fi
echo "check-edit-bqn-account-list: OK"
