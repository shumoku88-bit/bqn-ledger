#!/usr/bin/env bash
set -euo pipefail

fixture="${1:-fixtures/src-next-golden}"
expected="tests/fixtures/report_section_metadata_expected.tsv"
if [ ! -d "$fixture" ]; then
  echo "ERROR: fixture directory not found: $fixture" >&2
  exit 2
fi
if [ ! -f "$expected" ]; then
  echo "ERROR: expected metadata contract not found: $expected" >&2
  exit 2
fi

out="$(mktemp)"
json_out="$(mktemp)"
list="$(mktemp)"
keys="$(mktemp)"
json_keys="$(mktemp)"
list_keys="$(mktemp)"
descriptor_keys="$(mktemp)"
descriptor_probe="$(mktemp "$PWD/.report-section-descriptors.XXXXXX.bqn")"
trap 'rm -f "$out" "$json_out" "$list" "$keys" "$json_keys" "$list_keys" "$descriptor_keys" "$descriptor_probe"' EXIT

cat >"$descriptor_probe" <<'BQN'
sections ← •Import "src_next/report_sections.bqn"
{•Out 0⊑𝕩}¨ sections.rows
BQN
bqn "$descriptor_probe" >"$descriptor_keys"

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

# This committed fixture is an independent public-contract oracle. Production
# descriptor and metadata code must never read it.
if cmp -s "$expected" "$out"; then
  pass "metadata TSV exactly matches all expected rows and values"
else
  fail "metadata TSV differs from the independent expected contract"
  diff -u "$expected" "$out" >&2 || true
fi

tail -n +2 "$out" | cut -f1 >"$keys"
cut -f1 "$list" >"$list_keys"

if diff -u "$descriptor_keys" "$list_keys" >/dev/null && diff -u "$descriptor_keys" "$keys" >/dev/null; then
  pass "descriptor, metadata, and report --list-sections keys match exactly in canonical order"
else
  fail "descriptor, metadata, and report --list-sections keys/order differ"
  diff -u "$descriptor_keys" "$list_keys" >&2 || true
  diff -u "$descriptor_keys" "$keys" >&2 || true
fi

owner_failures=0
while IFS=$'\t' read -r key label category owner human structured; do
  if [ ! -f "$owner" ]; then
    fail "descriptor owner path does not exist for $key: $owner"
    owner_failures=$((owner_failures + 1))
  fi
  if [ "$key" = "debug" ] && [ "$owner" != "src_next/report.bqn" ]; then
    fail "debug descriptor owner changed: $owner"
    owner_failures=$((owner_failures + 1))
  fi
done < <(tail -n +2 "$out")
if [ "$owner_failures" -eq 0 ]; then
  pass "all descriptor owner paths exist and debug remains report-owned"
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

if python3 - "$json_out" "$expected" >"$json_keys" <<'PY'
import csv
import json
import sys

json_path, expected_path = sys.argv[1:]
required = ["key", "label", "category", "owner", "human_output", "structured_output"]
with open(json_path, encoding="utf-8") as f:
    rows = json.load(f)
with open(expected_path, encoding="utf-8", newline="") as f:
    expected_rows = list(csv.DictReader(f, delimiter="\t"))
if not isinstance(rows, list):
    raise SystemExit("top-level JSON is not an array")
if len(rows) != len(expected_rows):
    raise SystemExit(f"JSON row count {len(rows)} != expected {len(expected_rows)}")
for i, (row, expected_row) in enumerate(zip(rows, expected_rows), 1):
    if not isinstance(row, dict):
        raise SystemExit(f"row {i} is not an object")
    if list(row) != required:
        raise SystemExit(f"row {i} fields {list(row)} != expected {required}")
    if row != expected_row:
        raise SystemExit(f"row {i} differs: actual={row!r} expected={expected_row!r}")
    print(row["key"])
PY
then
  pass "json metadata shape and all field values match the independent expected contract"
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
