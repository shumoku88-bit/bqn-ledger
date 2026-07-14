#!/usr/bin/env bash
set -euo pipefail

fixture="fixtures/currency-m3-balances"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

failures=0
fail() { echo "FAIL: $*" >&2; failures=$((failures + 1)); }
pass() { echo "PASS: $*"; }

run_report_at() {
  local name="$1" base="$2"
  shift 2
  local status
  if tools/report "$base" "$@" >"$tmp/$name.out" 2>"$tmp/$name.err"; then
    return 0
  else
    status=$?
  fi
  echo "command failed: tools/report $base $*" >&2
  echo "exit: $status" >&2
  echo "stdout:" >&2
  cat "$tmp/$name.out" >&2
  echo "stderr:" >&2
  cat "$tmp/$name.err" >&2
  return 1
}

run_report() {
  local name="$1"
  shift
  run_report_at "$name" "$fixture" "$@"
}

make_ils_precision_fixture() {
  local dir="$1" amount="$2"
  cp -R "$fixture" "$dir"
  printf '2026-07-01\tJPY opening\tliabilities:jpy-card\tassets:jpy-cash\t1200\tcurrency=JPY\n' >"$dir/journal.tsv"
  printf '2026-07-02\tILS precision\tliabilities:ils-main\tassets:ils-main\t%s\tcurrency=ILS\n' "$amount" >>"$dir/journal.tsv"
}

expect_fail() {
  local name="$1" pattern="$2"
  shift 2
  set +e
  "$@" >"$tmp/$name.out" 2>"$tmp/$name.err"
  local status=$?
  set -e
  if [[ $status -eq 0 ]]; then
    fail "$name unexpectedly succeeded"
    return
  fi
  if grep -qF -- "$pattern" "$tmp/$name.out" "$tmp/$name.err"; then
    pass "$name fails closed (exit $status)"
  else
    fail "$name missing diagnostic: $pattern (exit $status)"
    cat "$tmp/$name.out" "$tmp/$name.err" >&2
  fi
}

if run_report jpy --section balances --currency JPY --no-color; then
  grep -qF 'Currency view: JPY (explicit selection)' "$tmp/jpy.out" || fail "JPY provenance missing"
  grep -qF 'assets:jpy-cash/JPY' "$tmp/jpy.out" || fail "JPY asset missing"
  grep -qF 'liabilities:jpy-card/JPY' "$tmp/jpy.out" || fail "JPY liability missing"
  grep -qE '^assets_total +\| +1200$' "$tmp/jpy.out" || fail "JPY assets total is not isolated"
  grep -qE '^liabilities_total +\| +-1200$' "$tmp/jpy.out" || fail "JPY liabilities total is not isolated"
  if grep -qF '/ILS' "$tmp/jpy.out" || grep -qF '₪' "$tmp/jpy.out"; then
    fail "JPY view leaked ILS account or amount"
  else
    pass "explicit JPY balances are isolated"
  fi
fi

if run_report ils --section balances --currency ILS --no-color; then
  grep -qF 'Currency view: ILS (explicit selection)' "$tmp/ils.out" || fail "ILS provenance missing"
  grep -qF 'assets:ils-main/ILS' "$tmp/ils.out" || fail "ILS main asset missing"
  grep -qF 'assets:ils-small/ILS' "$tmp/ils.out" || fail "ILS small asset missing"
  grep -qF '₪12.50' "$tmp/ils.out" || fail "ILS 12.50 is not exact"
  grep -qF '₪0.05' "$tmp/ils.out" || fail "ILS 0.05 is not exact"
  grep -qF -- '-₪12.50' "$tmp/ils.out" || fail "negative ILS sign placement is not exact"
  grep -qE '^assets_total +\| +₪12\.55$' "$tmp/ils.out" || fail "ILS assets total is not isolated"
  grep -qE '^liabilities_total +\| +-₪12\.55$' "$tmp/ils.out" || fail "ILS liabilities total is not isolated"
  if grep -qF '/JPY' "$tmp/ils.out" || grep -qF 'jpy-' "$tmp/ils.out"; then
    fail "ILS view leaked JPY account"
  else
    pass "explicit ILS balances and totals are isolated"
  fi
fi

