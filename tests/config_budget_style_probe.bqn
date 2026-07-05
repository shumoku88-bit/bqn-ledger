#!/usr/bin/env bqn

# Subprocess probe for POLICY_BUDGET_STYLE load/accessor behavior.
# Not auto-discovered because the filename does not match test_*.bqn.

conf ← •Import "../src_next/config.bqn"
base ← ⊑ •args
cfg ← conf.LoadConfig base
cfg.PolicyBudgetStyle @
