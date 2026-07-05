#!/usr/bin/env bqn

conf ← •Import "../src_next/config.bqn"
base ← ⊑ •args
cfg ← conf.LoadConfig base
cfg.HouseholdGroupLifeLabels @
