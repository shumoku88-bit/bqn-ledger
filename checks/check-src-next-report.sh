#!/usr/bin/env bash
set -euo pipefail

# Verify src_next human-readable Stage 4 report surface.
# This is observation-only; production remains bqn main.bqn.

fixture="${1:-fixtures/src-next-golden}"
if [ ! -d "$fixture" ]; then
  echo "ERROR: fixture directory not found: $fixture" >&2
  exit 2
fi

out="$(mktemp)"
section_out="$(mktemp)"
json_out="$(mktemp)"
bad_out="$(mktemp)"
bad_err="$(mktemp)"
actual_fixture=""

cleanup() {
  rm -f "$out" "$section_out" "$json_out" "$bad_out" "$bad_err"
  if [[ -n "$actual_fixture" ]]; then
    rm -rf "$actual_fixture"
  fi
}
trap cleanup EXIT

bqn src_next/report.bqn "$fixture" > "$out"

failures=0
fail() { echo "FAIL: $*" >&2; failures=$((failures + 1)); }
pass() { echo "PASS: $*"; }

sections=(
  '1. 全体サマリ (Snapshot)'
  '== YTD Summary =='
  '== Account Balances =='
  '== Current Cycle Summary =='
  '== Envelope & Budget =='
  '== Planned Payments =='
  '7. 直近の取引 (Recent Journal)'
  '== Readiness Check =='
  '== Outlook Dashboard =='
  '== Daily Trend =='
  '== Actual Comparison =='
  '12. デバッグ・由来 (Debug & Provenance)'
)

for section in "${sections[@]}"; do
  if grep -qF -- "$section" "$out"; then
    pass "human report contains: $section"
  else
    fail "human report missing: $section"
  fi
done

if tools/report "$fixture" --section envelopes --no-color >"$section_out" 2>/dev/null; then
  if grep -qF -- '== Envelope & Budget ==' "$section_out"; then
    pass "report --section envelopes contains the envelope header"
  else
    fail "report --section envelopes missing the envelope header"
  fi

  if grep -qF -- '== Planned Payments ==' "$section_out"; then
    fail "report --section envelopes leaked the next section header"
  else
    pass "report --section envelopes stays within one section"
  fi
else
  fail "report --section envelopes failed"
fi

if tools/report "$fixture" --section snapshot --no-color >"$section_out" 2>/dev/null; then
  if grep -qF -- '1. 全体サマリ (Snapshot)' "$section_out"; then
    pass "report --section snapshot contains the snapshot header"
  else
    fail "report --section snapshot missing the snapshot header"
  fi

  if grep -qF -- '== YTD Summary ==' "$section_out"; then
    fail "report --section snapshot leaked the next section header"
  else
    pass "report --section snapshot stays within one section"
  fi
else
  fail "report --section snapshot failed"
fi

if tools/report "$fixture" --section does-not-exist --no-color >"$bad_out" 2>"$bad_err"; then
  fail "report --section does-not-exist unexpectedly succeeded"
else
  pass "report --section does-not-exist fails"
fi

# JSON output verification: parse the document and enforce the first ViewModel contract.
if tools/report "$fixture" --section planned --format json >"$json_out" 2>/dev/null; then
  if python3 - "$json_out" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as f:
    root = json.load(f)

if not isinstance(root, dict):
    raise SystemExit("top-level JSON is not an object")

required_root = {"open_items", "open_total", "completed_items"}
missing_root = sorted(required_root - root.keys())
if missing_root:
    raise SystemExit(f"missing root fields: {missing_root}")

if not isinstance(root["open_items"], list):
    raise SystemExit("open_items is not an array")
if not isinstance(root["completed_items"], list):
    raise SystemExit("completed_items is not an array")
if not isinstance(root["open_total"], (int, float)) or isinstance(root["open_total"], bool):
    raise SystemExit("open_total is not numeric")

open_required = {"date", "category", "memo", "amount", "status", "plan_id"}
completed_required = open_required | {"actual_amount"}

