#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
snapshot ← •Import "../src/ledger/snapshot.bqn"
monthly ← •Import "../src/accounting/month_account_movement.bqn"

base ← "fixtures/ledger-facts-phase1-proof/"
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
lines ← loader.ReadLines base∾"accounts.tsv"
facts ← (snapshot.Build ⟨lines,•FChars "../"∾base∾"actual.journal",registry⟩).facts
result ← monthly.Build ⟨facts,"JPY","2026-01","2026-03"⟩
"ok" lib.AssertEq result.state
⟨"2026-01","2026-02"⟩ lib.AssertEq result.months
8 lib.AssertEq result.matrix.column_count
⟨965,¯1000,30,5,0,0,0,0⟩ lib.AssertEq 0⊑result.matrix.values
(8⥊0) lib.AssertEq 1⊑result.matrix.values
⟨0,0⟩ lib.AssertEq result.totals.month
⟨965,¯1000,30,5,0,0,0,0⟩ lib.AssertEq result.totals.account
0 lib.AssertEq result.totals.grand
1 lib.AssertEq result.totals.balanced
"actual.journal" lib.AssertEq (⊑0⊑0⊑result.matrix.contributors).source
⟨⟨⟩,⟨⟩,⟨⟩,⟨⟩,⟨⟩,⟨⟩,⟨⟩,⟨⟩⟩ lib.AssertEq 1⊑result.matrix.contributors

lf ← @+10
BuildDomain ← {𝕊 currency‿accountLines‿raw:
  domainFacts ← (snapshot.Build ⟨accountLines,raw,registry⟩).facts
  monthly.Build ⟨domainFacts,currency,"2026-03","2026-05"⟩
}
ilsLines ← ⟨
  "assets:ils	role=asset	currency=ILS",
  "expenses:a-ils	role=expense	currency=ILS",
  "expenses:b-ils	role=expense	currency=ILS"
⟩
ilsRaw ← ∾⟨
  "commodity ILS",lf,lf,"account assets:ils",lf,"    ; role: asset",lf,lf,
  "account expenses:a-ils",lf,"    ; role: expense",lf,lf,
  "account expenses:b-ils",lf,"    ; role: expense",lf,lf,
  "2026-03-01 * a",lf,"    ; event-id: ils-a",lf,"    ; layer: actual",lf,
  "    expenses:a-ils 12.3 ILS",lf,"    assets:ils -12.3 ILS",lf,lf,
  "2026-03-02 * b",lf,"    ; event-id: ils-b",lf,"    ; layer: actual",lf,
  "    expenses:b-ils 0.05 ILS",lf,"    assets:ils -0.05 ILS",lf
⟩
ils ← BuildDomain ⟨"ILS",ilsLines,ilsRaw⟩
"ok" lib.AssertEq ils.state
2 lib.AssertEq ils.scale
⟨¯1235,1230,5⟩ lib.AssertEq 0⊑ils.matrix.values
⟨0,0,0⟩ lib.AssertEq 1⊑ils.matrix.values

usdLines ← ⟨"assets:usd	role=asset	currency=USD","expenses:usd	role=expense	currency=USD"⟩
usdRaw ← ∾⟨"commodity USD",lf,lf,"account assets:usd",lf,"    ; role: asset",lf,lf,"account expenses:usd",lf,"    ; role: expense",lf⟩
usd ← BuildDomain ⟨"USD",usdLines,usdRaw⟩
"ok" lib.AssertEq usd.state
⟨⟨0,0⟩,⟨0,0⟩⟩ lib.AssertEq usd.matrix.values

CheckError ← {𝕊 domain‿first‿last‿code:
  rejected ← monthly.Build ⟨facts,domain,first,last⟩
  "error" lib.AssertEq rejected.state
  0 lib.AssertEq rejected.matrix.row_count
  lib.Assert ∨´code⊸≡¨{𝕩.code}¨rejected.diagnostics
}
CheckError ⟨"USD","2026-01","2026-03","domain_unknown"⟩
CheckError ⟨"JPY","2026-1","2026-03","first_month_invalid"⟩
CheckError ⟨"JPY","2026-03","2026-03","month_range_invalid"⟩
•Out "test_accounting_month_account_movement: ok"
