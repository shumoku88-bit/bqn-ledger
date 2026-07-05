#!/usr/bin/env bqn

# Characterization tests for current config resolution semantics.
# A4 Phase 1: verification only. This file must not change runtime behavior.

lib ← •Import "test_lib.bqn"
conf ← •Import "../src_next/config.bqn"

HasKey ← {
  cfg‿key ← 𝕩
  (⊑ cfg.keys ⊐ ⟨key⟩) < ≠ cfg.keys
}

# 1. A base without local config.tsv falls back to config/default_config.tsv.
fallback ← conf.LoadConfig "fixtures/src-next-golden"
"budget:" lib.AssertEq fallback.BudgetPrefix @
⟨"daily", "flex"⟩ lib.AssertEq fallback.HouseholdGroupLifeLabels @
"envelope" lib.AssertEq fallback.PolicyBudgetStyle @
"conservative" lib.AssertEq fallback.PolicyRiskStyle @

# 2. A full-ish local config remains valid and supplies explicit policy values.
full ← conf.LoadConfig "data"
"envelope" lib.AssertEq full.PolicyBudgetStyle @
"conservative" lib.AssertEq full.PolicyRiskStyle @
"bimonthly" lib.AssertEq full.PolicyIncomeCadence @

# 3. A partial local config replaces the default file at file-selection level.
# Missing POLICY_* keys are absent from Get; they are not merged from default_config.tsv.
partial ← conf.LoadConfig "fixtures/src-next-household-mapping-policy"
"" lib.AssertEq partial.Get "POLICY_BUDGET_STYLE"
"" lib.AssertEq partial.Get "POLICY_RISK_STYLE"
"" lib.AssertEq partial.Get "POLICY_INCOME_CADENCE"

# 4. Current accessor-level defaults remain distinct from file-level replacement.
"envelope" lib.AssertEq partial.PolicyBudgetStyle @
"conservative" lib.AssertEq partial.PolicyRiskStyle @
"" lib.AssertEq partial.PolicyIncomeCadence @
"" lib.AssertEq partial.ExecutionPlannedPaymentsEnvelope @

# 5. Explicit local policy values override accessor defaults.
calendar ← conf.LoadConfig "fixtures/generalization-calendar"
"none" lib.AssertEq calendar.PolicyBudgetStyle @
"simple" lib.AssertEq calendar.PolicyRiskStyle @
"monthly" lib.AssertEq calendar.PolicyIncomeCadence @

# 6. Missing and explicit-empty eligible keys are distinguishable by key presence.
# Both fixtures have a local config.tsv. The missing fixture omits all six first-slice
# application keys; the empty fixture contains all six with empty values.
missing ← conf.LoadConfig "fixtures/src-next-config-eligible-missing"
empty ← conf.LoadConfig "fixtures/src-next-config-eligible-empty"

0 lib.AssertEq (HasKey ⟨missing, "HOUSEHOLD_GROUP_LIFE"⟩)
0 lib.AssertEq (HasKey ⟨missing, "HOUSEHOLD_GROUP_RESERVE"⟩)
0 lib.AssertEq (HasKey ⟨missing, "POLICY_BUDGET_STYLE"⟩)
0 lib.AssertEq (HasKey ⟨missing, "POLICY_RISK_STYLE"⟩)
0 lib.AssertEq (HasKey ⟨missing, "POLICY_INCOME_CADENCE"⟩)
0 lib.AssertEq (HasKey ⟨missing, "EXECUTION_PLANNED_PAYMENTS_ENVELOPE"⟩)

1 lib.AssertEq (HasKey ⟨empty, "HOUSEHOLD_GROUP_LIFE"⟩)
1 lib.AssertEq (HasKey ⟨empty, "HOUSEHOLD_GROUP_RESERVE"⟩)
1 lib.AssertEq (HasKey ⟨empty, "POLICY_BUDGET_STYLE"⟩)
1 lib.AssertEq (HasKey ⟨empty, "POLICY_RISK_STYLE"⟩)
1 lib.AssertEq (HasKey ⟨empty, "POLICY_INCOME_CADENCE"⟩)
1 lib.AssertEq (HasKey ⟨empty, "EXECUTION_PLANNED_PAYMENTS_ENVELOPE"⟩)

# 7. Current Get collapses missing and explicit empty to the same empty string.
"" lib.AssertEq missing.Get "HOUSEHOLD_GROUP_LIFE"
"" lib.AssertEq empty.Get "HOUSEHOLD_GROUP_LIFE"
"" lib.AssertEq missing.Get "HOUSEHOLD_GROUP_RESERVE"
"" lib.AssertEq empty.Get "HOUSEHOLD_GROUP_RESERVE"
"" lib.AssertEq missing.Get "POLICY_BUDGET_STYLE"
"" lib.AssertEq empty.Get "POLICY_BUDGET_STYLE"
"" lib.AssertEq missing.Get "POLICY_RISK_STYLE"
"" lib.AssertEq empty.Get "POLICY_RISK_STYLE"
"" lib.AssertEq missing.Get "POLICY_INCOME_CADENCE"
"" lib.AssertEq empty.Get "POLICY_INCOME_CADENCE"
"" lib.AssertEq missing.Get "EXECUTION_PLANNED_PAYMENTS_ENVELOPE"
"" lib.AssertEq empty.Get "EXECUTION_PLANNED_PAYMENTS_ENVELOPE"

# 8. Current safe accessors also collapse missing and explicit empty for policy/optional keys.
# HOUSEHOLD_GROUP_* accessors are not invoked here because current Required exits;
# their raw presence distinction above is enough for this no-runtime-change slice.
"envelope" lib.AssertEq missing.PolicyBudgetStyle @
"envelope" lib.AssertEq empty.PolicyBudgetStyle @
"conservative" lib.AssertEq missing.PolicyRiskStyle @
"conservative" lib.AssertEq empty.PolicyRiskStyle @
"" lib.AssertEq missing.PolicyIncomeCadence @
"" lib.AssertEq empty.PolicyIncomeCadence @
"" lib.AssertEq missing.ExecutionPlannedPaymentsEnvelope @
"" lib.AssertEq empty.ExecutionPlannedPaymentsEnvelope @

•Out "test_src_next_config.bqn: OK"
