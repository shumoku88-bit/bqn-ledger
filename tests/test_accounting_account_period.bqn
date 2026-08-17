#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
snapshot ← •Import "canonical_snapshot_fixture.bqn"
account_admission ← •Import "../src/ledger/account_journal_admission.bqn"
canonicalPlan ← •Import "canonical_plan_test_facts.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
cycle_admission ← •Import "../src/ledger/cycle_admission.bqn"
scale ← •Import "../src/ledger/exact_scale.bqn"
period ← •Import "../src/accounting/account_period.bqn"

base ← "fixtures/ledger-facts-phase1-proof/"
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
accountSource ← •FChars "../"∾base∾"accounts.journal"
facts ← (snapshot.Build ⟨accountSource,•FChars "../"∾base∾"actual.journal",registry⟩).facts
cycle ← cycle_admission.Admit ⟨loader.ReadLines base∾"cycle.tsv",facts.accounts⟩
"ok" lib.AssertEq cycle.state
start ← dates.Ordinal cycle.definition.start
end ← dates.Ordinal cycle.definition.end_exclusive
result ← period.Build ⟨facts,"JPY","actual",start,end⟩

"ok" lib.AssertEq result.state
0 lib.AssertEq ≠result.diagnostics
7 lib.AssertEq ≠facts.postings.index
4 lib.AssertEq result.accounts.count
facts.accounts.key lib.AssertEq result.accounts.account_key
(4⥊0) lib.AssertEq result.accounts.opening
⟨1000,0,30,5⟩ lib.AssertEq result.accounts.debit_movement
⟨¯35,¯1000,0,0⟩ lib.AssertEq result.accounts.credit_movement
⟨965,¯1000,30,5⟩ lib.AssertEq result.accounts.closing
0 lib.AssertEq result.totals.opening
1035 lib.AssertEq result.totals.debit_movement
¯1035 lib.AssertEq result.totals.credit_movement
0 lib.AssertEq result.totals.closing
1 lib.AssertEq result.totals.balanced
⟨0⟩ lib.AssertEq 0⊑result.accounts.debit_contributors
⟨3,6⟩ lib.AssertEq 0⊑result.accounts.credit_contributors
⟨2,4⟩ lib.AssertEq 2⊑result.accounts.debit_contributors
⟨5⟩ lib.AssertEq 3⊑result.accounts.debit_contributors

late ← period.Build ⟨facts,"JPY","actual",dates.Ordinal "2026-01-11",end⟩
"ok" lib.AssertEq late.state
⟨980,¯1000,20,0⟩ lib.AssertEq late.accounts.opening
⟨0,0,10,5⟩ lib.AssertEq late.accounts.debit_movement
⟨¯15,0,0,0⟩ lib.AssertEq late.accounts.credit_movement
⟨965,¯1000,30,5⟩ lib.AssertEq late.accounts.closing
⟨0,3⟩ lib.AssertEq 0⊑late.accounts.opening_contributors
⟨6⟩ lib.AssertEq 0⊑late.accounts.credit_contributors
0 lib.AssertEq late.totals.opening
15 lib.AssertEq late.totals.debit_movement
¯15 lib.AssertEq late.totals.credit_movement
1 lib.AssertEq late.totals.balanced

normalized ← scale.Normalize ⟨¯12,0,2⟩
"ok" lib.AssertEq normalized.state
¯1200 lib.AssertEq normalized.coefficient
7 lib.AssertEq (scale.Sum ⟨10,¯3⟩).coefficient
"error" lib.AssertEq (scale.Normalize ⟨9007199254740991,0,1⟩).state
"error" lib.AssertEq (scale.Sum ⟨9007199254740991,2⟩).state

lf ← @+10
scaleAccountSource ← ∾⟨
  "account assets:jpy",lf,"  type: Asset",lf,"  commodity: JPY",lf,lf,
  "account expenses:jpy",lf,"  type: Expense",lf,"  commodity: JPY",lf
⟩
scaleAccounts ← (account_admission.Admit scaleAccountSource).accounts
scalePlanRaw ← ∾{𝕩∾@+10}¨⟨
  "2026-01-10 whole","  ; plan-id: p1","  expenses:jpy 25 JPY","  assets:jpy -25 JPY","",
  "2026-01-11 fraction","  ; plan-id: p2","  expenses:jpy 12.30 JPY","  assets:jpy -12.30 JPY"
⟩
scaleFacts ← (canonicalPlan.Build ⟨scalePlanRaw,scaleAccounts,registry⟩).facts
scalePeriod ← period.Build ⟨scaleFacts,"JPY","plan",start,end⟩
"ok" lib.AssertEq scalePeriod.state
1 lib.AssertEq scalePeriod.scale
⟨¯373,373⟩ lib.AssertEq scalePeriod.accounts.closing
373 lib.AssertEq scalePeriod.totals.debit_movement
¯373 lib.AssertEq scalePeriod.totals.credit_movement
1 lib.AssertEq scalePeriod.totals.balanced

BuildActualPeriod ← {𝕊 currency‿accountSourceValue‿raw‿firstDate‿lastDate:
  domainFacts ← (snapshot.Build ⟨accountSourceValue,raw,registry⟩).facts
  period.Build ⟨domainFacts,currency,"actual",dates.Ordinal firstDate,dates.Ordinal lastDate⟩
}
periodAccountSource ← ∾⟨
  "account assets:ils",lf,"  type: Asset",lf,"  commodity: ILS",lf,lf,
  "account expenses:a-ils",lf,"  type: Expense",lf,"  commodity: ILS",lf,lf,
  "account expenses:b-ils",lf,"  type: Expense",lf,"  commodity: ILS",lf
