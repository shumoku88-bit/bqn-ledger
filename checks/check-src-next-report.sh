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

# JSON output verification: balances section ViewModel contract.
if tools/report "$fixture" --section balances --format json >"$json_out" 2>/dev/null; then
  if python3 - "$json_out" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as f:
    root = json.load(f)

if not isinstance(root, dict):
    raise SystemExit("top-level JSON is not an object")

required_root = {"accounts", "totals"}
missing_root = sorted(required_root - root.keys())
if missing_root:
    raise SystemExit(f"missing root fields: {missing_root}")

if not isinstance(root["accounts"], list):
    raise SystemExit("accounts is not an array")
if not isinstance(root["totals"], dict):
    raise SystemExit("totals is not an object")

account_required = {"account_key", "amount", "role", "type"}
for i, row in enumerate(root["accounts"], 1):
    if not isinstance(row, dict):
        raise SystemExit(f"account {i} is not an object")
    missing = sorted(account_required - row.keys())
    if missing:
        raise SystemExit(f"account {i} missing fields: {missing}")
    if not isinstance(row["account_key"], str):
        raise SystemExit(f"account {i} account_key is not string")
    if not isinstance(row["role"], str):
        raise SystemExit(f"account {i} role is not string")
    if not isinstance(row["type"], str):
        raise SystemExit(f"account {i} type is not string")
    if not isinstance(row["amount"], (int, float)) or isinstance(row["amount"], bool):
        raise SystemExit(f"account {i} amount is not numeric")

totals_required = {
    "liquid_assets_total", "savings_total", "investment_total",
    "assets_total", "liabilities_total", "net_worth"
}
missing_totals = sorted(totals_required - root["totals"].keys())
if missing_totals:
    raise SystemExit(f"missing totals fields: {missing_totals}")

for key in totals_required:
    val = root["totals"][key]
    if not isinstance(val, (int, float)) or isinstance(val, bool):
        raise SystemExit(f"totals {key} is not numeric")
PY
  then
    pass "report --section balances --format json parses and matches contract"
  else
    fail "report --section balances --format json is invalid"
  fi
else
  fail "report --section balances --format json failed"
fi

# JSON output verification: snapshot section ViewModel contract.
if tools/report "$fixture" --section snapshot --format json >"$json_out" 2>/dev/null; then
  if python3 - "$json_out" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as f:
    root = json.load(f)

if not isinstance(root, dict):
    raise SystemExit("top-level JSON is not an object")

required_root = {"as_of", "status", "cycle", "remaining_days", "days_elapsed", "totals", "cycle_summary", "readiness"}
missing_root = sorted(required_root - root.keys())
if missing_root:
    raise SystemExit(f"missing root fields: {missing_root}")

if not isinstance(root["as_of"], str):
    raise SystemExit("as_of is not a string")
if not isinstance(root["status"], str):
    raise SystemExit("status is not a string")
if not isinstance(root["cycle"], dict):
    raise SystemExit("cycle is not an object")
if not isinstance(root["totals"], dict):
    raise SystemExit("totals is not an object")
if not isinstance(root["cycle_summary"], dict):
    raise SystemExit("cycle_summary is not an object")
if not isinstance(root["readiness"], dict):
    raise SystemExit("readiness is not an object")

# remaining_days and days_elapsed can be null or int
for key in ("remaining_days", "days_elapsed"):
    val = root[key]
    if val is not None:
        if not isinstance(val, int) or isinstance(val, bool):
            raise SystemExit(f"{key} is not an integer or null")

cycle_required = {"start", "end_exclusive", "available"}
missing_cycle = sorted(cycle_required - root["cycle"].keys())
if missing_cycle:
    raise SystemExit(f"missing cycle fields: {missing_cycle}")

if not isinstance(root["cycle"]["available"], (int, bool)): # BQN uses 0/1 for booleans
    raise SystemExit("cycle.available is not boolean/numeric")

for key in ("start", "end_exclusive"):
    val = root["cycle"][key]
    if val is not None and not isinstance(val, str):
        raise SystemExit(f"cycle.{key} is not string or null")

totals_required = {"liquid_assets", "savings", "investments", "assets_total", "liabilities_total", "net_worth"}
missing_totals = sorted(totals_required - root["totals"].keys())
if missing_totals:
    raise SystemExit(f"missing totals fields: {missing_totals}")

for key in totals_required:
    val = root["totals"][key]
    if not isinstance(val, (int, float)) or isinstance(val, bool):
        raise SystemExit(f"totals.{key} is not numeric")

cs_required = {"income_actual", "expense_actual", "net_actual", "plan_expense"}
missing_cs = sorted(cs_required - root["cycle_summary"].keys())
if missing_cs:
    raise SystemExit(f"missing cycle_summary fields: {missing_cs}")

for key in cs_required:
    val = root["cycle_summary"][key]
    if not isinstance(val, (int, float)) or isinstance(val, bool):
        raise SystemExit(f"cycle_summary.{key} is not numeric")