make_ils_precision_fixture "$tmp/ils-integer" "12"
if run_report_at ils-integer "$tmp/ils-integer" --section balances --currency ILS --no-color; then
  grep -qF '₪12.00' "$tmp/ils-integer.out" \
    && pass "ILS integer source renders with fixed two decimals" \
    || fail "ILS integer source did not render as ₪12.00"
fi

make_ils_precision_fixture "$tmp/ils-one-decimal" "12.5"
if run_report_at ils-one-decimal "$tmp/ils-one-decimal" --section balances --currency ILS --no-color; then
  grep -qF '₪12.50' "$tmp/ils-one-decimal.out" \
    && pass "ILS one-decimal source scales exactly to two decimals" \
    || fail "ILS one-decimal source did not render as ₪12.50"
fi

make_ils_precision_fixture "$tmp/ils-three-decimal" "1.234"
expect_fail ils-three-decimal 'ILS source precision exceeds 2 fractional digits: calculation scale 3' \
  tools/report "$tmp/ils-three-decimal" --section balances --currency ILS --no-color
if grep -qF '== Account Balances ==' "$tmp/ils-three-decimal.out" || grep -qF '₪1.23' "$tmp/ils-three-decimal.out"; then
  fail "ILS three-decimal failure emitted balances or a rounded value"
else
  pass "ILS three-decimal source emits no balances or rounded value"
fi

if run_report default --section balances --no-color; then
  grep -qF 'Currency view: JPY (ledger default)' "$tmp/default.out" \
    && pass "no override uses ledger default provenance" \
    || fail "ledger default provenance missing"
fi

expect_fail unsupported 'unsupported selected currency: EUR' \
  tools/report "$fixture" --section balances --currency EUR --no-color
expect_fail other-section '--currency is supported only with human --section balances' \
  tools/report "$fixture" --section snapshot --currency JPY --no-color
expect_fail full-report '--currency is supported only with human --section balances' \
  tools/report "$fixture" --currency JPY --no-color
expect_fail list-sections '--currency is supported only with human --section balances' \
  tools/report "$fixture" --list-sections --currency JPY --no-color
expect_fail section-cache '--currency is supported only with human --section balances' \
  tools/report "$fixture" --write-section-cache "$tmp/cache" --currency JPY --no-color
expect_fail selected-json '--currency is supported only with human --section balances' \
  tools/report "$fixture" --section balances --format json --currency ILS

cp -R "$fixture" "$tmp/invalid-default"
printf 'DEFAULT_CURRENCY=EUR\n' >"$tmp/invalid-default/config.tsv"
expect_fail invalid-default 'unsupported default currency: EUR' \
  tools/report "$tmp/invalid-default" --section balances --no-color

cp -R "$fixture" "$tmp/mismatch"
printf '2026-07-04\tmismatch\tassets:jpy-cash\tliabilities:jpy-card\t1.00\tcurrency=ILS\n' >>"$tmp/mismatch/journal.tsv"
expect_fail account-row-mismatch 'account currency mismatch' \
  tools/report "$tmp/mismatch" --section balances --currency ILS --no-color

cp -R "$fixture" "$tmp/duplicate-account"
printf 'assets:jpy-cash\trole=asset\ttype=liquid\tcurrency=JPY\tcurrency=JPY\n' >"$tmp/duplicate-account/accounts.tsv"
tail -n +2 "$fixture/accounts.tsv" >>"$tmp/duplicate-account/accounts.tsv"
expect_fail duplicate-account-currency 'duplicate currency metadata' \
  tools/report "$tmp/duplicate-account" --section balances --currency JPY --no-color

# Existing non-selected JSON and JPY-only balance unit contracts remain unchanged.
if tools/report fixtures/src-next-golden --section balances --format json >"$tmp/legacy.json" 2>"$tmp/legacy.err" \
  && python3 - "$tmp/legacy.json" <<'PY'
import json, sys
root = json.load(open(sys.argv[1], encoding="utf-8"))
assert set(root) == {"accounts", "totals"}
PY
then
  pass "existing balances JSON schema remains unchanged"
else
  fail "existing balances JSON regression"
  cat "$tmp/legacy.err" >&2
fi

if [[ $failures -ne 0 ]]; then
  echo "FAILED: $failures Currency M3 balance check(s) failed" >&2
  exit 1
fi

echo "OK: Currency M3 selected balances checks passed" >&2