for i, row in enumerate(root["open_items"], 1):
    if not isinstance(row, dict):
        raise SystemExit(f"open item {i} is not an object")
    missing = sorted(open_required - row.keys())
    if missing:
        raise SystemExit(f"open item {i} missing fields: {missing}")
    if row["status"] not in {"future", "due", "overdue"}:
        raise SystemExit(f"open item {i} has invalid status: {row['status']!r}")
    if not isinstance(row["amount"], (int, float)) or isinstance(row["amount"], bool):
        raise SystemExit(f"open item {i} amount is not numeric")

for i, row in enumerate(root["completed_items"], 1):
    if not isinstance(row, dict):
        raise SystemExit(f"completed item {i} is not an object")
    missing = sorted(completed_required - row.keys())
    if missing:
        raise SystemExit(f"completed item {i} missing fields: {missing}")
    if row["status"] != "completed":
        raise SystemExit(f"completed item {i} has invalid status: {row['status']!r}")
    for key in ("amount", "actual_amount"):
        if not isinstance(row[key], (int, float)) or isinstance(row[key], bool):
            raise SystemExit(f"completed item {i} {key} is not numeric")
PY
  then
    pass "report --section planned --format json parses and matches contract"
  else
    fail "report --section planned --format json is invalid"
  fi
else
  fail "report --section planned --format json failed"
fi

actual_fixture="$(mktemp -d)"
cp -R fixtures/plan-completion/. "$actual_fixture/"
python3 - "$actual_fixture/journal.tsv" <<'PY'
import sys

path = sys.argv[1]
with open(path, encoding="utf-8") as f:
    rows = [line.rstrip("\n").split("\t") for line in f]
rows[1][4] = "65000"
with open(path, "w", encoding="utf-8", newline="") as f:
    for row in rows:
        f.write("\t".join(row) + "\n")
PY

if tools/report "$actual_fixture" --section planned --format json >"$json_out" 2>/dev/null; then
  if python3 - "$json_out" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as f:
    root = json.load(f)

matches = [
    row for row in root["completed_items"]
    if row.get("plan_id") == "plan-2026-01-15-rent"
]
if len(matches) != 1:
    raise SystemExit(f"expected one completed rent item, got {len(matches)}")
row = matches[0]
if row.get("amount") != 64000:
    raise SystemExit(f"planned amount drifted: {row.get('amount')!r}")
if row.get("actual_amount") != 65000:
    raise SystemExit(f"actual amount did not come from journal: {row.get('actual_amount')!r}")
PY
  then
    pass "planned JSON actual_amount comes from matching journal rows"
  else
    fail "planned JSON actual_amount does not come from matching journal rows"
  fi
else
  fail "planned JSON actual-amount fixture failed"
fi
rm -rf "$actual_fixture"
actual_fixture=""

if tools/report "$fixture" --section snapshot --format json >"$bad_out" 2>&1; then
  fail "report --section snapshot --format json unexpectedly succeeded"
else
  if grep -qF -- 'ERROR: JSON format not supported for section: snapshot' "$bad_out"; then
    pass "report --section snapshot --format json fails with unsupported error"
  else
    fail "report --section snapshot --format json fails with unexpected error message"
  fi
fi

if tools/report "$fixture" --section planned --format jsno >"$bad_out" 2>&1; then
  fail "report --format jsno unexpectedly succeeded"
else
  if grep -qF -- 'ERROR: unsupported format: jsno' "$bad_out"; then
    pass "report rejects unsupported format values"
  else
    fail "report rejects unsupported format with unexpected error message"
  fi
fi

if tools/report "$fixture" --format json >"$bad_out" 2>&1; then
  fail "report --format json without --section unexpectedly succeeded"
else
  if grep -qF -- 'ERROR: --format json requires --section <key>' "$bad_out"; then
    pass "report requires a section for JSON output"
  else
    fail "report JSON-without-section fails with unexpected error message"
  fi
fi

if grep -qiE '(production.ready|default switch|replacement ready)' "$out"; then
  fail "human report appears to claim production readiness"
else
  pass "human report does not claim production readiness"
fi

if [ "$failures" -eq 0 ]; then
  echo "OK: src_next human report check passed for fixture: $fixture" >&2
  exit 0
else
  echo "FAILED: $failures src_next human report check(s) failed" >&2
  exit 1
fi
