#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
unset LEDGER_DATA_DIR

work="$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-account-add-contract.XXXXXX")"
trap 'rm -rf "$work"' EXIT
base="$work/household"
cp -R fixtures/canonical-household-v1 "$base"

sha_file() {
  shasum -a 256 "$1" | awk '{print $1}'
}

accounts="$base/accounts.journal"
before="$(sha_file "$accounts")"

# The canonical Account declaration owner has five roles on one aligned
# role/type/namespace axis. Dry-run every role through the public writer path.
while IFS=$'\t' read -r role name expected_type; do
  out="$(tools/edit --base "$base" account add \
    --name "$name" --role "$role" --currency JPY --dry-run --post-check none)"
  grep -Fq "account $name" <<<"$out" || {
    echo "FAIL: Account Add preview missing $name" >&2
    exit 1
  }
  grep -Fq "  type: $expected_type" <<<"$out" || {
    echo "FAIL: Account Add role/type projection missing $role -> $expected_type" >&2
    exit 1
  }
  grep -Fq '  commodity: JPY' <<<"$out" || {
    echo "FAIL: Account Add preview lost explicit Commodity" >&2
    exit 1
  }
done <<'EOF'
asset	assets:review-asset	Asset
liability	liabilities:review-liability	Liability
equity	equity:review-equity	Equity
income	income:review-income	Income
expense	expenses:review-expense	Expense
EOF

[[ "$(sha_file "$accounts")" == "$before" ]] || {
  echo 'FAIL: Account Add dry-run modified canonical accounts.journal' >&2
  exit 1
}

expect_fail_unchanged() {
  local label="$1" expected="$2"
  shift 2
  local out rc after
  out="$work/$label.out"
  set +e
  tools/edit --base "$base" account add "$@" --yes --post-check none >"$out" 2>&1
  rc=$?
  set -e
  if [[ $rc -eq 0 ]]; then
    echo "FAIL: $label unexpectedly succeeded" >&2
    cat "$out" >&2
    exit 1
  fi
  grep -Fq -- "$expected" "$out" || {
    echo "FAIL: $label diagnostic missing: $expected" >&2
    cat "$out" >&2
    exit 1
  }
  after="$(sha_file "$accounts")"
  [[ "$after" == "$before" ]] || {
    echo "FAIL: $label modified canonical accounts.journal" >&2
    exit 1
  }
}

# A namespace by itself is not an Account identity. The canonical writer, not a
# disconnected legacy TSV validator, owns this fail-closed rule.
expect_fail_unchanged empty-suffix \
  'account name must include a name after namespace: equity:' \
  --name 'equity:' --role equity --currency JPY

# Household classification no longer rides inside Account declarations.
expect_fail_unchanged legacy-type \
  'legacy --type Household classification belongs in household.toml; omit --type' \
  --name 'assets:legacy-type' --role asset --type liquid --currency JPY

expect_fail_unchanged namespace-mismatch \
  'account namespace does not match role' \
  --name 'assets:not-income' --role income --currency JPY

expect_fail_unchanged retired-budget-role \
  'role must be asset, liability, equity, income, or expense' \
  --name 'budget:retired' --role budget --currency JPY

echo 'check-edit-bqn-account-add-contract: ok'
