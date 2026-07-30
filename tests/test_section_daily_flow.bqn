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

syntheticStartText ← "2026-02-01"
syntheticEndText ← "2026-02-02"
syntheticStart ← dates.Ordinal syntheticStartText
syntheticEnd ← dates.Ordinal syntheticEndText
syntheticFlow ← {
  state⇐"ok",domain⇐"JPY",layer⇐"actual",
  start_ordinal⇐syntheticStart,end_exclusive_ordinal⇐syntheticEnd,scale⇐0,
  dates⇐{
    count⇐1,index⇐⟨0⟩,date_ordinal⇐⟨syntheticStart⟩,date_text⇐⟨syntheticStartText⟩,
    income⇐⟨10⟩,net⇐⟨6⟩,income_contributors⇐⟨⟨5,1,5⟩⟩
  },
  categories⇐{
    count⇐1,index⇐⟨0⟩,label⇐⟨"food"⟩,kind⇐⟨"envelope"⟩,
    envelope_account_index⇐⟨0⟩
  },
  expense_groups⇐{
    count⇐1,index⇐⟨0⟩,row_index⇐⟨0⟩,column_index⇐⟨0⟩,
    coefficient⇐⟨4⟩,contributors⇐⟨⟨3,1,3⟩⟩
  },
  diagnostics⇐⟨⟩
}
deduplicated ← section.Build ⟨syntheticFlow,syntheticStartText,syntheticEndText,syntheticStartText⟩
"ok" lib.AssertEq deduplicated.state
⟨syntheticStartText⟩ lib.AssertEq deduplicated.date_text
⟨⟨10,4,6⟩⟩ lib.AssertEq deduplicated.matrix.values
⟨5,1,5⟩ lib.AssertEq 0⊑0⊑deduplicated.matrix.contributors
⟨3,1,3⟩ lib.AssertEq 1⊑0⊑deduplicated.matrix.contributors
⟨1,3,5⟩ lib.AssertEq 2⊑0⊑deduplicated.matrix.contributors

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
⟨⟨0,0,0,0⟩⟩ lib.AssertEq emptyResult.matrix.values

rejected ← section.Build ⟨accounting,cycle.definition.start,cycle.definition.end_exclusive,"2026-01-11"⟩
"error" lib.AssertEq rejected.state
0 lib.AssertEq rejected.matrix.cell_count
1 lib.AssertEq ∨´0∾"observation_evidence_mismatch"⊸≡¨{𝕩.code}¨rejected.diagnostics

•Out "test_section_daily_flow: ok"