rd_required = {"valid_projection_rows", "skipped_projection_rows", "unknown_account_count", "out_of_cycle_skipped_count"}
missing_rd = sorted(rd_required - root["readiness"].keys())
if missing_rd:
    raise SystemExit(f"missing readiness fields: {missing_rd}")

for key in rd_required:
    val = root["readiness"][key]
    if not isinstance(val, int) or isinstance(val, bool):
        raise SystemExit(f"readiness.{key} is not an integer")
PY
  then
    pass "report --section snapshot --format json parses and matches contract"
  else
    fail "report --section snapshot --format json is invalid"
  fi
else
  fail "report --section snapshot --format json failed"
fi

# JSON output verification: snapshot section null fallback when cycle is unresolvable.
no_cycle_fixture="fixtures/snapshot-no-cycle"
if tools/report "$no_cycle_fixture" --section snapshot --format json >"$json_out" 2>/dev/null; then
  if python3 - "$json_out" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as f:
    root = json.load(f)

if not isinstance(root, dict):
    raise SystemExit("top-level JSON is not an object")

# When cycle is unresolvable: as_of, cycle.start, cycle.end_exclusive must be null
if root["as_of"] is not None:
    raise SystemExit(f"as_of should be null when cycle unavailable, got: {root['as_of']!r}")
if root["cycle"]["start"] is not None:
    raise SystemExit(f"cycle.start should be null, got: {root['cycle']['start']!r}")
if root["cycle"]["end_exclusive"] is not None:
    raise SystemExit(f"cycle.end_exclusive should be null, got: {root['cycle']['end_exclusive']!r}")
if root["cycle"]["available"] not in (0, False):
    raise SystemExit(f"cycle.available should be 0/false, got: {root['cycle']['available']!r}")

# remaining_days and days_elapsed must be null
if root["remaining_days"] is not None:
    raise SystemExit(f"remaining_days should be null, got: {root['remaining_days']!r}")
if root["days_elapsed"] is not None:
    raise SystemExit(f"days_elapsed should be null, got: {root['days_elapsed']!r}")

# status should be "unknown" when cycle is unavailable
if root["status"] != "unknown":
    raise SystemExit(f"status should be 'unknown', got: {root['status']!r}")

# totals must still be present and numeric
for key in ("liquid_assets", "savings", "investments", "assets_total", "liabilities_total", "net_worth"):
    val = root["totals"][key]
    if not isinstance(val, (int, float)) or isinstance(val, bool):
        raise SystemExit(f"totals.{key} is not numeric: {val!r}")
PY
  then
    pass "snapshot JSON null fallback works when cycle is unresolvable"
  else
    fail "snapshot JSON null fallback contract violated"
  fi
else
  fail "snapshot JSON with no-cycle fixture failed to execute"
fi

# Cross-section consistency verification when cycle is unresolvable (no-cycle).
json_snap="$(mktemp)"
json_bal="$(mktemp)"
if tools/report "$no_cycle_fixture" --section snapshot --format json >"$json_snap" 2>/dev/null && \
   tools/report "$no_cycle_fixture" --section balances --format json >"$json_bal" 2>/dev/null; then
  if python3 - "$json_snap" "$json_bal" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as f:
    snap = json.load(f)
with open(sys.argv[2], encoding="utf-8") as f:
    bal = json.load(f)

# Consistency 1: Liquid assets total must match exactly (5000 in fixture)
snap_liq = snap["totals"]["liquid_assets"]
bal_liq = bal["totals"]["liquid_assets_total"]
if snap_liq != bal_liq:
    raise SystemExit(f"Consistency failure: snap liquid ({snap_liq}) != bal liquid ({bal_liq})")
if snap_liq != 5000:
    raise SystemExit(f"Expected liquid assets to be 5000, got {snap_liq}")

# Consistency 2: Net worth must match exactly
snap_nw = snap["totals"]["net_worth"]
bal_nw = bal["totals"]["net_worth"]
if snap_nw != bal_nw:
    raise SystemExit(f"Consistency failure: snap net worth ({snap_nw}) != bal net worth ({bal_nw})")

# Consistency 3: Since cycle is unavailable, all movements must be 0 (no period duration)
snap_inc = snap["cycle_summary"]["income_actual"]
snap_exp = snap["cycle_summary"]["expense_actual"]
if snap_inc != 0 or snap_exp != 0:
    raise SystemExit(f"Expected 0 cycle movements, got income={snap_inc}, expense={snap_exp}")
PY
  then
    pass "cross-section consistency when cycle is unresolvable is verified"
  else
    fail "cross-section consistency when cycle is unresolvable contract violated"
  fi
else
  fail "failed to execute JSON report commands for consistency check"
fi
rm -f "$json_snap" "$json_bal"

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

if tools/report "$fixture" --section envelopes --format json >"$bad_out" 2>&1; then
  fail "report --section envelopes --format json unexpectedly succeeded"
else
  if grep -qF -- 'ERROR: JSON format not supported for section: envelopes' "$bad_out"; then
    pass "report --section envelopes --format json fails with unsupported error"
  else
    fail "report --section envelopes --format json fails with unexpected error message"
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
