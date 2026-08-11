#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
snapshot ← •Import "legacy_snapshot_fixture.bqn"
recent ← •Import "../src/accounting/recent_transactions.bqn"
section ← •Import "../src/sections/recent_journal.bqn"

base ← "fixtures/ledger-facts-phase1-proof/"
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
accountLines ← loader.ReadLines base∾"accounts.tsv"
facts ← (snapshot.Build ⟨accountLines,•FChars "../"∾base∾"actual.journal",registry⟩).facts
result ← section.Build recent.Build ⟨facts,10⟩
"ok" lib.AssertEq result.state
3 lib.AssertEq result.rows.count
⟨"split purchase","completed food plan","salary"⟩ lib.AssertEq result.rows.description
⟨⟨"expenses:food","expenses:transport"⟩,⟨"expenses:food"⟩,⟨"assets:cash"⟩⟩ lib.AssertEq result.rows.debit_accounts
"actual.journal" lib.AssertEq (⊑result.rows.transaction_reference).source

human ← section.FormatHuman result
compact ← section.FormatCompact result
(•FChars "../"∾base∾"recent_journal.destination.human.txt") lib.AssertEq human
(•FChars "../"∾base∾"recent_journal.destination.compact.txt") lib.AssertEq compact

emptyEvidence ← {
  state⇐"ok",limit⇐10,
  rows⇐{
    count⇐0,index⇐⟨⟩,transaction_index⇐⟨⟩,date⇐⟨⟩,description⇐⟨⟩,currency⇐⟨⟩,
    coefficient⇐⟨⟩,scale⇐⟨⟩,credit_accounts⇐⟨⟩,debit_accounts⇐⟨⟩,
    transaction_reference⇐⟨⟩,debit_contributors⇐⟨⟩,credit_contributors⇐⟨⟩
  },diagnostics⇐⟨⟩
}
emptyResult ← section.Build emptyEvidence
"ok" lib.AssertEq emptyResult.state
lib.Assert ∨´"ledger_recent_journal: (none)"⍷section.FormatCompact emptyResult
lib.Assert ∨´"(none)"⍷section.FormatHuman emptyResult
rejected ← section.Build {state⇐"error"}
"error" lib.AssertEq rejected.state
0 lib.AssertEq rejected.rows.count
•Out "test_section_recent_journal: ok"
