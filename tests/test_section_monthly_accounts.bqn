#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
loader ← •Import "../src_next/loader.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
snapshot ← •Import "../src/ledger/snapshot.bqn"
monthly ← •Import "../src/accounting/month_account_movement.bqn"
section ← •Import "../src/sections/monthly_accounts.bqn"

base ← "fixtures/ledger-facts-phase1-proof/"
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
lines ← loader.ReadLines base∾"accounts.tsv"
facts ← (snapshot.Build ⟨lines,•FChars "../"∾base∾"actual.journal",registry⟩).facts
result ← section.Build monthly.Build ⟨facts,"JPY","2026-01","2026-03"⟩
"ok" lib.AssertEq result.state
2 lib.AssertEq result.matrix.row_count
8 lib.AssertEq result.matrix.column_count
⟨"2026-01","2026-02"⟩ lib.AssertEq result.matrix.row_coordinates
facts.accounts.index lib.AssertEq result.matrix.column_coordinates
⟨965,¯1000,30,5,0,0,0,0⟩ lib.AssertEq 0⊑result.matrix.values
"actual.journal" lib.AssertEq (⊑0⊑0⊑result.matrix.contributors).source
human ← section.FormatHuman result
(•FChars "../"∾base∾"monthly_accounts.destination.human.txt") lib.AssertEq human
rejected ← section.Build monthly.Build ⟨facts,"USD","2026-01","2026-03"⟩
"error" lib.AssertEq rejected.state
0 lib.AssertEq rejected.matrix.row_count
•Out "test_section_monthly_accounts: ok"
