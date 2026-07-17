#!/usr/bin/env bqn

loader ← •Import "../../src_next/loader.bqn"
ak ← •Import "../../src_next/account_key.bqn"
context ← •Import "../../src_next/context.bqn"
cycle ← •Import "../../src_next/cycle.bqn"
cube ← •Import "../../src_next/cube.bqn"
tbds ← •Import "../../src_next/tbds.bqn"
env ← •Import "../../src_next/envelope_computation.bqn"

# Load base context
base ← "fixtures/envelope-characterization"
resolved ← ak.Resolve loader.ReadLines (base ∾ "/accounts.tsv")
cy ← cycle.ReadCycle base

# Build checked projection for sub_missing_date
miss_base ← "fixtures/envelope-characterization/sub_missing_date"
miss_snapshot ← context.LoadPostingSourceSnapshot miss_base
miss_proj ← context.BuildCheckedPostingProjectionFromSnapshot ⟨miss_snapshot, resolved, cy.start⟩
miss_rows ← miss_proj.posting_rows
miss_cube ← cube.Materialize ⟨miss_rows, cy.day_count, resolved.count⟩
miss_tbds ← tbds.Build ⟨miss_rows, miss_cube, resolved, cy⟩

# This call must crash during InCycle date parsing of "2026-99-99" inside BuildExecutionPlannedCoverage
env.Build { base ⇐ miss_base, resolved ⇐ resolved, cy ⇐ cy, cube ⇐ miss_cube, tbds ⇐ miss_tbds }
