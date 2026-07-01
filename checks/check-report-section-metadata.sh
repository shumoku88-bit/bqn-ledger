#!/usr/bin/env bash
set -euo pipefail

fixture="${1:-fixtures/src-next-golden}"
if [ ! -d "$fixture" ]; then
  echo "ERROR: fixture directory not found: $fixture" >&2
  exit 2
fi

out="$(mktemp)"
json_out="$(mktemp)"
list="$(mktemp)"
keys="$(mktemp)"
json_keys="$(mktemp)"
list_keys="$(mktemp)"
trap 'rm -f "$out" "$json_out" "$list" "$keys" "$json_keys" "$list_keys"' EXIT

./tools/report-section-metadata >"$out"
./tools/report-section-metadata --format json >"$json_out"
tools/report "$fixture" --list-sections --no-color >"$list"

failures=0
fail() { echo "FAIL: $*" >&2; failures=$((failures + 1)); }
pass() { echo "PASS: $*"; }

expected_header=$'key\tlabel\tcategory\towner\thuman_output\tstructured_output'
actual_header="$(head -n 1 "$out")"
if [ "$actual_header" = "$expected_header" ]; then
  pass "metadata header is stable"
else
  fail "unexpected metadata header: $actual_header"
fi

if awk -F'\t' 'NF != 6 { print NR ":" NF ":" $0; bad=1 } END { exit bad ? 1 : 0 }' "$out" >/dev/null; then
  pass "all metadata rows have six TSV fields"
else
  fail "metadata output contains rows with unexpected field counts"
fi

tail -n +2 "$out" | cut -f1 >"$keys"
cut -f1 "$list" >"$list_keys"

if diff -u "$list_keys" "$keys" >/dev/null; then
  pass "metadata section keys match report --list-sections order"
else
  fail "metadata section keys differ from report --list-sections"
  diff -u "$list_keys" "$keys" >&2 || true
fi

if grep -qF $'daily-flow\tDaily Flow\thousehold\tsrc_next/daily_flow.bqn\tyes\tmetadata' "$out"; then
  pass "daily-flow metadata row is present"
else
  fail "daily-flow metadata row missing"
fi

if grep -qF $'check\tReadiness Check\tdiagnostics\tsrc_next/readiness_check.bqn\tyes\tmetadata' "$out"; then
  pass "readiness metadata row is present"
else
  fail "readiness metadata row missing"
fi

if python3 - "$json_out" >"$json_keys" <<'PY'
import json
import sys
path = sys.argv[1]
with open(path, encoding="utf-8") as f:
    rows = json.load(f)
required = ["key", "label", "category", "owner", "human_output", "structured_output"]
if not isinstance(rows, list):
    raise SystemExit("top-level JSON is not an array")
for i, row in enumerate(rows, 1):
    if not isinstance(row, dict):
        raise SystemExit(f"row {i} is not an object")
    missing = [k for k in required if k not in row]
    if missing:
        raise SystemExit(f"row {i} missing keys: {missing}")
    print(row["key"])
PY
then
  pass "json metadata output parses and exposes required fields"
else
  fail "json metadata output is invalid"
fi

if diff -u "$list_keys" "$json_keys" >/dev/null; then
  pass "json metadata section keys match report --list-sections order"
else
  fail "json metadata section keys differ from report --list-sections"
  diff -u "$list_keys" "$json_keys" >&2 || true
fi

if python3 - "$json_out" <<'PY'
import json
import sys
with open(sys.argv[1], encoding="utf-8") as f:
    rows = json.load(f)
for row in rows:
    if row.get("key") == "daily-flow" and row.get("structured_output") == "metadata":
        raise SystemExit(0)
raise SystemExit(1)
PY
then
  pass "json daily-flow metadata row is present"
else
  fail "json daily-flow metadata row missing"
fi

if [ "$failures" -eq 0 ]; then
  echo "OK: report section metadata export check passed" >&2
  exit 0
else
  echo "FAILED: $failures report section metadata check(s) failed" >&2
  exit 1
fi
