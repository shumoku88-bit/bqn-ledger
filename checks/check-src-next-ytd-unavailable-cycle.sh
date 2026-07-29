#!/usr/bin/env bash
set -euo pipefail

# YTD unavailable-cycle regression boundary.
#
# This check distinguishes:
#   - unknown cycle mode;
#   - supported fixed mode that cannot resolve because boundaries are absent;
#   - valid fixed cycle with zero actual rows;
#   - valid fixed cycle with ordinary actual rows.
#
# It also locks the direct-section, section-cache, full-report, and unsupported
# JSON-route contracts without normalizing trailing newlines.

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

failures=0
fail() { echo "FAIL: $*" >&2; failures=$((failures + 1)); }
pass() { echo "PASS: $*"; }

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

UNKNOWN_FIXTURE="fixtures/envelopes-disabled-policy"
ZERO_FIXTURE="fixtures/empty-journal"
GOLDEN_FIXTURE="fixtures/editor-golden"

for fixture in "$UNKNOWN_FIXTURE" "$ZERO_FIXTURE" "$GOLDEN_FIXTURE"; do
  if [ ! -d "$fixture" ]; then
    echo "ERROR: fixture not found: $fixture" >&2
    exit 2
  fi
done

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
    od -An -tx1 -c "$path" >&2 || true
  fi
}

assert_expected_bytes() {
  local path="$1"
  local contract="$2"
  local label="$3"
  if python3 - "$path" "$contract" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
contract = sys.argv[2]
expected = {
    "unavailable-cache": (
        "== YTD Summary ==\n\n"
        "unavailable 〜 unavailable\n\n"
        "Account | YTD\n"
        "--------+----\n"
    ).encode("utf-8"),
    "unavailable-direct": (
        "== YTD Summary ==\n\n"
        "unavailable 〜 unavailable\n\n"
        "Account | YTD\n"
        "--------+----\n\n\n"
    ).encode("utf-8"),
    "zero-direct": (
        "== YTD Summary ==\n\n"
        "2026-01-01 〜 2026-02-01\n\n"
        "Account | YTD\n"
        "--------+----\n\n\n"
    ).encode("utf-8"),
    "golden-direct": (
        "== YTD Summary ==\n\n"
        "2026-01-01 〜 2026-06-22\n\n"
        "Account           | YTD\n"
        "------------------+----\n"
        "expenses:food/JPY | -80\n"
        "expenses:rent/JPY | -20\n\n\n"
    ).encode("utf-8"),
    "unsupported-json": b"ERROR: JSON format not supported for section: ytd\n",
}[contract]
actual = path.read_bytes()
if actual != expected:
    print(f"expected {expected!r}", file=sys.stderr)
    print(f"actual   {actual!r}", file=sys.stderr)
    raise SystemExit(1)
PY
  then
    pass "$label is byte-exact"
  else
    fail "$label byte contract mismatch"
  fi
}

# 1. Unknown mode: direct YTD returns the explicit unavailable presentation.
run_capture unknown-direct tools/report "$UNKNOWN_FIXTURE" --section ytd --no-color
assert_code 0 unknown-direct
assert_empty "$work_dir/unknown-direct.err" "unknown-direct stderr"
assert_expected_bytes "$work_dir/unknown-direct.out" unavailable-direct "unknown-direct stdout"

# 2. Unknown mode: section cache preserves raw section bytes and reaches later sections.
cache_dir="$work_dir/cache"
mkdir -p "$cache_dir"
run_capture unknown-cache tools/report "$UNKNOWN_FIXTURE" --write-section-cache "$cache_dir" --no-color
assert_code 0 unknown-cache
assert_empty "$work_dir/unknown-cache.out" "unknown-cache stdout"
assert_empty "$work_dir/unknown-cache.err" "unknown-cache stderr"

if [ -f "$cache_dir/ytd.txt" ]; then
  pass "unknown-cache ytd.txt exists"
  assert_expected_bytes "$cache_dir/ytd.txt" unavailable-cache "unknown-cache ytd.txt"
else
  fail "unknown-cache ytd.txt was not created"
fi

if [ -f "$cache_dir/daily-flow.txt" ] && [ -f "$cache_dir/actual-comparison.txt" ]; then
  pass "unknown-cache reached sections after YTD"
else
  fail "unknown-cache did not create later section files"
fi

cache_plus_print="$work_dir/cache-plus-print.out"
cat "$cache_dir/ytd.txt" >"$cache_plus_print"
printf '\n\n' >>"$cache_plus_print"
if cmp -s "$cache_plus_print" "$work_dir/unknown-direct.out"; then
  pass "cache ytd.txt plus PrintSection newlines matches direct stdout byte-for-byte"
else
  fail "cache/direct YTD byte relation mismatch"
fi

# 3. Unknown mode: full report passes YTD and reaches later human sections.
run_capture unknown-full tools/report "$UNKNOWN_FIXTURE" --no-color
assert_code 0 unknown-full
assert_empty "$work_dir/unknown-full.err" "unknown-full stderr"
if grep -qF '== YTD Summary ==' "$work_dir/unknown-full.out" \
  && grep -qF '== Daily Flow ==' "$work_dir/unknown-full.out" \
  && grep -qF '== Actual Comparison ==' "$work_dir/unknown-full.out"; then
  pass "unknown-full passes YTD and reaches later sections"
else
  fail "unknown-full is missing YTD or a later section"
fi

# 4. Supported but unresolved fixed mode has the same YTD unavailable contract.
unresolved_fixture="$work_dir/fixed-unresolved"
cp -R "$UNKNOWN_FIXTURE" "$unresolved_fixture"
printf 'mode\tfixed\n' >"$unresolved_fixture/cycle.tsv"
run_capture unresolved-direct tools/report "$unresolved_fixture" --section ytd --no-color
assert_code 0 unresolved-direct
assert_empty "$work_dir/unresolved-direct.err" "unresolved-direct stderr"
assert_expected_bytes "$work_dir/unresolved-direct.out" unavailable-direct "unresolved-direct stdout"

# 5. Valid cycle with zero actual rows remains a normal numeric-zero summary.
run_capture zero-direct tools/report "$ZERO_FIXTURE" --section ytd --no-color
assert_code 0 zero-direct
assert_empty "$work_dir/zero-direct.err" "zero-direct stderr"
assert_expected_bytes "$work_dir/zero-direct.out" zero-direct "zero-direct stdout"

# 6. Existing valid-cycle YTD values, order, signs, range, and human bytes stay fixed.
run_capture golden-direct tools/report "$GOLDEN_FIXTURE" --section ytd --no-color
assert_code 0 golden-direct
assert_empty "$work_dir/golden-direct.err" "golden-direct stderr"
assert_expected_bytes "$work_dir/golden-direct.out" golden-direct "golden-direct stdout"

# 7. YTD has no JSON route; preserve the existing unsupported-route contract.
run_capture unknown-json tools/report "$UNKNOWN_FIXTURE" --section ytd --format json --no-color
assert_code 1 unknown-json
assert_empty "$work_dir/unknown-json.err" "unknown-json stderr"
assert_expected_bytes "$work_dir/unknown-json.out" unsupported-json "unknown-json stdout"

if [ "$failures" -eq 0 ]; then
  echo "OK: all YTD unavailable-cycle regression checks passed" >&2
  exit 0
fi

echo "FAILED: $failures YTD unavailable-cycle check(s) failed" >&2
exit 1
