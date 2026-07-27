#!/usr/bin/env bash
set -euo pipefail

# Selected human report construction regression boundary.
#
# Direct `--section <key>` output must remain byte-identical to the canonical
# full-section cache while evaluating only the selected human builder. Full
# report, list, and cache routes intentionally retain all-section construction.

export NO_COLOR=1

SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

fixture="${1:-fixtures/src-next-golden}"
if [ ! -d "$fixture" ]; then
  echo "ERROR: fixture directory not found: $fixture" >&2
  exit 2
fi
fixture_abs="$(cd "$fixture" && pwd)"

failures=0
fail() { echo "FAIL: $*" >&2; failures=$((failures + 1)); }
pass() { echo "PASS: $*"; }

work_dir="$(mktemp -d)"
poison_report=""
cleanup() {
  rm -rf "$work_dir"
  if [[ -n "$poison_report" ]]; then rm -f "$poison_report"; fi
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

assert_code() {
  local expected="$1"
  local name="$2"
  local actual
  actual="$(cat "$work_dir/$name.code")"
  if [ "$actual" = "$expected" ]; then
    pass "$name exit status is $expected"
  else
    fail "$name exit status was $actual, expected $expected"
  fi
}

assert_empty() {
  local path="$1"
  local label="$2"
  if [ ! -s "$path" ]; then
    pass "$label is 0 bytes"
  else
    fail "$label is not empty"
  fi
}

# Canonical all-section construction owns cache bytes. Direct selected output
# must be exactly one cached body plus PrintSection's two trailing newlines.
cache_dir="$work_dir/cache"
mkdir -p "$cache_dir"
run_capture cache tools/report "$fixture" --write-section-cache "$cache_dir" --no-color
assert_code 0 cache
assert_empty "$work_dir/cache.out" "cache stdout"
assert_empty "$work_dir/cache.err" "cache stderr"

selected_keys=(
  snapshot issues ytd cycle trial-balance envelopes
  planned recent check outlook daily-trend daily-flow actual-comparison debug
)
for key in "${selected_keys[@]}"; do
  run_capture "direct-$key" tools/report "$fixture" --section "$key" --no-color
  assert_code 0 "direct-$key"
  assert_empty "$work_dir/direct-$key.err" "direct-$key stderr"
  expected="$work_dir/expected-$key.out"
  cat "$cache_dir/$key.txt" >"$expected"
  printf '\n\n' >>"$expected"
  if cmp -s "$expected" "$work_dir/direct-$key.out"; then
    pass "direct $key matches canonical cache bytes plus PrintSection newlines"
  else
    fail "direct $key differs from canonical cache bytes"
  fi
done

# Balances retains its existing specialized selected route and currency view.
run_capture direct-balances tools/report "$fixture" --section balances --currency JPY --no-color
assert_code 0 direct-balances
assert_empty "$work_dir/direct-balances.err" "direct-balances stderr"
if grep -qF '== Account Balances ==' "$work_dir/direct-balances.out" \
  && grep -qF 'Currency view: JPY' "$work_dir/direct-balances.out"; then
  pass "specialized balances selected route remains available"
else
  fail "specialized balances selected route output changed"
fi

# Outlook's explicit observation coordinate must preserve the same direct/cache
# relation as the default observation route.
as_of_cache="$work_dir/as-of-cache"
mkdir -p "$as_of_cache"
run_capture as-of-cache tools/report "$fixture" --write-section-cache "$as_of_cache" --outlook-as-of 2026-06-01 --no-color
assert_code 0 as-of-cache
assert_empty "$work_dir/as-of-cache.out" "as-of-cache stdout"
assert_empty "$work_dir/as-of-cache.err" "as-of-cache stderr"
run_capture as-of-direct tools/report "$fixture" --section outlook --outlook-as-of 2026-06-01 --no-color
assert_code 0 as-of-direct
assert_empty "$work_dir/as-of-direct.err" "as-of-direct stderr"
cat "$as_of_cache/outlook.txt" >"$work_dir/as-of-expected.out"
printf '\n\n' >>"$work_dir/as-of-expected.out"
if cmp -s "$work_dir/as-of-expected.out" "$work_dir/as-of-direct.out"; then
  pass "selected outlook preserves explicit observation bytes"
else
  fail "selected outlook explicit observation bytes changed"
fi

# Unknown keys fail before evaluating any selected handler.
run_capture unknown tools/report "$fixture" --section does-not-exist --no-color
assert_code 1 unknown
assert_empty "$work_dir/unknown.err" "unknown stderr"
printf 'ERROR: unknown section key: does-not-exist\n' >"$work_dir/unknown.expected"
if cmp -s "$work_dir/unknown.expected" "$work_dir/unknown.out"; then
  pass "unknown selected key preserves exact error bytes"
else
  fail "unknown selected key error bytes changed"
fi

# Runtime isolation proof: poison the unselected debug builder in a temporary
# report file kept beside the production modules, so relative imports remain
# identical. Selected snapshot and unknown-key routes must not touch it, while
# the ordinary full report must hit it.
poison_report="$(mktemp src_next/.report-poison.XXXXXX)"
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
assert_code 0 poison-snapshot
assert_empty "$work_dir/poison-snapshot.err" "poison-snapshot stderr"
if cmp -s "$work_dir/direct-snapshot.out" "$work_dir/poison-snapshot.out"; then
  pass "selected snapshot does not evaluate poisoned debug builder"
else
  fail "selected snapshot changed under unrelated poisoned builder"
fi

run_capture poison-unknown bqn "$poison_report" "$fixture_abs" --section does-not-exist --no-color
assert_code 1 poison-unknown
assert_empty "$work_dir/poison-unknown.err" "poison-unknown stderr"
if cmp -s "$work_dir/unknown.expected" "$work_dir/poison-unknown.out"; then
  pass "unknown key does not evaluate poisoned debug builder"
else
  fail "unknown key reached or changed under poisoned debug builder"
fi

run_capture poison-full bqn "$poison_report" "$fixture_abs" --no-color
assert_code 97 poison-full
assert_empty "$work_dir/poison-full.err" "poison-full stderr"
printf 'ERROR: selected-section poison debug builder evaluated\n' >"$work_dir/poison.expected"
if cmp -s "$work_dir/poison.expected" "$work_dir/poison-full.out"; then
  pass "poison is active and ordinary full report still constructs all sections"
else
  fail "ordinary full report did not reach the poisoned debug builder as expected"
fi

if [ "$failures" -eq 0 ]; then
  echo "OK: selected-section construction checks passed" >&2
  exit 0
fi

echo "FAILED: $failures selected-section construction check(s) failed" >&2
exit 1
