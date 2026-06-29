#!/usr/bin/env bash
set -euo pipefail
export NO_COLOR=1

# checks/check-devtools-negative.sh
# Check: devtools-negative

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
    echo "  actual: $haystack" >&2
  fi
}

# ── Tests ──

echo "Testing tools/query negative paths..." >&2
if out=$(tools/query 2>&1); then
  fail "tools/query with no args should fail"
else
  code=$?
  assert_eq "1" "$code" "tools/query exit code"
  assert_contains "Usage: tools/query" "$out" "tools/query usage message"
fi

if out=$(tools/query invalid_base --list 2>&1); then
  fail "tools/query with invalid base should fail"
else
  code=$?
  assert_eq "2" "$code" "tools/query invalid base exit code"
  assert_contains "ERROR: base directory not found" "$out" "tools/query invalid base message"
fi

echo "Testing tools/bqn-eval negative paths..." >&2
if out=$(bash tools/bqn-eval </dev/null 2>&1); then
  fail "tools/bqn-eval with no args should fail"
else
  code=$?
  assert_eq "1" "$code" "tools/bqn-eval exit code"
  assert_contains "Error: BQN expression is empty." "$out" "tools/bqn-eval empty error message"
fi

if out=$(bash tools/bqn-eval '1+' 2>&1); then
  fail "tools/bqn-eval with invalid syntax should fail"
else
  code=$?
  assert_eq "1" "$code" "tools/bqn-eval syntax exit code"
  assert_contains "must be functions" "$out" "tools/bqn-eval syntax error message"
fi

echo "Testing tools/bqn-dump negative paths..." >&2
if out=$(bash tools/bqn-dump </dev/null 2>&1); then
  fail "tools/bqn-dump with no args should fail"
else
  code=$?
  assert_eq "1" "$code" "tools/bqn-dump exit code"
  assert_contains "Error: BQN expression is empty." "$out" "tools/bqn-dump empty error message"
fi

if out=$(bash tools/bqn-dump '1+' 2>&1); then
  fail "tools/bqn-dump with invalid syntax should fail"
else
  code=$?
  assert_eq "1" "$code" "tools/bqn-dump syntax exit code"
  assert_contains "must be functions" "$out" "tools/bqn-dump syntax error message"
fi

echo "Testing tools/edit negative paths..." >&2
if out=$(tools/edit 2>&1); then
  fail "tools/edit with no args should fail"
else
  code=$?
  assert_eq "2" "$code" "tools/edit exit code"
  assert_contains "ERROR: missing command" "$out" "tools/edit missing command message"
fi

if out=$(tools/edit invalid_cmd 2>&1); then
  fail "tools/edit with invalid command should fail"
else
  code=$?
  assert_eq "2" "$code" "tools/edit invalid cmd exit code"
  assert_contains "ERROR: missing command/subcommand" "$out" "tools/edit invalid command message"
fi

if out=$(tools/edit journal add 2>&1); then
  fail "tools/edit journal add with missing args should fail"
else
  code=$?
  # BQN editor exits with 2
  if [[ "$code" -ne 1 && "$code" -ne 2 ]]; then
    fail "tools/edit journal add exit code: expected [1 or 2] got [$code]"
  else
    pass
  fi
  # BQN outputs "invalid date format"
  if echo "$out" | grep -qE "invalid date format"; then
    pass
  else
    fail "tools/edit missing arg message: expected BQN or Go error, got: $out"
  fi
fi

echo "Testing tools/add-ui.sh negative paths..." >&2
if out=$(bash tools/add-ui.sh invalid_mode 2>&1); then
  fail "tools/add-ui.sh with invalid mode should fail"
else
  code=$?
  assert_eq "1" "$code" "tools/add-ui.sh exit code"
  assert_contains "Error: Unknown argument: invalid_mode" "$out" "tools/add-ui.sh error message"
fi


# ── Summary ──
echo "check-devtools-negative: $PASS passed, $FAIL failed" >&2
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
echo "OK" >&2
