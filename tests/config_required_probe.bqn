#!/usr/bin/env bqn

# Subprocess probe for current Required accessor behavior.
# Not auto-discovered because the filename does not match test_*.bqn.

conf ← •Import "../src_next/config.bqn"

base‿key ← 2 ↑ •args
cfg ← conf.LoadConfig base
accessor ← (key ≡ "HOUSEHOLD_GROUP_LIFE") ⊑
  ⟨cfg.HouseholdGroupReserveLabels, cfg.HouseholdGroupLifeLabels⟩

accessor @
