#!/usr/bin/env bqn

loader ← •Import "../../src/application/source_io.bqn"
ak ← •Import "../../src_next/account_key.bqn"
context ← •Import "../../src_next/context.bqn"
cycle ← •Import "../../src_next/cycle.bqn"
cube ← •Import "../../src_next/cube.bqn"
tbds ← •Import "../../src_next/tbds.bqn"
env ← •Import "../../src_next/envelope_computation.bqn"
actual_source ← •Import "../../src_next/actual_source.bqn"
legacy_parser ← •Import "../../src_next/journal_profile_stage1.bqn"

# Load base context
base ← "fixtures/envelope-characterization"
resolved ← ak.Resolve loader.ReadLines (base ∾ "/accounts.tsv")
cy ← cycle.ReadCycle base

# Build checked projection for sub_invalid_budget_date
miss_base ← "fixtures/envelope-characterization/sub_invalid_budget_date"
miss_snapshot ← context.LoadNonActualPostingSourceSnapshot miss_base
miss_proj ← context.BuildCheckedPostingProjectionFromSnapshot ⟨miss_snapshot, resolved, cy.start⟩
miss_rows ← miss_proj.posting_rows
miss_cube ← cube.Materialize ⟨miss_rows, cy.day_count, resolved.count⟩
miss_tbds ← tbds.Build ⟨miss_rows, miss_cube, resolved, cy⟩

# Carry the characterization's prepared legacy transaction evidence so this
# probe remains focused on invalid Budget date parsing rather than source reload.
raw ← loader.ReadRaw (miss_base∾"/"∾actual_source.ResolveRelativePath miss_base)
txs ← (legacy_parser.ParseWithProfile ⟨raw,"historical_external_plan"⟩).transactions

# This call must crash during InCycle date parsing of "2026-99-99" inside CalcAllocated (compatibility path)
env.Build { base ⇐ miss_base, resolved ⇐ resolved, cy ⇐ cy, cube ⇐ miss_cube, tbds ⇐ miss_tbds, actual_transactions⇐txs }
