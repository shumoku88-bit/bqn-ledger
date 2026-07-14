#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

fixture="fixtures/currency-usd-single"
tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

failures=0
fail() { echo "FAIL: $*" >&2; failures=$((failures + 1)); }
pass() { echo "PASS: $*"; }

# 1. Source integrity check passes
if bqn src_edit/journal_source_check.bqn "$fixture" >/dev/null 2>&1; then
  pass "source integrity check passes"
else
  fail "source integrity check failed"
fi

# 2. Editor preview retains decimal and currency metadata
preview="$(./tools/edit --base "$fixture" journal add --date 2026-08-02 --memo "test preview" --from assets:checking --to expenses:utilities --amount 1.23 --currency USD --dry-run --post-check none)"
if grep -qF $'2026-08-02\ttest preview\tassets:checking\texpenses:utilities\t1.23\tcurrency=USD' <<<"$preview"; then
  pass "editor preview retains decimal amount and currency metadata"
else
  fail "editor preview failed to retain decimals or currency"
  echo "Preview output:" >&2
  echo "$preview" >&2
fi

# 3. Report displays balances with symbol and correct scale (e.g., $12.34)
balances="$(./tools/report "$fixture" --section balances --currency USD --no-color)"
if grep -qF '$12.34' <<<"$balances"; then
  pass "report displays balances with symbol $ and exact scale"
else
  fail "report did not display exact scale with symbol (expected $12.34)"
  echo "Balances output:" >&2
  echo "$balances" >&2
fi

# 4. Out-of-scale amount 12.345 fails closed
set +e
./tools/edit --base "$fixture" journal add --date 2026-08-02 --memo "too precise" --from assets:checking --to expenses:utilities --amount 12.345 --currency USD --yes --post-check none >/dev/null 2>&1
rc=$?
set -e
if [ "$rc" -ne 0 ]; then
  pass "amount with 3 decimal places fails closed"
else
  fail "amount with 3 decimal places unexpectedly succeeded"
fi

# 5. Adding mismatched currency to USD account fails
set +e
./tools/edit --base "$fixture" journal add --date 2026-08-02 --memo "wrong currency" --from assets:checking --to expenses:utilities --amount 10 --currency JPY --yes --post-check none >/dev/null 2>&1
rc=$?
set -e
if [ "$rc" -ne 0 ]; then
  pass "mismatched currency on USD account fails closed"
else
  fail "mismatched currency on USD account unexpectedly succeeded"
fi

# 6. Mixed currencies in same arithmetic domain fails
mixed_base="$tmp_root/mixed"
cp -R "$fixture" "$mixed_base"
# Append a JPY transaction to journal.tsv
printf '2026-08-02\tJPY txn\tassets:checking\texpenses:utilities\t1000\tcurrency=JPY\n' >> "$mixed_base/journal.tsv"
set +e
report_out="$(./tools/report "$mixed_base" --no-color 2>&1)"
rc=$?
set -e
if [ "$rc" -ne 0 ] && grep -qF "mixed_currency_domains" <<<"$report_out"; then
  pass "mixed currencies reject in arithmetic domain"
else
  fail "mixed currencies in same domain did not reject as expected"
  echo "Report exit code: $rc" >&2
  echo "Report output:" >&2
  echo "$report_out" >&2
fi

# 7. Plan add decimal and currency
plan_base="$tmp_root/plan"
cp -R "$fixture" "$plan_base"
./tools/edit --base "$plan_base" plan add --date 2026-08-16 --memo "new plan" --from assets:checking --to expenses:utilities --amount 45.67 --currency USD --yes --post-check none >/dev/null
if grep -qF $'2026-08-16\tnew plan\tassets:checking\texpenses:utilities\t45.67\t' "$plan_base/plan.tsv"; then
  pass "plan add supports exact decimal and writes currency metadata"
else
  fail "plan add failed to save exact decimal or currency metadata"
fi

# 8. Budget add decimal and currency
budget_base="$tmp_root/budget"
cp -R "$fixture" "$budget_base"
./tools/edit --base "$budget_base" budget add --date 2026-08-02 --memo "new budget" --from budget:opening --to budget:utilities --amount 25.50 --currency USD --yes --post-check none >/dev/null
if grep -qF $'2026-08-02\tnew budget\tbudget:opening\tbudget:utilities\t25.50\t' "$budget_base/budget_alloc.tsv"; then
  pass "budget add supports exact decimal and writes currency metadata"
else
  fail "budget add failed to save exact decimal or currency metadata"
fi

if [ "$failures" -ne 0 ]; then
  echo "FAILED: $failures USD single currency check(s) failed" >&2
  exit 1
fi
echo "OK: USD single currency end-to-end checks passed"
