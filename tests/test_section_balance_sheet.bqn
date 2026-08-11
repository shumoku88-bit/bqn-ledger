#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registryCore ← •Import "../src/ledger/currency_registry.bqn"
snapshot ← •Import "legacy_snapshot_fixture.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
accounting ← •Import "../src/accounting/balance_sheet.bqn"
section ← •Import "../src/sections/balance_sheet.bqn"

base ← "fixtures/ledger-facts-phase1-proof/"
registry ← (registryCore.Build loader.ReadLines "config/currencies.tsv").registry
facts ← (snapshot.Build ⟨loader.ReadLines base∾"accounts.tsv",•FChars "../"∾base∾"actual.journal",registry⟩).facts
calculation ← accounting.Build ⟨facts,"JPY",dates.Ordinal "2026-01-12"⟩
result ← section.Build ⟨calculation,"2026-01-12"⟩
"ok" lib.AssertEq result.state
1 lib.AssertEq result.balanced
(•FChars "../"∾base∾"balance_sheet.destination.human.txt") lib.AssertEq section.FormatHuman result
mismatch ← section.Build ⟨calculation,"2026-01-11"⟩
"error" lib.AssertEq mismatch.state
•Out "test_section_balance_sheet: ok"
