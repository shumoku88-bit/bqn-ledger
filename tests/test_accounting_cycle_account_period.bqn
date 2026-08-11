#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
account_admission ← •Import "../src/ledger/account_admission.bqn"
snapshot ← •Import "legacy_snapshot_fixture.bqn"
cycle_admission ← •Import "../src/ledger/cycle_admission.bqn"
fixed_resolver ← •Import "../src/accounting/cycle_fixed_resolution.bqn"
cycle_result ← •Import "../src/accounting/cycle_result.bqn"
cycle_accounts ← •Import "../src/accounting/cycle_account_period.bqn"

base ← "fixtures/ledger-facts-phase1-proof/"
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
accountLines ← loader.ReadLines base∾"accounts.tsv"
facts ← (snapshot.Build ⟨accountLines,•FChars "../"∾base∾"actual.journal",registry⟩).facts
accounts ← (account_admission.Admit ⟨accountLines,registry⟩).accounts
cycle ← fixed_resolver.Resolve cycle_admission.Admit ⟨loader.ReadLines base∾"cycle.tsv",accounts⟩

partial ← cycle_accounts.Build ⟨facts,"JPY",cycle,"2026-01-10"⟩
"ok" lib.AssertEq partial.state
"2026-01-01" lib.AssertEq partial.cycle_start
"2026-02-01" lib.AssertEq partial.cycle_end_exclusive
8 lib.AssertEq partial.accounts.count
⟨1000,0,20,0,0,0,0,0⟩ lib.AssertEq partial.accounts.debit_movement
⟨¯20,¯1000,0,0,0,0,0,0⟩ lib.AssertEq partial.accounts.credit_movement
⟨980,¯1000,20,0,0,0,0,0⟩ lib.AssertEq partial.accounts.closing
1 lib.AssertEq partial.totals.balanced
"actual.journal" lib.AssertEq (⊑0⊑partial.accounts.debit_contributors).source
2 lib.AssertEq ≠0⊑partial.accounts.closing_contributors

full ← cycle_accounts.Build ⟨facts,"JPY",cycle,"2026-01-31"⟩
"ok" lib.AssertEq full.state
⟨965,¯1000,30,5,0,0,0,0⟩ lib.AssertEq full.accounts.closing
1035 lib.AssertEq full.totals.debit_movement
¯1035 lib.AssertEq full.totals.credit_movement

# Both opening and observed-period evidence are nonempty for cash.
# Closing contributors must preserve opening-first, then period source order.
shiftedCycle ← cycle_result.Success ⟨"fixed","2026-01-12","2026-01-11","2026-02-01",⟨⟩,⟨⟩⟩
shifted ← cycle_accounts.Build ⟨facts,"JPY",shiftedCycle,"2026-01-12"⟩
"ok" lib.AssertEq shifted.state
⟨"proof-salary-1:0","proof-food-1:1"⟩ lib.AssertEq {𝕩.posting_id}¨0⊑shifted.accounts.opening_contributors
⟨⟩ lib.AssertEq {𝕩.posting_id}¨0⊑shifted.accounts.debit_contributors
⟨"proof-split-1:2"⟩ lib.AssertEq {𝕩.posting_id}¨0⊑shifted.accounts.credit_contributors
⟨"proof-split-1:2"⟩ lib.AssertEq {𝕩.posting_id}¨0⊑shifted.accounts.movement_contributors
⟨"proof-salary-1:0","proof-food-1:1","proof-split-1:2"⟩ lib.AssertEq {𝕩.posting_id}¨0⊑shifted.accounts.closing_contributors

lf ← @+10
BuildDomain ← {𝕊 currency‿lines‿raw‿observation:
  domainFacts ← (snapshot.Build ⟨lines,raw,registry⟩).facts
  resolved ← cycle_result.Success ⟨"fixed",observation,"2026-03-01","2026-04-01",⟨⟩,⟨⟩⟩
  cycle_accounts.Build ⟨domainFacts,currency,resolved,observation⟩
}
ilsLines ← ⟨
  "assets:ils	role=asset	type=liquid	currency=ILS",
  "expenses:a-ils	role=expense	currency=ILS",
  "expenses:b-ils	role=expense	currency=ILS"
⟩
ilsRaw ← ∾⟨
  "commodity ILS",lf,lf,
  "account assets:ils",lf,"    ; role: asset",lf,lf,
  "account expenses:a-ils",lf,"    ; role: expense",lf,lf,
  "account expenses:b-ils",lf,"    ; role: expense",lf,lf,
  "2026-03-01 * a",lf,"    ; event-id: ils-a",lf,"    ; layer: actual",lf,
  "    expenses:a-ils 12.3 ILS",lf,"    assets:ils -12.3 ILS",lf,lf,
  "2026-03-02 * b",lf,"    ; event-id: ils-b",lf,"    ; layer: actual",lf,
  "    expenses:b-ils 0.05 ILS",lf,"    assets:ils -0.05 ILS",lf
⟩
ils ← BuildDomain ⟨"ILS",ilsLines,ilsRaw,"2026-03-02"⟩
"ok" lib.AssertEq ils.state
2 lib.AssertEq ils.scale
⟨¯1235,1230,5⟩ lib.AssertEq ils.accounts.closing

usdLines ← ⟨"assets:usd	role=asset	currency=USD","expenses:usd	role=expense	currency=USD"⟩
usdRaw ← ∾⟨
  "commodity USD",lf,lf,
  "account assets:usd",lf,"    ; role: asset",lf,lf,
  "account expenses:usd",lf,"    ; role: expense",lf
⟩
usd ← BuildDomain ⟨"USD",usdLines,usdRaw,"2026-03-02"⟩
"ok" lib.AssertEq usd.state
⟨0,0⟩ lib.AssertEq usd.accounts.closing
⟨⟨⟩,⟨⟩⟩ lib.AssertEq usd.accounts.closing_contributors

outside ← cycle_accounts.Build ⟨facts,"JPY",cycle,"2026-02-01"⟩
"error" lib.AssertEq outside.state
0 lib.AssertEq outside.accounts.count
"observation_outside_cycle" lib.AssertEq (⊑outside.diagnostics).code
mismatchCycle ← cycle_result.Success ⟨"calendarMonth","2026-01-09","2026-01-01","2026-02-01",⟨⟩,⟨⟩⟩
mismatch ← cycle_accounts.Build ⟨facts,"JPY",mismatchCycle,"2026-01-10"⟩
"error" lib.AssertEq mismatch.state
lib.Assert 1=≠mismatch.diagnostics
"cycle_observation_mismatch" lib.AssertEq (⊑mismatch.diagnostics).code
invalidDate ← cycle_accounts.Build ⟨facts,"JPY",cycle,"2026-01-40"⟩
"error" lib.AssertEq invalidDate.state
"observation_invalid" lib.AssertEq (⊑invalidDate.diagnostics).code
unavailableCycle ← cycle_result.Unavailable ⟨"incomeAnchor","2026-01-10","planned_income_anchor_missing"⟩
unavailable ← cycle_accounts.Build ⟨facts,"JPY",unavailableCycle,"2026-01-10"⟩
"unavailable" lib.AssertEq unavailable.state
"planned_income_anchor_missing" lib.AssertEq unavailable.reason
0 lib.AssertEq unavailable.accounts.count
•Out "test_accounting_cycle_account_period: ok"
