#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registryCore ← •Import "../src/ledger/currency_registry.bqn"
snapshot ← •Import "../src/ledger/snapshot.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
accounting ← •Import "../src/accounting/profit_and_loss.bqn"
section ← •Import "../src/sections/profit_and_loss.bqn"

base ← "fixtures/ledger-facts-phase1-proof/"
registry ← (registryCore.Build loader.ReadLines "config/currencies.tsv").registry
facts ← (snapshot.Build ⟨loader.ReadLines base∾"accounts.tsv",•FChars "../"∾base∾"actual.journal",registry⟩).facts
calculation ← accounting.Build ⟨facts,"JPY",dates.Ordinal "2026-01-01",dates.Ordinal "2026-02-01"⟩
result ← section.Build ⟨calculation,"2026-01-01","2026-02-01"⟩
"ok" lib.AssertEq result.state
965 lib.AssertEq result.net_income
(•FChars "../"∾base∾"profit_and_loss.destination.human.txt") lib.AssertEq section.FormatHuman result
mismatch ← section.Build ⟨calculation,"2026-01-02","2026-02-01"⟩
"error" lib.AssertEq mismatch.state
•Out "test_section_profit_and_loss: ok"
