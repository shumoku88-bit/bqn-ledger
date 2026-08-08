#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
account_admission ← •Import "../src/ledger/account_admission.bqn"
snapshot ← •Import "../src/ledger/snapshot.bqn"
cycle_admission ← •Import "../src/ledger/cycle_admission.bqn"
fixed_resolver ← •Import "../src/accounting/cycle_fixed_resolution.bqn"
cycle_period ← •Import "../src/accounting/cycle_account_period.bqn"
section ← •Import "../src/sections/cycle_accounts.bqn"

base ← "fixtures/ledger-facts-phase1-proof/"
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
accountLines ← loader.ReadLines base∾"accounts.tsv"
accounts ← (account_admission.Admit ⟨accountLines,registry⟩).accounts
facts ← (snapshot.Build ⟨accountLines,•FChars "../"∾base∾"actual.journal",registry⟩).facts
cycle ← fixed_resolver.Resolve cycle_admission.Admit ⟨loader.ReadLines base∾"cycle.tsv",accounts⟩
accounting ← cycle_period.Build ⟨facts,"JPY",cycle,"2026-01-10"⟩
result ← section.Build accounting
"ok" lib.AssertEq result.state
8 lib.AssertEq result.matrix.row_count
5 lib.AssertEq result.matrix.column_count
⟨"opening","debit","credit","movement","closing"⟩ lib.AssertEq result.matrix.column_coordinates
⟨0,1000,¯20,980,980⟩ lib.AssertEq 0⊑result.matrix.values
⟨0,0,¯1000,¯1000,¯1000⟩ lib.AssertEq 1⊑result.matrix.values
"actual.journal" lib.AssertEq (⊑1⊑0⊑result.matrix.contributors).source
⟨0,1020,¯1020,0,0⟩ lib.AssertEq ⟨result.totals.opening,result.totals.debit,result.totals.credit,result.totals.movement,result.totals.closing⟩
1 lib.AssertEq result.totals.balanced
human ← section.FormatHuman result
(•FChars "../"∾base∾"cycle_accounts.fixed.destination.human.txt") lib.AssertEq human

unavailable ← section.Build {
  state⇐"unavailable",reason⇐"cycle_missing",diagnostics⇐⟨⟩
}
"unavailable" lib.AssertEq unavailable.state
"cycle_missing" lib.AssertEq unavailable.reason
0 lib.AssertEq unavailable.matrix.row_count
•Out "test_section_cycle_accounts: ok"
