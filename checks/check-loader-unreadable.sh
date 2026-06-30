#!/usr/bin/env bash
set -euo pipefail
export NO_COLOR=1

# checks/check-loader-unreadable.sh
# Check: loader-unreadable

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
# 1. Missing file should return empty list
missing_res=$(bqn -e 'loader ← •Import "src_next/loader.bqn" ⋄ •Out •Repr ⊑ 0 = ≢ loader.ReadLinesOptional "non_existent_file_path.tsv"')
assert_eq "1" "$missing_res" "missing file should return empty"

# 2. Unreadable file (permission 000) should crash and throw exception
unreadable_file="$TMPDIR/unreadable.tsv"
echo "dummy" > "$unreadable_file"
chmod 000 "$unreadable_file"

set +e
bqn -e 'loader ← •Import "src_next/loader.bqn" ⋄ loader.ReadLinesOptional "'"$unreadable_file"'"' >/dev/null 2>&1
rc=$?
set -e

# In macOS/Linux, reading permission 000 file as a normal user throws error.
# If we run as root, it might succeed, so we skip this assert if the file was somehow readable.
if [ -r "$unreadable_file" ]; then
  echo "  INFO: Running as root? unreadable.tsv is readable anyway. Skipping crash check." >&2
  pass
else
  if [ "$rc" -ne 0 ]; then
    pass
  else
    fail "expected ReadLinesOptional to crash on unreadable file, but it succeeded"
  fi
fi

# ── Summary ──
echo "check-loader-unreadable: $PASS passed, $FAIL failed" >&2
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
echo "OK" >&2
