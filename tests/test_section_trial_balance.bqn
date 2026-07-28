#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
loader ← •Import "../src_next/loader.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
snapshot ← •Import "../src/ledger/snapshot.bqn"
cycle_admission ← •Import "../src/ledger/cycle_admission.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
account_period ← •Import "../src/accounting/account_period.bqn"
section ← •Import "../src/sections/trial_balance.bqn"

base ← "fixtures/ledger-facts-phase1-proof/"
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
facts ← (snapshot.Build ⟨loader.ReadLines base∾"accounts.tsv",•FChars "../"∾base∾"actual.journal",registry⟩).facts
cycle ← cycle_admission.Admit ⟨loader.ReadLines base∾"cycle.tsv",facts.accounts⟩
start ← dates.Ordinal cycle.definition.start
end ← dates.Ordinal cycle.definition.end_exclusive
accountState ← account_period.Build ⟨facts,"JPY","actual",start,end⟩
result ← section.Build ⟨accountState,cycle.definition.start,cycle.definition.end_exclusive⟩

"ok" lib.AssertEq result.state
0 lib.AssertEq ≠result.diagnostics
"JPY" lib.AssertEq result.domain
"actual" lib.AssertEq result.layer
8 lib.AssertEq result.matrix.row_count
4 lib.AssertEq result.matrix.column_count
⟨"opening","debit_movement","credit_movement","closing"⟩ lib.AssertEq result.matrix.column_coordinates
⟨0,1,2,3,4,5,6,7⟩ lib.AssertEq result.matrix.row_coordinates
⟨
  ⟨0,1000,¯35,965⟩,
  ⟨0,0,¯1000,¯1000⟩,
  ⟨0,30,0,30⟩,
  ⟨0,5,0,5⟩,
  ⟨0,0,0,0⟩,⟨0,0,0,0⟩,⟨0,0,0,0⟩,⟨0,0,0,0⟩
⟩ lib.AssertEq result.matrix.values
⟨⟩ lib.AssertEq 0⊑0⊑result.matrix.contributors
⟨0⟩ lib.AssertEq 1⊑0⊑result.matrix.contributors
⟨3,6⟩ lib.AssertEq 2⊑0⊑result.matrix.contributors
⟨0,3,6⟩ lib.AssertEq 3⊑0⊑result.matrix.contributors
1035 lib.AssertEq result.totals.debit_movement
¯1035 lib.AssertEq result.totals.credit_movement
1 lib.AssertEq result.totals.balanced

human ← section.FormatHuman result
compact ← section.FormatCompact result
human lib.AssertEq section.FormatHuman result
compact lib.AssertEq section.FormatCompact result
(•FChars "../"∾base∾"trial_balance.destination.human.txt") lib.AssertEq human
(•FChars "../"∾base∾"trial_balance.destination.compact.txt") lib.AssertEq compact

rejected ← section.Build ⟨accountState,"2026-01-02",cycle.definition.end_exclusive⟩
"error" lib.AssertEq rejected.state
0 lib.AssertEq rejected.matrix.cell_count
1 lib.AssertEq ∨´0∾"period_start_mismatch"⊸≡¨{𝕩.code}¨rejected.diagnostics

•Out "test_section_trial_balance: ok"
