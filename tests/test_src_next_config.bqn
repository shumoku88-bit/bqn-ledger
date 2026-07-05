#!/usr/bin/env bqn

# Characterization tests for current config resolution semantics.
# A4 Phase 1: verification only. This file must not change runtime behavior.

lib ← •Import "test_lib.bqn"
conf ← •Import "../src_next/config.bqn"

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

•Out "test_src_next_config.bqn: OK"
