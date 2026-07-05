#!/usr/bin/env bqn

# Config resolution tests for A4 typed sparse-override work.

lib ← •Import "test_lib.bqn"
conf ← •Import "../src_next/config.bqn"

HasKey ← {
  cfg‿key ← 𝕩
  (⊑ cfg.keys ⊐ ⟨key⟩) < ≠ cfg.keys
}

Contains ← { needle ← 𝕨 ⋄ 0 < +´ (needle ⍷ 𝕩) }

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

# 4. Defaultable policy keys use typed missing behavior; optional accessors remain unchanged.
"envelope" lib.AssertEq partial.PolicyBudgetStyle @
"conservative" lib.AssertEq partial.PolicyRiskStyle @
"" lib.AssertEq partial.PolicyIncomeCadence @
"" lib.AssertEq partial.ExecutionPlannedPaymentsEnvelope @

# 5. Explicit local policy values remain valid and override defaults.
calendar ← conf.LoadConfig "fixtures/generalization-calendar"
"none" lib.AssertEq calendar.PolicyBudgetStyle @
"simple" lib.AssertEq calendar.PolicyRiskStyle @
"monthly" lib.AssertEq calendar.PolicyIncomeCadence @

# 6. Missing eligible keys remain distinguishable by key presence.
missing ← conf.LoadConfig "fixtures/src-next-config-eligible-missing"
0 lib.AssertEq (HasKey ⟨missing, "HOUSEHOLD_GROUP_LIFE"⟩)
0 lib.AssertEq (HasKey ⟨missing, "HOUSEHOLD_GROUP_RESERVE"⟩)
0 lib.AssertEq (HasKey ⟨missing, "POLICY_BUDGET_STYLE"⟩)
0 lib.AssertEq (HasKey ⟨missing, "POLICY_RISK_STYLE"⟩)
0 lib.AssertEq (HasKey ⟨missing, "POLICY_INCOME_CADENCE"⟩)
0 lib.AssertEq (HasKey ⟨missing, "EXECUTION_PLANNED_PAYMENTS_ENVELOPE"⟩)

# default_config.tsv contains legal explicit-empty optional keys.
1 lib.AssertEq (HasKey ⟨fallback, "POLICY_INCOME_CADENCE"⟩)
1 lib.AssertEq (HasKey ⟨fallback, "EXECUTION_PLANNED_PAYMENTS_ENVELOPE"⟩)

# 7. Presence-aware Lookup preserves missing, explicit empty, and explicit value.
⟨0, ""⟩ lib.AssertEq missing.Lookup "POLICY_INCOME_CADENCE"
⟨1, ""⟩ lib.AssertEq fallback.Lookup "POLICY_INCOME_CADENCE"
⟨1, "monthly"⟩ lib.AssertEq calendar.Lookup "POLICY_INCOME_CADENCE"

⟨0, ""⟩ lib.AssertEq missing.Lookup "HOUSEHOLD_GROUP_LIFE"
⟨1, "daily,flex"⟩ lib.AssertEq fallback.Lookup "HOUSEHOLD_GROUP_LIFE"

# 8. Existing Get still collapses missing and legal explicit empty to the same empty string.
"" lib.AssertEq missing.Get "POLICY_INCOME_CADENCE"
"" lib.AssertEq fallback.Get "POLICY_INCOME_CADENCE"
"" lib.AssertEq missing.Get "EXECUTION_PLANNED_PAYMENTS_ENVELOPE"
"" lib.AssertEq fallback.Get "EXECUTION_PLANNED_PAYMENTS_ENVELOPE"

# 9. Optional policy behavior remains unchanged in this slice.
"" lib.AssertEq fallback.PolicyIncomeCadence @
"" lib.AssertEq fallback.ExecutionPlannedPaymentsEnvelope @

# 10. Existing budget-style explicit-empty contract remains covered.
budget_empty_result ← •SH ⟨
  "bqn",
  "tests/config_budget_style_probe.bqn",
  "fixtures/src-next-config-eligible-empty"
⟩
1 lib.AssertEq 0 ⊑ budget_empty_result
1 lib.AssertEq ("CONFIG ERROR: empty value for POLICY_BUDGET_STYLE" Contains 1 ⊑ budget_empty_result)

# 11. Generic policy probe selects risk style for valid and explicit-empty cases.
risk_value_result ← •SH ⟨
  "bqn",
  "tests/config_policy_value_probe.bqn",
  "fixtures/generalization-calendar",
  "POLICY_RISK_STYLE"
⟩
0 lib.AssertEq 0 ⊑ risk_value_result

risk_empty_result ← •SH ⟨
  "bqn",
  "tests/config_policy_value_probe.bqn",
  "fixtures/src-next-config-eligible-empty",
  "POLICY_RISK_STYLE"
⟩
1 lib.AssertEq 0 ⊑ risk_empty_result
risk_empty_output ← (1 ⊑ risk_empty_result) ∾ (2 ⊑ risk_empty_result)
1 lib.AssertEq ("CONFIG ERROR: empty value for POLICY_RISK_STYLE" Contains risk_empty_output)

•Out "test_src_next_config.bqn: OK"
