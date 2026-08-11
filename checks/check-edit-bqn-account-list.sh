#!/usr/bin/env bash
set -euo pipefail
trap 'rc=$?; echo "::error file=checks/check-edit-bqn-account-list.sh::debug failed command: $BASH_COMMAND" >&2; exit "$rc"' ERR

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

list_base="fixtures/canonical-household-v1"
out_dir="$(mktemp -d)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp" "$out_dir"' EXIT

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

# Canonical Account mutation qualification.
cp "$list_base/accounts.journal" "$tmp/accounts.journal"
printf 'legacy sentinel\n' >"$tmp/accounts.tsv"
legacy_before="$(shasum -a 256 "$tmp/accounts.tsv" | awk '{print $1}')"
account_before="$(shasum -a 256 "$tmp/accounts.journal" | awk '{print $1}')"

preview="$(./tools/edit --base "$tmp" account add --name 'Income:Friend-Settlement' --role income --currency JPY --dry-run --post-check none)"
grep -Fq 'Target:' <<<"$preview"
grep -Fq '/accounts.journal' <<<"$preview"
grep -Fq 'account Income:Friend-Settlement' <<<"$preview"
grep -Fq '  type: Income' <<<"$preview"
grep -Fq '  commodity: JPY' <<<"$preview"
[[ "$(shasum -a 256 "$tmp/accounts.journal" | awk '{print $1}')" == "$account_before" ]] || { echo 'FAIL: Account dry-run modified accounts.journal' >&2; exit 1; }
[[ "$(shasum -a 256 "$tmp/accounts.tsv" | awk '{print $1}')" == "$legacy_before" ]] || { echo 'FAIL: Account dry-run modified legacy accounts.tsv' >&2; exit 1; }

apply_out="$(./tools/edit --base "$tmp" account add --name 'Income:Friend-Settlement' --role income --currency JPY --yes --post-check lint 2>&1)"
grep -Fq 'Mandatory Account validation: OK' <<<"$apply_out"
grep -Fq 'Post-check: OK' <<<"$apply_out"
grep -Fq 'account Income:Friend-Settlement' "$tmp/accounts.journal"
grep -Fq '  type: Income' "$tmp/accounts.journal"
grep -Fq '  commodity: JPY' "$tmp/accounts.journal"
compgen -G "$tmp/.backup/accounts.journal.*.bak" >/dev/null
[[ "$(shasum -a 256 "$tmp/accounts.tsv" | awk '{print $1}')" == "$legacy_before" ]] || { echo 'FAIL: canonical Account write touched legacy accounts.tsv' >&2; exit 1; }

if ./tools/edit --base "$tmp" account add --name 'Income:Friend-Settlement' --role income --currency JPY --dry-run --post-check none >"$out_dir/account-add-duplicate.out" 2>&1; then
  echo "FAIL: account add accepted duplicate canonical Account" >&2
  exit 1
fi
if ./tools/edit --base "$tmp" account add --name 'Expenses:Food2' --role income --currency JPY --dry-run --post-check none >"$out_dir/account-add-role.out" 2>&1; then
  echo "FAIL: account add accepted mismatched namespace and role" >&2
  exit 1
fi
if ./tools/edit --base "$tmp" account add --name 'Assets:Savings2' --role asset --type savings --currency JPY --dry-run --post-check none >"$out_dir/account-add-type.out" 2>&1; then
  echo "FAIL: canonical Account writer accepted legacy Household classification" >&2
  exit 1
fi
grep -Fq 'Household classification belongs in household.toml' "$out_dir/account-add-type.out"

# The old system default cannot redirect Account writes back to accounts.tsv.
grep -Fq $'DEFAULT_ACCOUNTS_FILE\taccounts.tsv' config/system_defaults.tsv
second_preview="$(./tools/edit --base "$tmp" account add --name 'Expenses:Utilities' --role expense --currency JPY --dry-run --post-check none)"
grep -Fq '/accounts.journal' <<<"$second_preview"
! grep -Fq '/accounts.tsv' <<<"$second_preview"

# Immediate pre-rename stale detection preserves the concurrent writer and creates no backup for the attempted Account.
stale="$out_dir/stale"
mkdir "$stale"
cp "$list_base/accounts.journal" "$stale/accounts.journal"
stale_before_count="$(find "$stale" -type f -path '*/.backup/*' | wc -l | tr -d ' ')"
mutate_account_target() { printf '\n; concurrent Account writer\n' >>"$ACCOUNT_TARGET"; }
export -f mutate_account_target
export ACCOUNT_TARGET="$stale/accounts.journal"
set +e
BQN_LEDGER_TEST_MODE=1 SAFE_WRITE_TEST_BEFORE_APPEND_RENAME_HOOK=mutate_account_target \
  ./tools/edit --base "$stale" account add --name 'Expenses:Utilities' --role expense --currency JPY --yes --post-check none >"$out_dir/stale.out" 2>&1
