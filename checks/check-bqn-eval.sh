#!/usr/bin/env bash
set -euo pipefail
export NO_COLOR=1

# checks/check-bqn-eval.sh
# Check: bqn-eval

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

# Positive: basic expression
out=$(bash ./tools/bqn-eval '•Out "hello"' 2>&1) && assert_eq "hello" "$out" "basic •Out"

# Positive: shape expression (no output) — just verify non-error
if bash ./tools/bqn-eval '≢⟨1,2,3⟩' 2>/dev/null; then
  pass
else
  fail "shape expression should not error"
fi

# Negative: missing expression
if ! bash ./tools/bqn-eval 2>/dev/null; then
  pass
else
  fail "missing expression should error"
fi

# Negative: empty expression via stdin
if ! printf '' | bash ./tools/bqn-eval 2>/dev/null; then
  pass
else
  fail "empty expression should error"
fi

# Negative: invalid option
if ! bash ./tools/bqn-eval --invalid-opt '1' 2>/dev/null; then
  pass
else
  fail "invalid option should error"
fi

# Negative: json format rejected (Phase 1)
out=$(bash ./tools/bqn-eval --format json '1' 2>&1) && rc=$? || rc=$?
if [ "$rc" -ne 0 ]; then
  pass
else
  fail "json format should be rejected in Phase 1"
fi

# Positive: help flag
if bash ./tools/bqn-eval --help 2>/dev/null; then
  pass
else
  fail "--help should succeed"
fi

# ── Summary ──
echo "check-bqn-eval: $PASS passed, $FAIL failed" >&2
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
echo "OK" >&2
