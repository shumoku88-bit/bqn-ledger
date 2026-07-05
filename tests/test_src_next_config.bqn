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
⟨"reserve"⟩ lib.AssertEq fallback.HouseholdGroupReserveLabels @
"envelope" lib.AssertEq fallback.PolicyBudgetStyle @
"conservative" lib.AssertEq fallback.PolicyRiskStyle @

# 2. Sparse local overrides inherit repository defaults for the approved group keys.
life_override ← conf.LoadConfig "fixtures/src-next-config-effective-life-override"
⟨"daily", "flex", "weekly"⟩ lib.AssertEq life_override.HouseholdGroupLifeLabels @
⟨"reserve"⟩ lib.AssertEq life_override.HouseholdGroupReserveLabels @

reserve_override ← conf.LoadConfig "fixtures/src-next-config-effective-reserve-override"
⟨"daily", "flex"⟩ lib.AssertEq reserve_override.HouseholdGroupLifeLabels @
⟨"reserve", "longterm"⟩ lib.AssertEq reserve_override.HouseholdGroupReserveLabels @

# 3. A full-ish local config remains valid and supplies explicit policy values.
full ← conf.LoadConfig "data"
⟨"daily", "flex"⟩ lib.AssertEq full.HouseholdGroupLifeLabels @
⟨"reserve"⟩ lib.AssertEq full.HouseholdGroupReserveLabels @
"envelope" lib.AssertEq full.PolicyBudgetStyle @
"conservative" lib.AssertEq full.PolicyRiskStyle @
"bimonthly" lib.AssertEq full.PolicyIncomeCadence @

# 4. A partial local config replaces the default file at raw file-selection level.
# Missing POLICY_* keys are absent from Get; they are not merged from default_config.tsv.
partial ← conf.LoadConfig "fixtures/src-next-household-mapping-policy"
"" lib.AssertEq partial.Get "POLICY_BUDGET_STYLE"
"" lib.AssertEq partial.Get "POLICY_RISK_STYLE"
"" lib.AssertEq partial.Get "POLICY_INCOME_CADENCE"

# 5. Defaultable policy keys use typed missing behavior; optional accessors remain unchanged.
"envelope" lib.AssertEq partial.PolicyBudgetStyle @
"conservative" lib.AssertEq partial.PolicyRiskStyle @
"" lib.AssertEq partial.PolicyIncomeCadence @
"" lib.AssertEq partial.ExecutionPlannedPaymentsEnvelope @

# 6. Explicit local policy values remain valid and override defaults.
calendar ← conf.LoadConfig "fixtures/generalization-calendar"
"none" lib.AssertEq calendar.PolicyBudgetStyle @
"simple" lib.AssertEq calendar.PolicyRiskStyle @
"monthly" lib.AssertEq calendar.PolicyIncomeCadence @

# 7. Missing eligible raw keys remain distinguishable by key presence,
# while approved group accessors inherit repository defaults and tolerate extra UI keys.
missing ← conf.LoadConfig "fixtures/src-next-config-eligible-missing"
0 lib.AssertEq (HasKey ⟨missing, "HOUSEHOLD_GROUP_LIFE"⟩)
0 lib.AssertEq (HasKey ⟨missing, "HOUSEHOLD_GROUP_RESERVE"⟩)
⟨"daily", "flex"⟩ lib.AssertEq missing.HouseholdGroupLifeLabels @
⟨"reserve"⟩ lib.AssertEq missing.HouseholdGroupReserveLabels @
0 lib.AssertEq (HasKey ⟨missing, "POLICY_BUDGET_STYLE"⟩)
0 lib.AssertEq (HasKey ⟨missing, "POLICY_RISK_STYLE"⟩)
0 lib.AssertEq (HasKey ⟨missing, "POLICY_INCOME_CADENCE"⟩)
0 lib.AssertEq (HasKey ⟨missing, "EXECUTION_PLANNED_PAYMENTS_ENVELOPE"⟩)

# default_config.tsv contains legal explicit-empty optional keys.
1 lib.AssertEq (HasKey ⟨fallback, "POLICY_INCOME_CADENCE"⟩)
1 lib.AssertEq (HasKey ⟨fallback, "EXECUTION_PLANNED_PAYMENTS_ENVELOPE"⟩)

# 8. Presence-aware Lookup preserves missing, explicit empty, and explicit value.
⟨0, ""⟩ lib.AssertEq missing.Lookup "POLICY_INCOME_CADENCE"
⟨1, ""⟩ lib.AssertEq fallback.Lookup "POLICY_INCOME_CADENCE"
⟨1, "monthly"⟩ lib.AssertEq calendar.Lookup "POLICY_INCOME_CADENCE"

⟨0, ""⟩ lib.AssertEq missing.Lookup "HOUSEHOLD_GROUP_LIFE"
⟨1, "daily,flex"⟩ lib.AssertEq fallback.Lookup "HOUSEHOLD_GROUP_LIFE"

# 9. Existing Get still collapses missing and legal explicit empty to the same empty string.
"" lib.AssertEq missing.Get "POLICY_INCOME_CADENCE"
"" lib.AssertEq fallback.Get "POLICY_INCOME_CADENCE"
"" lib.AssertEq missing.Get "EXECUTION_PLANNED_PAYMENTS_ENVELOPE"
"" lib.AssertEq fallback.Get "EXECUTION_PLANNED_PAYMENTS_ENVELOPE"

# 10. Optional policy behavior remains unchanged in this slice.
"" lib.AssertEq fallback.PolicyIncomeCadence @
"" lib.AssertEq fallback.ExecutionPlannedPaymentsEnvelope @

# 11. Explicit-empty approved group keys fail closed.
life_empty_result ← •SH ⟨
  "bqn",
  "tests/config_household_group_life_probe.bqn",
  "fixtures/src-next-config-effective-life-empty"
⟩
1 lib.AssertEq 0 ⊑ life_empty_result
1 lib.AssertEq ("CONFIG ERROR: empty value for HOUSEHOLD_GROUP_LIFE" Contains 1 ⊑ life_empty_result)

reserve_empty_result ← •SH ⟨
  "bqn",
  "tests/config_household_group_reserve_probe.bqn",
  "fixtures/src-next-config-effective-reserve-empty"
⟩
1 lib.AssertEq 0 ⊑ reserve_empty_result
1 lib.AssertEq ("CONFIG ERROR: empty value for HOUSEHOLD_GROUP_RESERVE" Contains 1 ⊑ reserve_empty_result)

# 12. Existing budget-style explicit-empty contract remains covered.
budget_empty_result ← •SH ⟨
  "bqn",
  "tests/config_budget_style_probe.bqn",
  "fixtures/src-next-config-eligible-empty"
⟩
1 lib.AssertEq 0 ⊑ budget_empty_result
1 lib.AssertEq ("CONFIG ERROR: empty value for POLICY_BUDGET_STYLE" Contains 1 ⊑ budget_empty_result)

# 13. Explicit-empty second defaultable policy must exit 1 when invoked.
risk_empty_result ← •SH ⟨
  "bqn",
  "tests/config_policy_second_probe.bqn",
  "fixtures/src-next-config-eligible-empty"
⟩
1 lib.AssertEq 0 ⊑ risk_empty_result

•Out "test_src_next_config.bqn: OK"
