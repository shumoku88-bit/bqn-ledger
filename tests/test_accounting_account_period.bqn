#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
snapshot ← •Import "../src/ledger/snapshot.bqn"
account_admission ← •Import "../src/ledger/account_admission.bqn"
companion_snapshot ← •Import "../src/ledger/companion_snapshot.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
cycle_admission ← •Import "../src/ledger/cycle_admission.bqn"
scale ← •Import "../src/ledger/exact_scale.bqn"
period ← •Import "../src/accounting/account_period.bqn"

base ← "fixtures/ledger-facts-phase1-proof/"
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
facts ← (snapshot.Build ⟨loader.ReadLines base∾"accounts.tsv",•FChars "../"∾base∾"actual.journal",registry⟩).facts
cycle ← cycle_admission.Admit ⟨loader.ReadLines base∾"cycle.tsv",facts.accounts⟩
"ok" lib.AssertEq cycle.state
start ← dates.Ordinal cycle.definition.start
end ← dates.Ordinal cycle.definition.end_exclusive
result ← period.Build ⟨facts,"JPY","actual",start,end⟩

"ok" lib.AssertEq result.state
0 lib.AssertEq ≠result.diagnostics
0 lib.AssertEq result.scale
8 lib.AssertEq result.accounts.count
facts.accounts.key lib.AssertEq result.accounts.account_key
(8⥊0) lib.AssertEq result.accounts.opening
⟨1000,0,30,5,0,0,0,0⟩ lib.AssertEq result.accounts.debit_movement
⟨¯35,¯1000,0,0,0,0,0,0⟩ lib.AssertEq result.accounts.credit_movement
⟨965,¯1000,30,5,0,0,0,0⟩ lib.AssertEq result.accounts.closing
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
⟨980,¯1000,20,0,0,0,0,0⟩ lib.AssertEq late.accounts.opening
⟨0,0,10,5,0,0,0,0⟩ lib.AssertEq late.accounts.debit_movement
⟨¯15,0,0,0,0,0,0,0⟩ lib.AssertEq late.accounts.credit_movement
⟨965,¯1000,30,5,0,0,0,0⟩ lib.AssertEq late.accounts.closing
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

scaleAccountLines ← ⟨
  "assets:jpy	role=asset	currency=JPY",
  "expenses:jpy	role=expense	currency=JPY"
⟩
scaleAccounts ← (account_admission.Admit ⟨scaleAccountLines,registry⟩).accounts
scalePlanLines ← ⟨
  "2026-01-10	whole	assets:jpy	expenses:jpy	25	currency=JPY	plan_id=p1",
  "2026-01-11	fraction	assets:jpy	expenses:jpy	12.30	currency=JPY	plan_id=p2"
⟩
scaleFacts ← (companion_snapshot.Build ⟨scalePlanLines,⟨⟩,scaleAccounts,registry⟩).plan
scalePeriod ← period.Build ⟨scaleFacts,"JPY","plan",start,end⟩
"ok" lib.AssertEq scalePeriod.state
1 lib.AssertEq scalePeriod.scale
⟨¯373,373⟩ lib.AssertEq scalePeriod.accounts.closing
373 lib.AssertEq scalePeriod.totals.debit_movement
¯373 lib.AssertEq scalePeriod.totals.credit_movement
1 lib.AssertEq scalePeriod.totals.balanced

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
