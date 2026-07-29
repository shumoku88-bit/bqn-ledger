#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
snapshot ← •Import "../src/ledger/snapshot.bqn"
cycle_admission ← •Import "../src/ledger/cycle_admission.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
flow ← •Import "../src/accounting/date_category_flow.bqn"
section ← •Import "../src/sections/daily_flow.bqn"

base ← "fixtures/ledger-facts-phase1-proof/"
accountLines ← loader.ReadLines base∾"accounts.tsv"
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
facts ← (snapshot.Build ⟨accountLines,•FChars "../"∾base∾"actual.journal",registry⟩).facts
cycle ← cycle_admission.Admit ⟨loader.ReadLines base∾"cycle.tsv",facts.accounts⟩
start ← dates.Ordinal cycle.definition.start
end ← dates.Ordinal cycle.definition.end_exclusive
accounting ← flow.Build ⟨facts,"JPY","actual",start,end⟩
result ← section.Build ⟨accounting,cycle.definition.start,cycle.definition.end_exclusive,"2026-01-12"⟩

"ok" lib.AssertEq result.state
0 lib.AssertEq ≠result.diagnostics
⟨"income","food","other","net"⟩ lib.AssertEq result.column_labels
⟨"2026-01-02","2026-01-10","2026-01-12"⟩ lib.AssertEq result.date_text
# As-of is already the final accounting date, so row-axis dedup retains three rows.
3 lib.AssertEq result.matrix.row_count
⟨
  ⟨1000,0,0,1000⟩,
  ⟨0,20,0,¯20⟩,
  ⟨0,10,5,¯15⟩
⟩ lib.AssertEq result.matrix.values
⟨1,2⟩ lib.AssertEq result.expense_column_indices
⟨1⟩ lib.AssertEq 0⊑0⊑result.matrix.contributors
⟨1⟩ lib.AssertEq 3⊑0⊑result.matrix.contributors
⟨2⟩ lib.AssertEq 1⊑1⊑result.matrix.contributors
⟨2⟩ lib.AssertEq 3⊑1⊑result.matrix.contributors
⟨4,5⟩ lib.AssertEq 3⊑2⊑result.matrix.contributors

human ← section.FormatHuman result
human lib.AssertEq section.FormatHuman result
(•FChars "../"∾base∾"daily_flow.destination.human.txt") lib.AssertEq human

lf ← @+10
emptyRaw ← ∾⟨"commodity JPY"∾lf,""∾lf,"account assets:cash"∾lf⟩
emptyFacts ← (snapshot.Build ⟨accountLines,emptyRaw,registry⟩).facts
⟨"actual"⟩ lib.AssertEq emptyFacts.layers.name
emptyAccounting ← flow.Build ⟨emptyFacts,"JPY","actual",start,end⟩
"ok" lib.AssertEq emptyAccounting.state
0 lib.AssertEq emptyAccounting.dates.count
emptyResult ← section.Build ⟨emptyAccounting,cycle.definition.start,cycle.definition.end_exclusive,cycle.definition.start⟩
"ok" lib.AssertEq emptyResult.state
⟨"2026-01-01"⟩ lib.AssertEq emptyResult.date_text
1 lib.AssertEq emptyResult.matrix.row_count
⟨⟨0,0,0,0⟩⟩ lib.AssertEq emptyResult.matrix.values
# The not-found source-row coordinate selects appended zero and empty contributor cells.
⟨⟨⟨⟩,⟨⟩,⟨⟩,⟨⟩⟩⟩ lib.AssertEq emptyResult.matrix.contributors

rejected ← section.Build ⟨accounting,cycle.definition.start,cycle.definition.end_exclusive,"2026-01-11"⟩
"error" lib.AssertEq rejected.state
0 lib.AssertEq rejected.matrix.cell_count
1 lib.AssertEq ∨´0∾"observation_evidence_mismatch"⊸≡¨{𝕩.code}¨rejected.diagnostics

•Out "test_section_daily_flow: ok"
