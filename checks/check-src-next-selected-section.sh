#!/usr/bin/env bash
set -euo pipefail

# Selected human report construction regression boundary.
# Direct output must match canonical cache bytes while only the chosen builder
# is evaluated. Full/list/cache routes intentionally retain all-section work.

export NO_COLOR=1
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

fixture="${1:-fixtures/src-next-golden}"
[[ -d "$fixture" ]] || { echo "ERROR: fixture directory not found: $fixture" >&2; exit 2; }
fixture_abs="$(cd "$fixture" && pwd)"

failures=0
fail() { echo "FAIL: $*" >&2; failures=$((failures + 1)); }
pass() { echo "PASS: $*"; }

work_dir="$(mktemp -d)"
poison_report=""
cleanup() {
  rm -rf "$work_dir"
  [[ -z "$poison_report" ]] || rm -f "$poison_report"
}
trap cleanup EXIT

run_capture() {
  local name="$1"
  shift
  set +e
  "$@" >"$work_dir/$name.out" 2>"$work_dir/$name.err"
  local code=$?
  set -e
  printf '%s\n' "$code" >"$work_dir/$name.code"
}

assert_result() {
  local expected_code="$1" name="$2"
  local actual_code
  actual_code="$(cat "$work_dir/$name.code")"
  [[ "$actual_code" = "$expected_code" ]] \
    && pass "$name exit status is $expected_code" \
    || fail "$name exit status was $actual_code, expected $expected_code"
  [[ ! -s "$work_dir/$name.err" ]] \
    && pass "$name stderr is 0 bytes" \
    || fail "$name stderr is not empty"
}

cache_dir="$work_dir/cache"
mkdir -p "$cache_dir"
run_capture cache tools/report "$fixture" --write-section-cache "$cache_dir" --no-color
assert_result 0 cache
[[ ! -s "$work_dir/cache.out" ]] && pass "cache stdout is 0 bytes" || fail "cache stdout is not empty"

selected_keys=(
  snapshot issues ytd cycle trial-balance envelopes planned recent check
  outlook daily-trend daily-flow actual-comparison debug
)
for key in "${selected_keys[@]}"; do
  run_capture "direct-$key" tools/report "$fixture" --section "$key" --no-color
  assert_result 0 "direct-$key"
  cat "$cache_dir/$key.txt" >"$work_dir/expected-$key.out"
  printf '\n\n' >>"$work_dir/expected-$key.out"
  cmp -s "$work_dir/expected-$key.out" "$work_dir/direct-$key.out" \
    && pass "direct $key matches canonical cache bytes" \
    || fail "direct $key differs from canonical cache bytes"
done

run_capture direct-balances tools/report "$fixture" --section balances --currency JPY --no-color
assert_result 0 direct-balances
if grep -qF '== Account Balances ==' "$work_dir/direct-balances.out" \
  && grep -qF 'Currency view: JPY' "$work_dir/direct-balances.out"; then
  pass "specialized balances route remains available"
else
  fail "specialized balances route output changed"
fi

as_of_cache="$work_dir/as-of-cache"
mkdir -p "$as_of_cache"
run_capture as-of-cache tools/report "$fixture" --write-section-cache "$as_of_cache" --outlook-as-of 2026-06-01 --no-color
assert_result 0 as-of-cache
run_capture as-of-direct tools/report "$fixture" --section outlook --outlook-as-of 2026-06-01 --no-color
assert_result 0 as-of-direct
cat "$as_of_cache/outlook.txt" >"$work_dir/as-of-expected.out"
printf '\n\n' >>"$work_dir/as-of-expected.out"
cmp -s "$work_dir/as-of-expected.out" "$work_dir/as-of-direct.out" \
  && pass "selected outlook preserves explicit observation bytes" \
  || fail "selected outlook explicit observation bytes changed"

run_capture unknown tools/report "$fixture" --section does-not-exist --no-color
assert_result 1 unknown
printf 'ERROR: unknown section key: does-not-exist\n' >"$work_dir/unknown.expected"
cmp -s "$work_dir/unknown.expected" "$work_dir/unknown.out" \
  && pass "unknown key preserves exact error bytes" \
  || fail "unknown key error bytes changed"

# Keep the probe beside production modules with a normal .bqn suffix so CBQN
# resolves relative imports exactly as it does for src_next/report.bqn.
poison_report="src_next/.report-poison-$$-${RANDOM}.bqn"
cp src_next/report.bqn "$poison_report"
python3 - "$poison_report" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
old = '''BuildDebugEntry ← {
  ctx ← 𝕩
  hdr ← fmt.Section (L "report.debug_title")
  txt ← hdr∾(@+10)∾"status: partial/src_next"∾(@+10)∾cube.VerifyNumeric ⟨ctx.cube, ctx.resolved.account_keys⟩
  ⟨"debug", txt⟩
}
'''
new = '''BuildDebugEntry ← {
  •Out "ERROR: selected-section poison debug builder evaluated"
  •Exit 97
}
'''
if text.count(old) != 1:
    raise SystemExit("expected exactly one BuildDebugEntry body to poison")
path.write_text(text.replace(old, new), encoding="utf-8", newline="")
PY

run_capture poison-snapshot bqn "$poison_report" "$fixture_abs" --section snapshot --no-color
assert_result 0 poison-snapshot
cmp -s "$work_dir/direct-snapshot.out" "$work_dir/poison-snapshot.out" \
  && pass "selected snapshot skips poisoned debug builder" \
  || fail "selected snapshot reached unrelated poisoned builder"

run_capture poison-unknown bqn "$poison_report" "$fixture_abs" --section does-not-exist --no-color
assert_result 1 poison-unknown
cmp -s "$work_dir/unknown.expected" "$work_dir/poison-unknown.out" \
  && pass "unknown key skips poisoned debug builder" \
  || fail "unknown key reached unrelated poisoned builder"

run_capture poison-full bqn "$poison_report" "$fixture_abs" --no-color
assert_result 97 poison-full
printf 'ERROR: selected-section poison debug builder evaluated\n' >"$work_dir/poison.expected"
cmp -s "$work_dir/poison.expected" "$work_dir/poison-full.out" \
  && pass "ordinary full report still constructs all sections" \
  || fail "ordinary full report did not activate poison"

if [[ "$failures" -eq 0 ]]; then
  echo "OK: selected-section construction checks passed" >&2
  exit 0
fi

echo "FAILED: $failures selected-section construction check(s) failed" >&2
exit 1
