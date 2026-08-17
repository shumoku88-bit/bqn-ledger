#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
snapshot ← •Import "canonical_snapshot_fixture.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
balance ← •Import "../src/accounting/account_balance.bqn"
section ← •Import "../src/sections/account_balances.bqn"

base ← "fixtures/ledger-facts-phase1-proof/"
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
accountSource ← •FChars "../"∾base∾"accounts.journal"
facts ← (snapshot.Build ⟨accountSource,•FChars "../"∾base∾"actual.journal",registry⟩).facts
accountState ← balance.Build ⟨facts,"JPY",dates.Ordinal "2026-01-12"⟩
result ← section.Build ⟨accountState,"2026-01-12"⟩
"ok" lib.AssertEq result.state
4 lib.AssertEq result.matrix.row_count
1 lib.AssertEq result.matrix.column_count
⟨⟨965⟩,⟨¯1000⟩,⟨30⟩,⟨5⟩⟩ lib.AssertEq result.matrix.values
3 lib.AssertEq ≠⊑0⊑result.matrix.contributors
1 lib.AssertEq result.balanced

human ← section.FormatHuman result
compact ← section.FormatCompact result
json ← section.FormatJson result
(•FChars "../"∾base∾"account_balances.destination.human.txt") lib.AssertEq human
(•FChars "../"∾base∾"account_balances.destination.compact.txt") lib.AssertEq compact
(•FChars "../"∾base∾"account_balances.destination.json") lib.AssertEq json
lib.Assert ∨´"balance"⍷json

SyntheticState ← {𝕊 domain‿scaleValue‿keys‿values:
  {
    state⇐"ok",domain⇐domain,observation_ordinal⇐dates.Ordinal "2026-03-02",scale⇐scaleValue,balanced⇐(+´values)=0,
    accounts⇐{
      count⇐≠keys,index⇐↕≠keys,account_index⇐↕≠keys,account_key⇐keys,
      role⇐(≠keys)⥊⟨"asset","expense","expense"⟩,type⇐(≠keys)⥊⟨"liquid","",""⟩,
      closing⇐values,contributors⇐{⟨⟩}¨↕≠keys
    },diagnostics⇐⟨⟩
  }
}
ilsState ← SyntheticState ⟨"ILS",2,⟨"assets:ils","expenses:a-ils","expenses:b-ils"⟩,⟨¯1235,1230,5⟩⟩
ilsResult ← section.Build ⟨ilsState,"2026-03-02"⟩
"ok" lib.AssertEq ilsResult.state
lib.Assert ∨´"12.30"⍷section.FormatJson ilsResult
lib.Assert ∨´"ledger_balance: expenses:b-ils/ILS 0.05"⍷section.FormatCompact ilsResult
usdState ← SyntheticState ⟨"USD",2,⟨"assets:usd","expenses:usd"⟩,⟨0,0⟩⟩
usdResult ← section.Build ⟨usdState,"2026-03-02"⟩
"ok" lib.AssertEq usdResult.state
2 lib.AssertEq usdResult.matrix.row_count
lib.Assert ∨´"0.00"⍷section.FormatHuman usdResult

badText ← section.Build ⟨accountState,"2026-01-11"⟩
"error" lib.AssertEq badText.state
0 lib.AssertEq badText.matrix.row_count
0 lib.AssertEq badText.matrix.column_count
"observation_mismatch" lib.AssertEq (⊑badText.diagnostics).code
•Out "test_section_account_balances: ok"
