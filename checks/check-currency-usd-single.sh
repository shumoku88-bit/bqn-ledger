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

# 7. Complete decimal plan lifecycle (add -> edit -> finish)
lifecycle_base="$tmp_root/lifecycle"
cp -R "$fixture" "$lifecycle_base"

# plan add
./tools/edit --base "$lifecycle_base" plan add --date 2026-08-15 --memo "subscription" --from assets:checking --to expenses:utilities --amount 49.99 --currency USD --yes --post-check lint >/dev/null
plan_row="$(tail -n 1 "$lifecycle_base/plan.tsv")"
if grep -qF $'currency=USD' <<<"$plan_row" && grep -qF $'49.99' <<<"$plan_row"; then
  pass "lifecycle step 1: plan add writes exact decimal and currency=USD"
else
  fail "lifecycle step 1 failed: plan add row was '$plan_row'"
fi

# Extract plan ID
plan_id="$(echo "$plan_row" | grep -o 'plan_id=[^[:space:]]*' | cut -d= -f2)"
if [ -n "$plan_id" ]; then
  pass "lifecycle step 1a: plan ID generated: $plan_id"
else
  fail "lifecycle step 1a failed: could not extract plan ID from '$plan_row'"
fi

# plan edit (modify amount to another decimal)
./tools/edit --base "$lifecycle_base" plan edit --id "$plan_id" --amount 45.67 --yes --post-check lint >/dev/null
edited_row="$(grep "$plan_id" "$lifecycle_base/plan.tsv")"
if grep -qF $'45.67' <<<"$edited_row" && grep -qF $'currency=USD' <<<"$edited_row"; then
  pass "lifecycle step 2: plan edit updates amount to 45.67 and preserves currency=USD"
else
  fail "lifecycle step 2 failed: edited row was '$edited_row'"
fi

# plan finish with explicit actual decimal amount
./tools/edit --base "$lifecycle_base" plan finish --id "$plan_id" --actual-date 2026-07-14 --actual-amount 40.00 --yes --apply --post-check lint >/dev/null
finished_row="$(tail -n 1 "$lifecycle_base/journal.tsv")"
if grep -qF $'2026-07-14' <<<"$finished_row" && grep -qF $'40.00' <<<"$finished_row" && grep -qF "plan_id=$plan_id" <<<"$finished_row" && grep -qF 'currency=USD' <<<"$finished_row"; then
  pass "lifecycle step 3: plan finish with --actual-amount appends correct journal row with currency=USD"
else
  fail "lifecycle step 3 failed: finished journal row was '$finished_row'"
fi

# 8. Plan finish with implicit (empty) actual amount (preserves planned amount)
./tools/edit --base "$lifecycle_base" plan add --date 2026-08-16 --memo "implicit" --from assets:checking --to expenses:utilities --amount 19.99 --currency USD --yes --post-check lint >/dev/null
plan_row_2="$(tail -n 1 "$lifecycle_base/plan.tsv")"
plan_id_2="$(echo "$plan_row_2" | grep -o 'plan_id=[^[:space:]]*' | cut -d= -f2)"
./tools/edit --base "$lifecycle_base" plan finish --id "$plan_id_2" --actual-date 2026-07-14 --yes --apply --post-check lint >/dev/null
finished_row_2="$(tail -n 1 "$lifecycle_base/journal.tsv")"
if grep -qF $'19.99' <<<"$finished_row_2" && grep -qF "plan_id=$plan_id_2" <<<"$finished_row_2" && grep -qF 'currency=USD' <<<"$finished_row_2"; then
  pass "lifecycle step 4: plan finish with empty actual amount preserves original planned amount 19.99 and currency=USD"
else
  fail "lifecycle step 4 failed: finished journal row was '$finished_row_2'"
fi

# 9. Budget add decimal and currency
budget_base="$tmp_root/budget"
cp -R "$fixture" "$budget_base"
./tools/edit --base "$budget_base" budget add --date 2026-08-02 --memo "new budget" --from budget:opening --to budget:utilities --amount 25.50 --currency USD --yes --post-check lint >/dev/null
budget_row="$(tail -n 1 "$budget_base/budget_alloc.tsv")"
if grep -qF $'25.50' <<<"$budget_row" && grep -qF $'currency=USD' <<<"$budget_row"; then
  pass "budget add supports exact decimal and writes currency=USD metadata"
else
  fail "budget add failed to save exact decimal or currency metadata: '$budget_row'"
fi

# 10. Run source integrity check on mutated bases
if bqn src_edit/journal_source_check.bqn "$lifecycle_base" >/dev/null 2>&1; then
  pass "mutated lifecycle base passes source integrity"
else
  fail "mutated lifecycle base failed source integrity check"
fi

if bqn src_edit/journal_source_check.bqn "$budget_base" >/dev/null 2>&1; then
  pass "mutated budget base passes source integrity"
else
  fail "mutated budget base failed source integrity check"
fi

if [ "$failures" -ne 0 ]; then
  echo "FAILED: $failures USD single currency check(s) failed" >&2
  exit 1
fi
echo "OK: USD single currency end-to-end checks passed"
