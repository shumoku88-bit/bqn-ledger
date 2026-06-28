#!/usr/bin/env bash
set -euo pipefail
export NO_COLOR=1

# checks/check-missing-role-fallback.sh
# Check: missing-role-fallback

# Resolve repo root
SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

# ── Test state ──
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); }
fail() { FAIL=$((FAIL + 1)); echo "  FAIL: $1" >&2; }

# ── Temp dir ──
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

# ── Assert helpers ──
assert_eq() {
  local expected="$1" actual="$2" label="${3:-}"
  if [ "$expected" = "$actual" ]; then
    pass
  else
    fail "${label:-assert_eq}: expected [$expected] got [$actual]"
  fi
}

assert_contains() {
  local needle="$1" haystack="$2" label="${3:-}"
  if echo "$haystack" | grep -qF "$needle"; then
    pass
  else
    fail "${label:-assert_contains}: [$needle] not found"
  fi
}

# ── Tests ──

echo "Running src_next engine on missing role fallback fixture..." >&2
out=$(tools/report-next-summary fixtures/src-next-missing-role-fallback 2>/dev/null || true)

# Check fallback detection
assert_contains "src_next_household_metadata_expense_accounts_total: 0" "$out" "expenses count fallback is 0"
assert_contains "src_next_household_metadata_prefix_fallback_total_count: 6" "$out" "total fallback count works (equity=0, assets=2, income=1, expenses=3)"
assert_contains "src_next_household_metadata_prefix_fallback_expense_count: 3" "$out" "expense fallback count works"
assert_contains "src_next_readiness_missing_role_accounts_count: 7" "$out" "missing role total count works (6 accounts + 1 unknown)"


# ── Summary ──
echo "check-missing-role-fallback: $PASS passed, $FAIL failed" >&2
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
echo "OK" >&2
