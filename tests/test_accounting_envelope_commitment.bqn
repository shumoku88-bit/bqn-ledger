#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
registryCore ← •Import "../src/ledger/currency_registry.bqn"
snapshot ← •Import "legacy_snapshot_fixture.bqn"
canonicalPlan ← •Import "canonical_plan_test_facts.bqn"
historyFixture ← •Import "envelope_history_test_fixture.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
commitment ← •Import "../src/accounting/envelope_commitment.bqn"

lf ← @+10 ⋄ tab ← @+9
Raw ← {𝕊 lines:∾{𝕩∾⟨lf⟩}¨lines}
Join ← {𝕊 fields:out←⊑fields ⋄ {𝕊 field:out∾↩tab∾field}¨1↓fields ⋄ out}
registry ← (registryCore.Build ⟨Join ⟨"JPY","0","¥"⟩⟩).registry
accountLines ← ⟨
  Join ⟨"assets:cash","role=asset","currency=JPY"⟩,
  Join ⟨"assets:savings","role=asset","currency=JPY"⟩,
  Join ⟨"expenses:food","role=expense","currency=JPY"⟩,
  Join ⟨"expenses:transport","role=expense","currency=JPY"⟩,
  Join ⟨"expenses:other","role=expense","currency=JPY"⟩
⟩
actualRaw ← Raw ⟨
  "commodity JPY","",
  "account assets:cash","    ; role: asset","",
  "account assets:savings","    ; role: asset","",
  "account expenses:food","    ; role: expense","",
  "account expenses:transport","    ; role: expense","",
  "account expenses:other","    ; role: expense","",
  "2026-01-10 * completed food",
  "    ; event-id: completed-food-actual",
  "    ; layer: actual",
  "    ; plan-id: completed-food",
  "    expenses:food 4 JPY",
  "    assets:cash -4 JPY"
⟩
actual ← (snapshot.Build ⟨accountLines,actualRaw,registry⟩).facts
planRaw ← Raw ⟨
  "2026-01-09 completed food",
  "  ; plan-id: completed-food",
  "  expenses:food 4 JPY",
  "  assets:cash -4 JPY","",
  "2026-01-20 open food",
  "  ; plan-id: open-food",
  "  expenses:food 5 JPY",
  "  assets:cash -5 JPY","",
  "2026-01-20 open savings",
  "  ; plan-id: open-save",
  "  assets:savings 7 JPY",
  "  assets:cash -7 JPY","",
  "2026-01-20 explicit unmanaged",
  "  ; plan-id: open-transport",
  "  expenses:transport 3 JPY",
  "  assets:cash -3 JPY","",
  "2026-01-20 missing route",
  "  ; plan-id: open-other",
  "  expenses:other 2 JPY",
  "  assets:cash -2 JPY"
⟩
plan ← (canonicalPlan.Build ⟨planRaw,actual.accounts,registry⟩).facts
baseHistory ← historyFixture.Initial ⟨⟨"food","goal"⟩,⟨⟩,⟨⟩,⟨⟩⟩
expenseHistory ← historyFixture.WithExpense ⟨
  baseHistory,
  ⟨"initial","2026-01-12","initial"⟩,
  ⟨"expenses:food","expenses:food","expenses:transport"⟩,
  ⟨"managed","unmanaged","unmanaged"⟩,
  ⟨"food","",""⟩
⟩
history ← historyFixture.WithFulfillment ⟨
  expenseHistory,
  ⟨"2026-01-01","2026-01-12"⟩,
  ⟨"open-save","open-save"⟩,
  ⟨"fulfills","not-target"⟩,
  ⟨"goal",""⟩
⟩
start ← dates.Ordinal "2026-01-01"
finish ← dates.Ordinal "2026-02-01"
jan11 ← dates.Ordinal "2026-01-11"
jan15 ← dates.Ordinal "2026-01-15"

beforeChange ← commitment.Build ⟨plan,actual,history,"JPY",start,finish,jan11⟩
"ok" lib.AssertEq beforeChange.state
⟨"food","goal"⟩ lib.AssertEq beforeChange.managed.envelope_id
⟨5,7⟩ lib.AssertEq beforeChange.managed.commitment
1 lib.AssertEq beforeChange.unmanaged.count
⟨"open-transport"⟩ lib.AssertEq beforeChange.unmanaged.plan_id
⟨3⟩ lib.AssertEq beforeChange.unmanaged.coefficient
1 lib.AssertEq beforeChange.unrouted.count
⟨"open-other"⟩ lib.AssertEq beforeChange.unrouted.plan_id
⟨2⟩ lib.AssertEq beforeChange.unrouted.coefficient
4 lib.AssertEq beforeChange.evidence.count
⟨"open-food","open-save","open-transport","open-other"⟩ lib.AssertEq beforeChange.evidence.plan_id
⟨"managed","fulfills","unmanaged","unrouted"⟩ lib.AssertEq beforeChange.evidence.route
"plan.journal" lib.AssertEq (⊑⊑beforeChange.managed.plan_contributors).source

# Open intent is evaluated at the observation day. After Jan 12 the same open
# Expense Plan is explicitly unmanaged and the same savings Plan is not-target.
afterChange ← commitment.Build ⟨plan,actual,history,"JPY",start,finish,jan15⟩
"ok" lib.AssertEq afterChange.state
⟨0,0⟩ lib.AssertEq afterChange.managed.commitment
2 lib.AssertEq afterChange.unmanaged.count
⟨"open-food","open-transport"⟩ lib.AssertEq afterChange.unmanaged.plan_id
⟨5,3⟩ lib.AssertEq afterChange.unmanaged.coefficient
1 lib.AssertEq afterChange.unrouted.count
⟨"open-other"⟩ lib.AssertEq afterChange.unrouted.plan_id
⟨"unmanaged","not-target","unmanaged","unrouted"⟩ lib.AssertEq afterChange.evidence.route

# The Plan linked to Actual completion is absent from both commitment snapshots.
0 lib.AssertEq +´"completed-food"⊸≡¨beforeChange.evidence.plan_id
0 lib.AssertEq +´"completed-food"⊸≡¨afterChange.evidence.plan_id

•Out "test_accounting_envelope_commitment: ok"
