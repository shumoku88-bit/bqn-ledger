#!/usr/bin/env bqn

# Subprocess probe for current Required accessor failure behavior.
# Not auto-discovered by tools/check.sh because the filename does not match test_*.bqn.

conf ← •Import "../src_next/config.bqn"

base‿key ← 2 ↑ •args
cfg ← conf.LoadConfig base

Run ← {𝕊:
  (key ≡ "HOUSEHOLD_GROUP_LIFE") ?
    cfg.HouseholdGroupLifeLabels @ ;
    cfg.HouseholdGroupReserveLabels @
}

Run @
