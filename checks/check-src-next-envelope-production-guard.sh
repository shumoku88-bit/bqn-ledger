#!/usr/bin/env bash
set -euo pipefail

# Guard the Stage 4a fixture-only envelope computation prototype on production data.
# Production src_next summary must stay unavailable/fallback and must not expose
# polished envelope remaining, safe_remaining, daily_amount, or per-day advice.

base="${1:-data}"
if [ ! -d "$base" ]; then
  echo "ERROR: base directory not found: $base" >&2
  exit 2
fi

output="$(mktemp)"
trap 'rm -f "$output"' EXIT

failures=0
fail() { echo "FAIL: $*" >&2; failures=$((failures + 1)); }
pass() { echo "PASS: $*"; }

value() {
  local key="$1" file="$2"
  awk -F': ' -v key="$key" '$1 == key { print $2; exit }' "$file"
}

expect_value() {
  local key="$1" expected="$2" actual
  actual="$(value "$key" "$output")"
  if [ "$actual" = "$expected" ]; then
    pass "$key is $expected"
  else
    fail "$key expected '$expected' but got '${actual:-<missing>}'"
  fi
}

tools/report-next-summary "$base" > "$output" 2>/dev/null

if grep -qF -- '--- SrcNext Envelope Computation ---' "$output"; then
  pass "SrcNext Envelope Computation section found"
else
  fail "SrcNext Envelope Computation section missing"
fi

# Production data must not opt into the fixture-only policy source. All polished
# envelope amount fields stay unavailable (any unavailable/* reason), and status
# must not become computed.
for field in \
  src_next_envelope_target_id \
  src_next_envelope_label \
  src_next_envelope_selector \
  src_next_envelope_allocated \
  src_next_envelope_actual_spent \
  src_next_envelope_remaining \
  src_next_envelope_status; do
  actual="$(value "$field" "$output")"
  case "$actual" in
    unavailable/*) pass "$field is $actual" ;;
    *) fail "$field expected 'unavailable/*' but got '${actual:-<missing>}'" ;;
  esac
done

if grep -qE '^src_next_envelope_status:[[:space:]]*computed$' "$output"; then
  fail "production envelope status became computed"
else
  pass "production envelope status is not computed"
fi

if grep -qE '^src_next_envelope_(allocated|actual_spent|remaining):[[:space:]]*-?[0-9]' "$output"; then
  fail "production envelope output contains polished numeric amount fields"
else
  pass "production envelope amount fields are not polished numeric values"
fi

# Later-work fields and per-day advice must not leak into the Stage 4a surface.
for banned in 'safe_remaining' 'daily_amount' 'per-day allowance' 'per_day_allowance'; do
  if grep -qF -- "$banned" "$output"; then
    fail "production summary contains banned later-work field/text: $banned"
  else
    pass "production summary excludes: $banned"
  fi
done

# Snapshot household advice must remain fallback/current-engine, not src_next
# computed food/daily/flex/reserve remaining or outlook daily amount.
for text in \
  '  daily_remaining:   fallback/current-engine' \
  '  food_remaining:    fallback/current-engine' \
  '  flex_remaining:    fallback/current-engine' \
  '  reserve_remaining: fallback/current-engine' \
  '  outlook_daily: fallback/current-engine'; do
  if grep -qF -- "$text" "$output"; then
    pass "production summary contains fallback text: $text"
  else
    fail "production summary missing fallback text: $text"
  fi
done

if grep -qE '^  (daily_remaining|food_remaining|flex_remaining|reserve_remaining|outlook_daily):[[:space:]]*-?[0-9]' "$output"; then
  fail "production summary exposes numeric household advice remaining/outlook"
else
  pass "production summary does not expose numeric household advice remaining/outlook"
fi

if [ "$failures" -eq 0 ]; then
  echo "OK: src_next envelope production guard passed for base: $base" >&2
  exit 0
else
  echo "FAILED: $failures src_next envelope production guard check(s) failed" >&2
  exit 1
fi
