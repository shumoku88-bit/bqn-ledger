#!/usr/bin/env bash
set -euo pipefail

if [ -f "src_next/report.bqn" ]; then
  ROOT_DIR="$PWD"
else
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
fi
cd "$ROOT_DIR"

base="data"
out_dir="$(mktemp -d)"
trap 'rm -rf "$out_dir"' EXIT

actual_asset="$(./tools/edit --base "$base" account list --role asset)"
if ! grep -Fxq 'assets:bank' <<< "$actual_asset"; then
  echo "FAIL: account list --role asset missing assets:bank" >&2
  printf '%s\n' "$actual_asset" >&2
  exit 1
fi
if grep -Fxq 'expenses:食費' <<< "$actual_asset"; then
  echo "FAIL: account list --role asset included expense account" >&2
  printf '%s\n' "$actual_asset" >&2
  exit 1
fi

actual_expense="$(./tools/edit --base "$base" account list --role expense)"
if ! grep -Fxq 'expenses:食費' <<< "$actual_expense"; then
  echo "FAIL: account list --role expense missing expenses:食費" >&2
  printf '%s\n' "$actual_expense" >&2
  exit 1
fi
if grep -Fxq 'assets:bank' <<< "$actual_expense"; then
  echo "FAIL: account list --role expense included asset account" >&2
  printf '%s\n' "$actual_expense" >&2
  exit 1
fi

actual_missing_role="$(./tools/edit --base "$base" account list --role does-not-exist)"
if [[ -n "$actual_missing_role" ]]; then
  echo "FAIL: account list --role does-not-exist should be empty" >&2
  printf '%s\n' "$actual_missing_role" >&2
  exit 1
fi

actual_all="$(./tools/edit --base "$base" account list)"
for account in 'assets:bank' 'expenses:食費' 'income:年金' 'budget:opening'; do
  if ! grep -Fxq "$account" <<< "$actual_all"; then
    echo "FAIL: account list missing $account" >&2
    printf '%s\n' "$actual_all" >&2
    exit 1
  fi
done

if ./tools/edit --base "$base" account list --bad > "$out_dir/account-list.out" 2>&1; then
  echo "FAIL: account list accepted unknown option" >&2
  cat "$out_dir/account-list.out" >&2
  exit 1
fi

# account add uses the same BQN-owned account contract and safe append path.
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
