#!/usr/bin/env bash
set -euo pipefail

if [[ -f src_next/report.bqn ]]; then ROOT_DIR=$PWD; else ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; fi
cd "$ROOT_DIR"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
base="$tmp/base"
mkdir -p "$base"

cat >"$base/accounts.tsv" <<'EOF'
assets:bank-jpy	role=asset	type=liquid	currency=JPY
expenses:food-jpy	role=expense	currency=JPY
assets:cash-ils	role=asset	type=liquid	currency=ILS
assets:balance-ils	role=asset	type=liquid	currency=ILS
expenses:food-ils	role=expense	currency=ILS
assets:cash-usd	role=asset	type=liquid	currency=USD
expenses:food-usd	role=expense	currency=USD
budget:pool-jpy	role=budget	currency=JPY
budget:daily-jpy	role=budget	currency=JPY
budget:pool-ils	role=budget	currency=ILS
budget:daily-ils	role=budget	currency=ILS
EOF
cat >"$base/config.tsv" <<'EOF'
ACTUAL_JOURNAL_FILE	source.journal
DEFAULT_CURRENCY	JPY
EOF
cat >"$base/cycle.tsv" <<'EOF'
mode	fixed
start	2026-07-01
end_exclusive	2026-08-01
EOF
cat >"$base/plan.tsv" <<'EOF'
2026-07-29	synthetic JPY plan	assets:bank-jpy	expenses:food-jpy	100	currency=JPY
2026-07-29	synthetic ILS plan	assets:balance-ils	expenses:food-ils	2.50	currency=ILS
EOF
cat >"$base/budget_alloc.tsv" <<'EOF'
2026-07-01	synthetic JPY budget	budget:pool-jpy	budget:daily-jpy	50	currency=JPY
2026-07-01	synthetic ILS budget	budget:pool-ils	budget:daily-ils	1.25	currency=ILS
EOF
cat >"$base/source.journal" <<'EOF'
commodity JPY

commodity ILS

commodity USD

account assets:bank-jpy

account expenses:food-jpy

account assets:cash-ils

account assets:balance-ils

account expenses:food-ils

account assets:cash-usd

account expenses:food-usd

2026-07-01 * synthetic JPY seed
  assets:bank-jpy  -1000 JPY
  expenses:food-jpy  1000 JPY

2026-07-02 * synthetic ILS balance seed
  assets:balance-ils  -20.00 ILS
  assets:cash-ils  20.00 ILS
EOF

sha_file() { shasum -a 256 "$1" | awk '{print $1}'; }
expect_fail_unchanged() {
  local label=$1; shift
  local before after
  before="$(sha_file "$base/source.journal")"
  if ./tools/edit --base "$base" "$@" >"$tmp/$label.out" 2>&1; then
    echo "FAIL: $label unexpectedly succeeded" >&2
    cat "$tmp/$label.out" >&2
    exit 1
  fi
  after="$(sha_file "$base/source.journal")"
  [[ "$before" == "$after" ]] || { echo "FAIL: $label changed Journal" >&2; exit 1; }
}

# Public ordinary-add path: exact ILS expense, complete-source admission, and
# Stage 2A currency-proof carriage are all exercised by mandatory validation.
./tools/edit --base "$base" journal add \
  --date 2026-07-25 --memo 'synthetic ILS meal' \
  --from assets:cash-ils --to expenses:food-ils --amount 12.34 --currency ILS \
  --yes --post-check lint >"$tmp/ils-add.out"
grep -q 'Mandatory native validation: OK' "$tmp/ils-add.out"
grep -q $'OK\tNATIVE_JOURNAL_CANDIDATE\tordinary' "$tmp/ils-add.out"
grep -q 'expenses:food-ils    12.34 ILS' "$base/source.journal"

# Existing omitted-currency behavior remains JPY.
./tools/edit --base "$base" journal add \
  --date 2026-07-25 --memo 'synthetic JPY compatibility' \
  --from assets:bank-jpy --to expenses:food-jpy --amount 10 \
  --yes --post-check lint >"$tmp/jpy-add.out"
grep -q 'expenses:food-jpy    10 JPY' "$base/source.journal"

# USD follows the same registry-driven writer boundary.
./tools/edit --base "$base" journal add \
  --date 2026-07-25 --memo 'synthetic USD witness' \
  --from assets:cash-usd --to expenses:food-usd --amount 7.50 --currency USD \
  --yes --post-check lint >"$tmp/usd-add.out"
grep -q 'expenses:food-usd    7.50 USD' "$base/source.journal"

expect_fail_unchanged unsupported journal add --date 2026-07-26 --memo bad --from assets:cash-ils --to expenses:food-ils --amount 1 --currency EUR --yes
expect_fail_unchanged precision journal add --date 2026-07-26 --memo bad --from assets:cash-ils --to expenses:food-ils --amount 1.001 --currency ILS --yes
expect_fail_unchanged malformed journal add --date 2026-07-26 --memo bad --from assets:cash-ils --to expenses:food-ils --amount 1x --currency ILS --yes
expect_fail_unchanged missing-posting journal multi-add --date 2026-07-26 --description bad --currency ILS --posting assets:cash-ils=-1 --yes
expect_fail_unchanged account-mismatch journal add --date 2026-07-26 --memo bad --from assets:bank-jpy --to expenses:food-ils --amount 1 --currency ILS --yes
expect_fail_unchanged mixed-domain journal multi-add --date 2026-07-26 --description bad --currency ILS --posting assets:cash-ils=-1 --posting assets:bank-jpy=1 --yes
expect_fail_unchanged zero journal add --date 2026-07-26 --memo bad --from assets:cash-ils --to expenses:food-ils --amount 0 --currency ILS --yes
expect_fail_unchanged unbalanced journal multi-add --date 2026-07-26 --description bad --currency ILS --posting assets:cash-ils=-1 --posting expenses:food-ils=2 --yes

# End-to-end selected-domain read: Actual + plan + budget compose at ILS scale,
# while JPY and USD accounts remain absent and no cross-currency total exists.
./tools/report "$base" --section balances --currency ILS >"$tmp/ils-balances.out"
grep -q 'Currency view: ILS' "$tmp/ils-balances.out"
grep -q 'assets:cash-ils/ILS' "$tmp/ils-balances.out"
grep -q 'assets:balance-ils/ILS' "$tmp/ils-balances.out"
grep -q 'expenses:food-ils/ILS' "$tmp/ils-balances.out"
grep -q '₪12.34' "$tmp/ils-balances.out"
! grep -q 'bank-jpy' "$tmp/ils-balances.out"
! grep -q 'cash-usd' "$tmp/ils-balances.out"

./tools/report "$base" --section balances --currency JPY >"$tmp/jpy-balances.out"
grep -q 'Currency view: JPY' "$tmp/jpy-balances.out"
grep -q 'assets:bank-jpy/JPY' "$tmp/jpy-balances.out"
! grep -q 'cash-ils' "$tmp/jpy-balances.out"

echo 'check-israel-ils-usable-vertical-slice: OK'