stale_rc=$?
set -e
[[ "$stale_rc" -ne 0 ]] || { echo 'FAIL: stale Account append succeeded' >&2; exit 1; }
grep -Fqx '; concurrent Account writer' <(tail -n 1 "$stale/accounts.journal")
! grep -Fq 'account Expenses:Utilities' "$stale/accounts.journal"
[[ "$(find "$stale" -type f -path '*/.backup/*' | wc -l | tr -d ' ')" == "$stale_before_count" ]] || { echo 'FAIL: stale Account append left backup evidence' >&2; exit 1; }

# Mandatory post-admission failure rolls the exact original bytes back.
rollback="$out_dir/rollback"
mkdir "$rollback"
cp "$list_base/accounts.journal" "$rollback/accounts.journal"
rollback_before="$(shasum -a 256 "$rollback/accounts.journal" | awk '{print $1}')"
set +e
BQN_LEDGER_TEST_MODE=1 EDIT_BQN_TEST_FORCE_ACCOUNT_POST_CHECK_FAIL=1 \
  ./tools/edit --base "$rollback" account add --name 'Expenses:Utilities' --role expense --currency JPY --yes --post-check none >"$out_dir/rollback.out" 2>&1
rollback_rc=$?
set -e
[[ "$rollback_rc" -ne 0 ]] || { echo 'FAIL: forced Account post-admission failure succeeded' >&2; exit 1; }
[[ "$(shasum -a 256 "$rollback/accounts.journal" | awk '{print $1}')" == "$rollback_before" ]] || { echo 'FAIL: Account rollback did not restore original bytes' >&2; exit 1; }
grep -Fq 'Mandatory Account validation: FAILED' "$out_dir/rollback.out"
grep -Fq 'Rollback: restored original bytes' "$out_dir/rollback.out"
compgen -G "$rollback/.backup/accounts.journal.*.bak" >/dev/null

# A later writer wins over rollback and is never overwritten.
later="$out_dir/later"
mkdir "$later"
cp "$list_base/accounts.journal" "$later/accounts.journal"
later_account_writer() { printf '\n; later Account writer survives\n' >>"$LATER_ACCOUNT_TARGET"; }
export -f later_account_writer
export LATER_ACCOUNT_TARGET="$later/accounts.journal"
set +e
BQN_LEDGER_TEST_MODE=1 EDIT_BQN_TEST_FORCE_ACCOUNT_POST_CHECK_FAIL=1 EDIT_BQN_TEST_BEFORE_POSTCHECK_ROLLBACK_HOOK=later_account_writer \
  ./tools/edit --base "$later" account add --name 'Expenses:Utilities' --role expense --currency JPY --yes --post-check none >"$out_dir/later.out" 2>&1
later_rc=$?
set -e
[[ "$later_rc" -ne 0 ]] || { echo 'FAIL: later-writer Account rollback unexpectedly succeeded' >&2; exit 1; }
grep -Fqx '; later Account writer survives' <(tail -n 1 "$later/accounts.journal")
grep -Fq 'Rollback: refused' "$out_dir/later.out"

# Invalid canonical Account source fails closed before preview/write.
invalid="$out_dir/invalid"
mkdir "$invalid"
printf 'account Broken\n  type: Unknown\n' >"$invalid/accounts.journal"
invalid_before="$(shasum -a 256 "$invalid/accounts.journal" | awk '{print $1}')"
if ./tools/edit --base "$invalid" account add --name 'Income:X' --role income --currency JPY --yes --post-check none >"$out_dir/invalid.out" 2>&1; then
  echo 'FAIL: Account writer accepted invalid canonical source' >&2
  exit 1
fi
[[ "$(shasum -a 256 "$invalid/accounts.journal" | awk '{print $1}')" == "$invalid_before" ]]
[[ ! -d "$invalid/.backup" ]]

if rg -n 'accounts\.tsv|DEFAULT_ACCOUNTS_FILE' src_edit/account_add_cmd.bqn src_edit/account_validate_cmd.bqn; then
  echo 'FAIL: canonical Account writer BQN owner still depends on legacy Accounts source selection' >&2
  exit 1
fi

echo "check-edit-bqn-account-list: OK"
