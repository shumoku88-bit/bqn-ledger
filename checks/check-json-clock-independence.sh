#!/usr/bin/env bash
set -euo pipefail
export NO_COLOR=1

# checks/check-json-clock-independence.sh
# Check: json-clock-independence

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

# 1. Create a fake date executable that writes a flag file
cat <<EOF > "$TMPDIR/date"
#!/bin/sh
echo "yes" > "$TMPDIR/called.txt"
exit 99
EOF
chmod +x "$TMPDIR/date"

# 2. Run structured JSON request with PATH overridden
set +e
json_out="$(PATH="$TMPDIR:$PATH" tools/report fixtures/src-next-golden --section planned --format json 2>/dev/null)"
json_status=$?
set -e

# Assert JSON request still succeeds and is valid
assert_eq 0 "$json_status" "JSON request exit status"

# Assert exact output under fake-date PATH parses as JSON
if echo "$json_out" | python3 -c 'import sys, json; json.load(sys.stdin)'; then
  pass
else
  fail "JSON output is not parseable JSON"
fi

# Assert the fake date was not called on the JSON path
if [ -f "$TMPDIR/called.txt" ]; then
  fail "JSON path invoked the date command"
else
  pass
fi

# 3. Prove that human report path DOES invoke the date command
rm -f "$TMPDIR/called.txt"
set +e
human_out="$(PATH="$TMPDIR:$PATH" tools/report fixtures/src-next-golden --section snapshot --no-color 2>/dev/null)"
human_status=$?
set -e

# Assert human path called the fake date
if [ -f "$TMPDIR/called.txt" ]; then
  pass "Human path successfully called the fake date as expected"
else
  fail "Human path did not call the fake date"
fi

# ── Summary ──
echo "check-json-clock-independence: $PASS passed, $FAIL failed" >&2
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
echo "OK" >&2
