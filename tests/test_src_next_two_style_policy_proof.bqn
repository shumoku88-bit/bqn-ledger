#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
loader ← •Import "../src_next/loader.bqn"
ak ← •Import "../src_next/account_key.bqn"
proj ← •Import "../src_next/projection.bqn"
cycle ← •Import "../src_next/cycle.bqn"
cube ← •Import "../src_next/cube.bqn"
tbds ← •Import "../src_next/tbds.bqn"
hh ← •Import "../src_next/household_policy.bqn"

proof ← {state⇐"proven", domain⇐"JPY", basis⇐"legacy_compatibility", message⇐""}

BuildRowsForFile ← {𝕊 base‿srcFile‿resolved‿cycleStart:
  lines ← loader.ReadLines (base ∾ "/" ∾ srcFile)
  args ← {𝕊 i:
    flds ← loader.SplitTsv (i ⊑ lines)
    ⟨srcFile, i, flds, resolved.accounts, resolved.roles, resolved.account_keys, cycleStart⟩
  } ¨ ↕ ≠ lines
  proj.MakeRowsAuthorized ⟨proof, args⟩
}

# ── 1. moko-style test (POLICY_BUDGET_STYLE=envelope) ──
base_moko ← "fixtures/generalization-moko"
res_moko ← ak.Resolve loader.ReadLines (base_moko ∾ "/accounts.tsv")
cy_moko ← cycle.ReadCycle base_moko
rows_moko ← (BuildRowsForFile ⟨base_moko, "journal.tsv", res_moko, cy_moko.start⟩) ∾ BuildRowsForFile ⟨base_moko, "plan.tsv", res_moko, cy_moko.start⟩
result_moko ← cube.Materialize ⟨rows_moko, cy_moko.day_count, res_moko.count⟩

# Core TBDS construction should work
tbds_moko ← tbds.Build ⟨rows_moko, result_moko, res_moko, cy_moko⟩
1 lib.AssertEq 0 < ≠ tbds_moko

# Household summary should have policy metadata enabled
sum_moko ← hh.BuildSummary ⟨base_moko, res_moko, result_moko.valid_rows⟩
1 lib.AssertEq sum_moko.has_policy_metadata

# ── 2. calendar-style test (POLICY_BUDGET_STYLE=none) ──
base_cal ← "fixtures/generalization-calendar"
res_cal ← ak.Resolve loader.ReadLines (base_cal ∾ "/accounts.tsv")
cy_cal ← cycle.ReadCycle base_cal
# For calendarMonth, resolution is unavailable, use mock period for engine loading test
cal_start ← "2026-02-01"
cal_days ← 28
rows_cal ← (BuildRowsForFile ⟨base_cal, "journal.tsv", res_cal, cal_start⟩) ∾ BuildRowsForFile ⟨base_cal, "plan.tsv", res_cal, cal_start⟩
result_cal ← cube.Materialize ⟨rows_cal, cal_days, res_cal.count⟩

# Core TBDS construction should work (core is policy-independent)
# Build cy_cal_mock to pass cy.start/cy.end_exclusive expected by tbds.Build
cy_cal_mock ← { mode ⇐ "fixed", start ⇐ cal_start, end_exclusive ⇐ "2026-03-01", day_count ⇐ cal_days }
tbds_cal ← tbds.Build ⟨rows_cal, result_cal, res_cal, cy_cal_mock⟩
1 lib.AssertEq 0 < ≠ tbds_cal

# Household summary should have policy metadata DISABLED
sum_cal ← hh.BuildSummary ⟨base_cal, res_cal, result_cal.valid_rows⟩
0 lib.AssertEq sum_cal.has_policy_metadata

# Test outlook under simple risk style
outlook ← •Import "../src_next/outlook.bqn"
ctx_cal_mock_out ← {
  base ⇐ base_cal,
  cy ⇐ cy_cal_mock,
  resolved ⇐ res_cal,
  cube ⇐ result_cal,
  tbds ⇐ tbds_cal
}
vm_cal_outlook ← outlook.Build ctx_cal_mock_out
"unavailable/policy" lib.AssertEq vm_cal_outlook.liq_safe_daily

•Out "test_src_next_two_style_policy_proof.bqn: OK"
