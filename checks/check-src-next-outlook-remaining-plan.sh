#!/usr/bin/env bash
set -euo pipefail

# Guard the Slice B checked plan owner, completion evidence, asymmetric anchor
# policy, and Outlook fail-closed propagation. Detailed behavior lives in BQN.

failures=0
fail() { echo "FAIL: $*" >&2; failures=$((failures + 1)); }
pass() { echo "PASS: $*"; }

focused="$(mktemp)"
summary="$(mktemp)"
trap 'rm -f "$focused" "$summary"' EXIT

if bqn tests/test_src_next_outlook_remaining_plan_numeric_owner.bqn >"$focused" 2>&1; then
  pass "focused checked remaining-plan behavior"
else
  cat "$focused" >&2
  fail "focused checked remaining-plan behavior"
fi

if grep -qF 'test_src_next_outlook_remaining_plan_numeric_owner.bqn: OK' "$focused"; then
  pass "focused test completion marker"
else
  fail "focused test completion marker missing"
fi

if grep -qF 'ctx.posting_rows' src_next/outlook_remaining_plan.bqn \
  && grep -qF 'plan_rows.PlanId' src_next/outlook_remaining_plan.bqn; then
  pass "checked postings and plan-ID evidence are explicit owners"
else
  fail "checked posting or completion owner missing"
fi

if grep -qF '•BQN' src_next/outlook_remaining_plan.bqn; then
  fail "remaining-plan helper reparses source amounts"
else
  pass "remaining-plan helper has no source amount parser"
fi

if grep -qF 'remaining_plan.BuildAt' src_next/outlook.bqn; then
  pass "Outlook connects the checked remaining-plan helper"
else
  fail "Outlook checked remaining-plan connection missing"
fi

for legacy in 'InRemaining ←' 'PlanLiquidDelta ←' 'GetMetaVal ←'; do
  if grep -qF "$legacy" src_next/outlook.bqn; then
    fail "legacy Outlook remaining parser survives: $legacy"
  else
    pass "legacy Outlook remaining parser absent: $legacy"
  fi
done

if tools/report-next-summary fixtures/outlook-remaining-plan-numeric-owner-target >"$summary" 2>&1; then
  pass "target fixture compact summary renders"
else
  cat "$summary" >&2
  fail "target fixture compact summary failed"
fi

for expected in \
  'src_next_outlook_status: ok' \
  'src_next_outlook_reason: outlook_active'; do
  if grep -qF "$expected" "$summary"; then
    pass "compact Outlook field: $expected"
  else
    fail "compact Outlook field missing: $expected"
  fi
done

if [ "$failures" -eq 0 ]; then
  echo "OK: src_next Outlook remaining-plan check passed" >&2
  exit 0
fi

echo "FAILED: $failures Outlook remaining-plan check(s) failed" >&2
exit 1
