#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
admission ← •Import "../src/ledger/envelope_history_admission.bqn"
lf ← @+10 ⋄ quote ← @+34
Lines ← {𝕊 xs:∾{𝕩∾⟨lf⟩}¨xs}
Quoted ← {𝕊 text:⟨quote⟩∾text∾⟨quote⟩}

# The canonical fixture itself carries explicit clean-epoch history. Historical
# admission no longer depends on a parallel migration-era Household fixture.
historyRaw ← •FChars "../fixtures/canonical-household-v1/household.toml"
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

# A source with no Envelope history publishes explicit absence and invents no
# registry or routing evidence.
absent ← admission.Admit ""
"ok" lib.AssertEq absent.state
0 lib.AssertEq absent.present
0 lib.AssertEq absent.registry.count
0 lib.AssertEq absent.expense_routing.count
0 lib.AssertEq absent.fulfillment_routing.count

# Routing evidence cannot exist without the stable identity root.
routeOnly ← Lines ⟨"[[envelope-history.expense-routing]]","effective-from = "∾(Quoted "initial"),"expense-account = "∾(Quoted "Expenses:Groceries"),"route = "∾(Quoted "managed"),"target = "∾(Quoted "Daily"),"note = "∾(Quoted "missing root")⟩
missingRoot ← admission.Admit routeOnly
"error" lib.AssertEq missingRoot.state
0 lib.AssertEq missingRoot.registry.count
0 lib.AssertEq missingRoot.expense_routing.count

# Fulfillment routing is admitted source-locally by stable PlanId text. PlanId
# existence is deliberately left for later cross-source Household qualification.
fulfillmentSuffix ← Lines ⟨"[[envelope-history.fulfillment-routing]]","effective-from = "∾(Quoted "2026-08-15"),"plan-id = "∾(Quoted "plan-synthetic"),"route = "∾(Quoted "fulfills"),"target = "∾(Quoted "Daily"),"note = "∾(Quoted "synthetic fulfillment")⟩
withFulfillment ← admission.Admit (historyRaw∾⟨lf⟩∾fulfillmentSuffix)
"ok" lib.AssertEq withFulfillment.state
1 lib.AssertEq withFulfillment.fulfillment_routing.count
⟨"plan-synthetic"⟩ lib.AssertEq withFulfillment.fulfillment_routing.plan_id
⟨"fulfills"⟩ lib.AssertEq withFulfillment.fulfillment_routing.route
⟨"Daily"⟩ lib.AssertEq withFulfillment.fulfillment_routing.target_id
⟨dates.Ordinal "2026-08-15"⟩ lib.AssertEq withFulfillment.fulfillment_routing.effective_ordinal

# Historical targets are stable identities, not current labels or inferred
# categories. Unknown target identity fails closed.
unknownTargetSuffix ← Lines ⟨"[[envelope-history.expense-routing]]","effective-from = "∾(Quoted "2026-08-15"),"expense-account = "∾(Quoted "Expenses:Other"),"route = "∾(Quoted "managed"),"target = "∾(Quoted "RetiredUnknown"),"note = "∾(Quoted "invalid target")⟩
unknownTarget ← admission.Admit (historyRaw∾⟨lf⟩∾unknownTargetSuffix)
"error" lib.AssertEq unknownTarget.state
0 lib.AssertEq unknownTarget.registry.count
0 lib.AssertEq unknownTarget.expense_routing.count

# Explicit unmanaged routing is a complete negative decision and therefore must
# not carry an Envelope target.
unmanagedTargetSuffix ← Lines ⟨"[[envelope-history.expense-routing]]","effective-from = "∾(Quoted "2026-08-16"),"expense-account = "∾(Quoted "Expenses:Other"),"route = "∾(Quoted "unmanaged"),"target = "∾(Quoted "Daily"),"note = "∾(Quoted "invalid unmanaged target")⟩
unmanagedTarget ← admission.Admit (historyRaw∾⟨lf⟩∾unmanagedTargetSuffix)
"error" lib.AssertEq unmanagedTarget.state
0 lib.AssertEq unmanagedTarget.registry.count
0 lib.AssertEq unmanagedTarget.expense_routing.count

•Out "test_ledger_envelope_history_admission: ok"
