#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
snapshot ← •Import "legacy_snapshot_fixture.bqn"
cycle_result ← •Import "../src/accounting/cycle_result.bqn"
cycle_period ← •Import "../src/accounting/cycle_account_period.bqn"
comparison ← •Import "../src/accounting/cycle_comparison.bqn"
section ← •Import "../src/sections/cycle_comparison.bqn"

base ← "fixtures/ledger-facts-phase1-proof/"
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
lines ← loader.ReadLines base∾"accounts.tsv"
facts ← (snapshot.Build ⟨lines,•FChars "../"∾base∾"actual.journal",registry⟩).facts
Window ← {𝕊 start‿finish‿observation:
  cycle_period.Build ⟨facts,"JPY",cycle_result.Success ⟨"fixed",observation,start,finish,⟨⟩,⟨⟩⟩,observation⟩
}
current ← Window ⟨"2026-01-01","2026-02-01","2026-01-10"⟩
baseline ← Window ⟨"2025-12-22","2026-01-22","2025-12-31"⟩
result ← section.Build comparison.Build ⟨current,baseline,"aligned_elapsed"⟩
"ok" lib.AssertEq result.state
7 lib.AssertEq result.matrix.row_count
3 lib.AssertEq result.matrix.column_count
⟨"current_movement","baseline_movement","difference"⟩ lib.AssertEq result.matrix.column_coordinates
⟨980,0,980⟩ lib.AssertEq 0⊑result.matrix.values
"actual.journal" lib.AssertEq (⊑0⊑0⊑result.matrix.contributors).source
980 lib.AssertEq (0⊑result.difference_evidence).current_coefficient
human ← section.FormatHuman result
(•FChars "../"∾base∾"cycle_comparison.fixed.destination.human.txt") lib.AssertEq human

unavailableAccounting ← comparison.Build ⟨current,cycle_period.Build ⟨facts,"JPY",cycle_result.Unavailable ⟨"incomeAnchor","2025-12-31","anchor_missing"⟩,"2025-12-31"⟩,"aligned_elapsed"⟩
unavailable ← section.Build unavailableAccounting
"unavailable" lib.AssertEq unavailable.state
0 lib.AssertEq unavailable.matrix.row_count
•Out "test_section_cycle_comparison: ok"
