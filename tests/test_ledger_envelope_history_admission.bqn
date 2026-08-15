#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
admission ← •Import "../src/ledger/envelope_history_admission.bqn"
lf ← @+10 ⋄ quote ← @+34

historyRaw ← •FChars "../fixtures/canonical-household-envelope-history/household.toml"
history ← admission.Admit historyRaw
"ok" lib.AssertEq history.state
1 lib.AssertEq history.present
0 lib.AssertEq ≠history.diagnostics
⟨"Daily"⟩ lib.AssertEq history.registry.id
1 lib.AssertEq history.expense_routing.count
⟨"initial"⟩ lib.AssertEq history.expense_routing.effective_from
⟨1⟩ lib.AssertEq history.expense_routing.initial
⟨¯1⟩ lib.AssertEq history.expense_routing.effective_ordinal
⟨"Expenses:Groceries"⟩ lib.AssertEq history.expense_routing.expense_account_key
⟨"managed"⟩ lib.AssertEq history.expense_routing.route
⟨"Daily"⟩ lib.AssertEq history.expense_routing.target_id
0 lib.AssertEq history.fulfillment_routing.count

# Expansion remains compatible with canonical fixtures that predate the shared
# history section. Absence is explicit and publishes no invented routing.
absentRaw ← •FChars "../fixtures/canonical-household-v1/household.toml"
absent ← admission.Admit absentRaw
"ok" lib.AssertEq absent.state
0 lib.AssertEq absent.present
0 lib.AssertEq absent.registry.count
0 lib.AssertEq absent.expense_routing.count
0 lib.AssertEq absent.fulfillment_routing.count

# Fulfillment routing is admitted source-locally by stable PlanId text. PlanId
# existence is deliberately left for later cross-source Household qualification.
fulfillmentSuffix ← ⟨lf⟩∾"[[envelope-history.fulfillment-routing]]"∾⟨lf⟩∾
  "effective-from = "∾⟨quote⟩∾"2026-08-15"∾⟨quote,lf⟩∾
  "plan-id = "∾⟨quote⟩∾"plan-synthetic"∾⟨quote,lf⟩∾
  "route = "∾⟨quote⟩∾"fulfills"∾⟨quote,lf⟩∾
  "target = "∾⟨quote⟩∾"Daily"∾⟨quote,lf⟩∾
  "note = "∾⟨quote⟩∾"synthetic fulfillment"∾⟨quote,lf⟩
withFulfillment ← admission.Admit (historyRaw∾fulfillmentSuffix)
"ok" lib.AssertEq withFulfillment.state
1 lib.AssertEq withFulfillment.fulfillment_routing.count
⟨"plan-synthetic"⟩ lib.AssertEq withFulfillment.fulfillment_routing.plan_id
⟨"fulfills"⟩ lib.AssertEq withFulfillment.fulfillment_routing.route
⟨"Daily"⟩ lib.AssertEq withFulfillment.fulfillment_routing.target_id
⟨dates.Ordinal "2026-08-15"⟩ lib.AssertEq withFulfillment.fulfillment_routing.effective_ordinal

# Historical targets are stable identities, not current labels or inferred
# categories. Unknown target identity fails closed.
unknownTargetSuffix ← ⟨lf⟩∾"[[envelope-history.expense-routing]]"∾⟨lf⟩∾
  "effective-from = "∾⟨quote⟩∾"2026-08-15"∾⟨quote,lf⟩∾
  "expense-account = "∾⟨quote⟩∾"Expenses:Other"∾⟨quote,lf⟩∾
  "route = "∾⟨quote⟩∾"managed"∾⟨quote,lf⟩∾
  "target = "∾⟨quote⟩∾"RetiredUnknown"∾⟨quote,lf⟩∾
  "note = "∾⟨quote⟩∾"invalid target"∾⟨quote,lf⟩
unknownTarget ← admission.Admit (historyRaw∾unknownTargetSuffix)
"error" lib.AssertEq unknownTarget.state
0 lib.AssertEq unknownTarget.registry.count
0 lib.AssertEq unknownTarget.expense_routing.count

•Out "test_ledger_envelope_history_admission: ok"