⟩
periodRaw ← ∾⟨
  "commodity ILS",lf,lf,"account assets:ils",lf,"    ; role: asset",lf,lf,
  "account expenses:a-ils",lf,"    ; role: expense",lf,lf,
  "account expenses:b-ils",lf,"    ; role: expense",lf,lf,
  "2026-02-20 * Opening A first",lf,"    ; event-id: period-opening-a-first",lf,"    ; layer: actual",lf,
  "    expenses:a-ils 10 ILS",lf,"    assets:ils -10 ILS",lf,lf,
  "2026-02-21 * Opening A second",lf,"    ; event-id: period-opening-a-second",lf,"    ; layer: actual",lf,
  "    expenses:a-ils -10 ILS",lf,"    assets:ils 10 ILS",lf,lf,
  "2026-03-01 * Period A first",lf,"    ; event-id: period-a-first",lf,"    ; layer: actual",lf,
  "    expenses:a-ils 7 ILS",lf,"    assets:ils -7 ILS",lf,lf,
  "2026-03-02 * Period B",lf,"    ; event-id: period-b",lf,"    ; layer: actual",lf,
  "    expenses:b-ils 5 ILS",lf,"    assets:ils -5 ILS",lf,lf,
  "2026-03-03 * Period A second",lf,"    ; event-id: period-a-second",lf,"    ; layer: actual",lf,
  "    expenses:a-ils -7 ILS",lf,"    assets:ils 7 ILS",lf
⟩
characterized ← BuildActualPeriod ⟨"ILS",periodAccountSource,periodRaw,"2026-03-01","2026-04-01"⟩
"ok" lib.AssertEq characterized.state
⟨"assets:ils","expenses:a-ils","expenses:b-ils"⟩ lib.AssertEq characterized.accounts.account_key
⟨0,0,0⟩ lib.AssertEq characterized.accounts.opening
⟨7,7,5⟩ lib.AssertEq characterized.accounts.debit_movement
⟨¯12,¯7,0⟩ lib.AssertEq characterized.accounts.credit_movement
⟨¯5,0,5⟩ lib.AssertEq characterized.accounts.movement
⟨¯5,0,5⟩ lib.AssertEq characterized.accounts.closing
⟨⟨1,3⟩,⟨0,2⟩,⟨⟩⟩ lib.AssertEq characterized.accounts.opening_contributors
⟨⟨9⟩,⟨4⟩,⟨6⟩⟩ lib.AssertEq characterized.accounts.debit_contributors
⟨⟨5,7⟩,⟨8⟩,⟨⟩⟩ lib.AssertEq characterized.accounts.credit_contributors
⟨⟨5,7,9⟩,⟨4,8⟩,⟨6⟩⟩ lib.AssertEq characterized.accounts.period_contributors
0 lib.AssertEq characterized.totals.opening
19 lib.AssertEq characterized.totals.debit_movement
¯19 lib.AssertEq characterized.totals.credit_movement
0 lib.AssertEq characterized.totals.movement
0 lib.AssertEq characterized.totals.closing
1 lib.AssertEq characterized.totals.balanced

emptyAccountSource ← ∾⟨
  "account assets:usd",lf,"  type: Asset",lf,"  commodity: USD",lf,lf,
  "account expenses:usd",lf,"  type: Expense",lf,"  commodity: USD",lf
⟩
emptyRaw ← ∾⟨
  "commodity USD",lf,lf,"account assets:usd",lf,"    ; role: asset",lf,lf,
  "account expenses:usd",lf,"    ; role: expense",lf
⟩
emptyPeriod ← BuildActualPeriod ⟨"USD",emptyAccountSource,emptyRaw,"2026-03-01","2026-04-01"⟩
"ok" lib.AssertEq emptyPeriod.state
2 lib.AssertEq emptyPeriod.accounts.count
⟨0,0⟩ lib.AssertEq emptyPeriod.accounts.opening
⟨0,0⟩ lib.AssertEq emptyPeriod.accounts.debit_movement
⟨0,0⟩ lib.AssertEq emptyPeriod.accounts.credit_movement
⟨0,0⟩ lib.AssertEq emptyPeriod.accounts.movement
⟨0,0⟩ lib.AssertEq emptyPeriod.accounts.closing
⟨⟨⟩,⟨⟩⟩ lib.AssertEq emptyPeriod.accounts.opening_contributors
⟨⟨⟩,⟨⟩⟩ lib.AssertEq emptyPeriod.accounts.debit_contributors
⟨⟨⟩,⟨⟩⟩ lib.AssertEq emptyPeriod.accounts.credit_contributors
⟨⟨⟩,⟨⟩⟩ lib.AssertEq emptyPeriod.accounts.period_contributors
0 lib.AssertEq emptyPeriod.totals.opening
0 lib.AssertEq emptyPeriod.totals.debit_movement
0 lib.AssertEq emptyPeriod.totals.credit_movement
0 lib.AssertEq emptyPeriod.totals.movement
0 lib.AssertEq emptyPeriod.totals.closing
1 lib.AssertEq emptyPeriod.totals.balanced

CheckRejected ← {𝕊 domain‿layer‿s‿e‿code:
  rejected ← period.Build ⟨facts,domain,layer,s,e⟩
  "error" lib.AssertEq rejected.state
  0 lib.AssertEq rejected.accounts.count
  ⟨⟩ lib.AssertEq rejected.totals.opening
  1 lib.AssertEq ∨´0∾code⊸≡¨{𝕩.code}¨rejected.diagnostics
}
CheckRejected ⟨"USD","actual",start,end,"domain_unknown"⟩
CheckRejected ⟨"JPY","plan",start,end,"layer_unknown"⟩
CheckRejected ⟨"JPY","actual",end,start,"period_range_invalid"⟩

•Out "test_accounting_account_period: ok"
