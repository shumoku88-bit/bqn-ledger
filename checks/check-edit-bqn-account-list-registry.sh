#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
unset LEDGER_DATA_DIR

work="$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-account-list-registry.XXXXXX")"
trap 'rm -rf "$work"' EXIT
base="$work/household"
cp -R fixtures/canonical-household-v1 "$base"

cat >>"$base/accounts.journal" <<'EOF'

account Assets:Dollar
  type: Asset
  commodity: USD

account Expenses:Dollar-Food
  type: Expense
  commodity: USD
EOF

# USD is registry-supported even though the retired validator helper only knew
# the older JPY/ILS pair. Account List must follow the canonical registry owner.
usd="$(tools/edit --base "$base" account list --currency USD)"
grep -Fxq 'Assets:Dollar' <<<"$usd" || {
  echo 'FAIL: Account List rejected or lost registry-supported USD asset' >&2
  printf '%s\n' "$usd" >&2
  exit 1
}
grep -Fxq 'Expenses:Dollar-Food' <<<"$usd" || {
  echo 'FAIL: Account List lost registry-supported USD expense' >&2
  printf '%s\n' "$usd" >&2
  exit 1
}
if grep -Fxq 'Assets:Bank' <<<"$usd"; then
  echo 'FAIL: USD Account List leaked JPY account' >&2
  exit 1
fi

usd_expense="$(tools/edit --base "$base" account list --role expense --currency USD)"
[[ "$usd_expense" == 'Expenses:Dollar-Food' ]] || {
  echo 'FAIL: role + registry currency filters did not compose' >&2
  printf '%s\n' "$usd_expense" >&2
  exit 1
}

if tools/edit --base "$base" account list --currency EUR >"$work/eur.out" 2>&1; then
  echo 'FAIL: Account List accepted unsupported EUR' >&2
  exit 1
fi
grep -Fq 'unsupported selected currency: EUR' "$work/eur.out" || {
  echo 'FAIL: Account List unsupported-currency diagnostic is not registry-owned' >&2
  cat "$work/eur.out" >&2
  exit 1
}

if grep -Fq 'validate.bqn' src_edit/account_list_cmd.bqn; then
  echo 'FAIL: Account List still delegates currency admission to legacy validate.bqn' >&2
  exit 1
fi

echo 'check-edit-bqn-account-list-registry: ok'
