#!/usr/bin/env bqn

# Subprocess probe for typed policy accessor behavior.
# Not auto-discovered because the filename does not match test_*.bqn.

conf ← •Import "../src_next/config.bqn"
base‿key ← 2 ↑ •args
cfg ← conf.LoadConfig base
accessor ← (key ≡ "POLICY_BUDGET_STYLE") ⊑
  ⟨cfg.PolicyRiskStyle, cfg.PolicyBudgetStyle⟩

accessor @
