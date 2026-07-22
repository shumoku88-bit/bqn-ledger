#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
parser ← •Import "../src_next/journal_profile_stage1.bqn"
adapter ← •Import "../src_next/journal_posting_ir_stage2a.bqn"
carrier_module ← •Import "../src_next/journal_read_only_source_carrier.bqn"
context ← •Import "../src_next/context.bqn"
cube ← •Import "../src_next/cube.bqn"
tbds ← •Import "../src_next/tbds.bqn"
ak ← •Import "../src_next/account_key.bqn"
loader ← •Import "../src_next/loader.bqn"

lf ← @+10
tab ← @+9
base ← "../fixtures/journal-resolved-envelope-assignment-persistence"
cycleStart ← "2026-08-01"

cy ← {
  start ⇐ cycleStart,
  end_exclusive ⇐ "2026-09-01",
  day_count ⇐ 31,
  mode ⇐ "explicit"
}

HasCode ← {𝕊 code‿result: ∨´ 0 ∾ {code ≡ 𝕩.code}¨ result.diagnostics }
Intersect ← { (𝕩 ∊ 𝕨) / 𝕩 }

# 8 required accounts resolved via account_key.Resolve
accountLines ← ⟨
  "assets:bank" ∾ tab ∾ "role=asset",
  "expenses:food:daily" ∾ tab ∾ "role=expense",
  "expenses:food:stock" ∾ tab ∾ "role=expense",
  "expenses:household" ∾ tab ∾ "role=expense",
  "budget:spent:daily" ∾ tab ∾ "role=budget",
  "budget:daily" ∾ tab ∾ "role=budget",
  "budget:spent:flex" ∾ tab ∾ "role=budget",
  "budget:flex" ∾ tab ∾ "role=budget"
⟩
resolved ← ak.Resolve accountLines

8 lib.AssertEq resolved.count
⟨
  "assets:bank/JPY",
  "expenses:food:daily/JPY",
  "expenses:food:stock/JPY",
  "expenses:household/JPY",
  "budget:spent:daily/JPY",
  "budget:daily/JPY",
  "budget:spent:flex/JPY",
  "budget:flex/JPY"
⟩ lib.AssertEq resolved.account_keys

v1Defaults ← •FChars (base ∾ "/defaults-v1.journal")
v2Defaults ← •FChars (base ∾ "/defaults-v2.journal")
persistedEvents ← •FChars (base ∾ "/persisted-events.journal")

Join ← { (0 ⊑ 𝕩) ∾ lf ∾ (1 ⊑ 𝕩) }

v1Raw ← Join ⟨v1Defaults, persistedEvents⟩
v1Lines ← (@+10) loader.SplitKeepEmpty v1Raw
carrierV1 ← {
  source_file ⇐ "persisted-events.journal",
  lines ⇐ v1Lines
}
carrierResultV1 ← carrier_module.Build ⟨carrierV1, resolved, cycleStart⟩

# 1. Transaction IR identity
"ok" lib.AssertEq carrierResultV1.state
0 lib.AssertEq ≠ carrierResultV1.diagnostics
3 lib.AssertEq ≠ carrierResultV1.transactions
⟨"actual", "budget", "actual"⟩ lib.AssertEq {𝕩.layer_name}¨ carrierResultV1.transactions

purchaseV1 ← 0 ⊑ carrierResultV1.transactions
companionV1 ← 1 ⊑ carrierResultV1.transactions
laterPurchaseV1 ← 2 ⊑ carrierResultV1.transactions

"durable" lib.AssertEq purchaseV1.identity_kind
"event-purchase-2026-08-03-001" lib.AssertEq purchaseV1.source_event_id
"event-envelope-consumption-2026-08-03-001" lib.AssertEq companionV1.source_event_id
"event-purchase-2026-08-03-001" lib.AssertEq companionV1.actual_event_id
lib.Assert purchaseV1.source_event_id ≢ companionV1.source_event_id

⟨"expenses:food:daily", "expenses:food:stock", "expenses:household", "assets:bank"⟩ lib.AssertEq {𝕩.account_key}¨ purchaseV1.postings
⟨"budget:spent:daily", "budget:daily", "budget:spent:flex", "budget:flex"⟩ lib.AssertEq {𝕩.account_key}¨ companionV1.postings
⟨"expenses:food:daily", "expenses:food:stock", "expenses:household", "assets:bank"⟩ lib.AssertEq {𝕩.account_key}¨ laterPurchaseV1.postings

0 lib.AssertEq +´ {𝕩.delta}¨ purchaseV1.postings
0 lib.AssertEq +´ {𝕩.delta}¨ companionV1.postings
0 lib.AssertEq +´ {𝕩.delta}¨ laterPurchaseV1.postings

4 lib.AssertEq ≠ purchaseV1.postings
4 lib.AssertEq ≠ companionV1.postings
4 lib.AssertEq ≠ laterPurchaseV1.postings

# 2. Stage 2A Posting IR
postingRowsV1 ← carrierResultV1.posting_rows
12 lib.AssertEq ≠ postingRowsV1
lib.Assert ∧´ {"ok" ≡ 𝕩.status}¨ postingRowsV1
lib.Assert ∧´ {"event-purchase-2026-08-03-001" ≡ 𝕩.source_id}¨ 4 ↑ postingRowsV1
lib.Assert ∧´ {"event-envelope-consumption-2026-08-03-001" ≡ 𝕩.source_id}¨ 4 ↑ (4 ↓ postingRowsV1)
lib.Assert ∧´ {"event-purchase-2026-08-10-001" ≡ 𝕩.source_id}¨ 4 ↑ (8 ↓ postingRowsV1)

# first actual purchase rows: actual / layer_index 0
lib.Assert ∧´ {"actual" ≡ 𝕩.layer_name}¨ 4 ↑ postingRowsV1
lib.Assert ∧´ {cube.layer_actual = 𝕩.layer_index}¨ 4 ↑ postingRowsV1

# budget companion rows: budget / layer_index 2
lib.Assert ∧´ {"budget" ≡ 𝕩.layer_name}¨ 4 ↑ (4 ↓ postingRowsV1)
lib.Assert ∧´ {cube.layer_budget = 𝕩.layer_index}¨ 4 ↑ (4 ↓ postingRowsV1)

# later actual purchase rows: actual / layer_index 0
lib.Assert ∧´ {"actual" ≡ 𝕩.layer_name}¨ 4 ↑ (8 ↓ postingRowsV1)
lib.Assert ∧´ {cube.layer_actual = 𝕩.layer_index}¨ 4 ↑ (8 ↓ postingRowsV1)

# Actual accounts not in budget layer rows; budget accounts not in actual layer rows
lib.Assert ∧´ {"budget:" ≢ 7 ↑ 𝕩.account_key}¨ (4 ↑ postingRowsV1) ∾ (4 ↑ (8 ↓ postingRowsV1))
lib.Assert ∧´ {"budget:" ≡ 7 ↑ 𝕩.account_key}¨ 4 ↑ (4 ↓ postingRowsV1)

# 3. BuildPeriodView and TBDS
viewA ← context.BuildPeriodView ⟨postingRowsV1, resolved, cy⟩
32 lib.AssertEq ≠ viewA.tbds

actualTbdsA ← tbds.RowsForLayer ⟨cube.layer_actual, viewA.tbds⟩
budgetTbdsA ← tbds.RowsForLayer ⟨cube.layer_budget, viewA.tbds⟩

# 4. Actual-layer coordinates
GetMovement ← {𝕊 key‿rows:
  matching ← ({key ≡ 𝕩.account_key}¨ rows) / rows
  1 lib.AssertEq ≠ matching
  (⊑ matching).movement
}

(-5600) lib.AssertEq GetMovement ⟨"assets:bank/JPY", actualTbdsA⟩
2800 lib.AssertEq GetMovement ⟨"expenses:food:daily/JPY", actualTbdsA⟩
1800 lib.AssertEq GetMovement ⟨"expenses:food:stock/JPY", actualTbdsA⟩
1000 lib.AssertEq GetMovement ⟨"expenses:household/JPY", actualTbdsA⟩

0 lib.AssertEq GetMovement ⟨"budget:spent:daily/JPY", actualTbdsA⟩
0 lib.AssertEq GetMovement ⟨"budget:daily/JPY", actualTbdsA⟩
0 lib.AssertEq GetMovement ⟨"budget:spent:flex/JPY", actualTbdsA⟩
0 lib.AssertEq GetMovement ⟨"budget:flex/JPY", actualTbdsA⟩

0 lib.AssertEq +´ {𝕩.movement}¨ actualTbdsA

# 5. Budget-layer coordinates
2300 lib.AssertEq GetMovement ⟨"budget:spent:daily/JPY", budgetTbdsA⟩
(-2300) lib.AssertEq GetMovement ⟨"budget:daily/JPY", budgetTbdsA⟩
500 lib.AssertEq GetMovement ⟨"budget:spent:flex/JPY", budgetTbdsA⟩
(-500) lib.AssertEq GetMovement ⟨"budget:flex/JPY", budgetTbdsA⟩

0 lib.AssertEq GetMovement ⟨"assets:bank/JPY", budgetTbdsA⟩
0 lib.AssertEq GetMovement ⟨"expenses:food:daily/JPY", budgetTbdsA⟩
0 lib.AssertEq GetMovement ⟨"expenses:food:stock/JPY", budgetTbdsA⟩
0 lib.AssertEq GetMovement ⟨"expenses:household/JPY", budgetTbdsA⟩

0 lib.AssertEq +´ {𝕩.movement}¨ budgetTbdsA

# 6. Actual projection invariance
actualRowsOnly ← (cube.layer_actual = {𝕩.layer_index}¨ postingRowsV1) / postingRowsV1
8 lib.AssertEq ≠ actualRowsOnly
viewB ← context.BuildPeriodView ⟨actualRowsOnly, resolved, cy⟩
actualTbdsB ← tbds.RowsForLayer ⟨cube.layer_actual, viewB.tbds⟩

# Compare actual-layer TBDS row evidence field by field (row order, account_key, layer_name, opening, debit/credit/net movement, closing)
8 lib.AssertEq ≠ actualTbdsA
8 lib.AssertEq ≠ actualTbdsB
({𝕩.account_key}¨ actualTbdsA) lib.AssertEq ({𝕩.account_key}¨ actualTbdsB)
({𝕩.layer_name}¨ actualTbdsA) lib.AssertEq ({𝕩.layer_name}¨ actualTbdsB)
({𝕩.opening}¨ actualTbdsA) lib.AssertEq ({𝕩.opening}¨ actualTbdsB)
({𝕩.debit_movement}¨ actualTbdsA) lib.AssertEq ({𝕩.debit_movement}¨ actualTbdsB)
({𝕩.credit_movement}¨ actualTbdsA) lib.AssertEq ({𝕩.credit_movement}¨ actualTbdsB)
({𝕩.movement}¨ actualTbdsA) lib.AssertEq ({𝕩.movement}¨ actualTbdsB)
({𝕩.closing}¨ actualTbdsA) lib.AssertEq ({𝕩.closing}¨ actualTbdsB)

# 7. Historical stability under Defaults V2
v2Raw ← Join ⟨v2Defaults, persistedEvents⟩
v2Lines ← (@+10) loader.SplitKeepEmpty v2Raw
carrierV2 ← {
  source_file ⇐ "persisted-events.journal",
  lines ⇐ v2Lines
}
carrierResultV2 ← carrier_module.Build ⟨carrierV2, resolved, cycleStart⟩

"ok" lib.AssertEq carrierResultV2.state
0 lib.AssertEq ≠ carrierResultV2.diagnostics
12 lib.AssertEq ≠ carrierResultV2.posting_rows

# Persisted budget companion rows under V2 match V1 field by field
companionRowsV1 ← 4 ↑ (4 ↓ postingRowsV1)
companionRowsV2 ← 4 ↑ (4 ↓ carrierResultV2.posting_rows)
({𝕩.account_key}¨ companionRowsV1) lib.AssertEq ({𝕩.account_key}¨ companionRowsV2)
({𝕩.delta}¨ companionRowsV1) lib.AssertEq ({𝕩.delta}¨ companionRowsV2)
({𝕩.layer_name}¨ companionRowsV1) lib.AssertEq ({𝕩.layer_name}¨ companionRowsV2)
({𝕩.layer_index}¨ companionRowsV1) lib.AssertEq ({𝕩.layer_index}¨ companionRowsV2)
({𝕩.source_id}¨ companionRowsV1) lib.AssertEq ({𝕩.source_id}¨ companionRowsV2)

viewV2 ← context.BuildPeriodView ⟨carrierResultV2.posting_rows, resolved, cy⟩
budgetTbdsV2 ← tbds.RowsForLayer ⟨cube.layer_budget, viewV2.tbds⟩

({𝕩.account_key}¨ budgetTbdsA) lib.AssertEq ({𝕩.account_key}¨ budgetTbdsV2)
({𝕩.layer_name}¨ budgetTbdsA) lib.AssertEq ({𝕩.layer_name}¨ budgetTbdsV2)
({𝕩.opening}¨ budgetTbdsA) lib.AssertEq ({𝕩.opening}¨ budgetTbdsV2)
({𝕩.debit_movement}¨ budgetTbdsA) lib.AssertEq ({𝕩.debit_movement}¨ budgetTbdsV2)
({𝕩.credit_movement}¨ budgetTbdsA) lib.AssertEq ({𝕩.credit_movement}¨ budgetTbdsV2)
({𝕩.movement}¨ budgetTbdsA) lib.AssertEq ({𝕩.movement}¨ budgetTbdsV2)
({𝕩.closing}¨ budgetTbdsA) lib.AssertEq ({𝕩.closing}¨ budgetTbdsV2)

2300 lib.AssertEq GetMovement ⟨"budget:spent:daily/JPY", budgetTbdsV2⟩
(-2300) lib.AssertEq GetMovement ⟨"budget:daily/JPY", budgetTbdsV2⟩
500 lib.AssertEq GetMovement ⟨"budget:spent:flex/JPY", budgetTbdsV2⟩
(-500) lib.AssertEq GetMovement ⟨"budget:flex/JPY", budgetTbdsV2⟩

# Observe candidate proposal vs persisted fact authority under V2 defaults
parsedV2 ← parser.Parse v2Raw
"ok" lib.AssertEq parsedV2.state
purchaseV2 ← 0 ⊑ parsedV2.transactions
resolvedV2Defaults ← parser.ResolveEnvelopeDefaults ⟨purchaseV2, parsedV2.accounts⟩
"ok" lib.AssertEq resolvedV2Defaults.state
0 lib.AssertEq +´ { ("daily" ≡ 𝕩.envelope) ⊑ 0‿𝕩.amount }¨ resolvedV2Defaults.assignments
2800 lib.AssertEq +´ { ("flex" ≡ 𝕩.envelope) ⊑ 0‿𝕩.amount }¨ resolvedV2Defaults.assignments

# Fail-closed evidence

ActualBlock ← {𝕊:
  ∾ ⟨
    "2026-08-03 * Example Market | purchase", lf,
    "    ; event-id: event-purchase-1", lf,
    "    expenses:food:daily 10 JPY", lf,
    "    assets:bank -10 JPY", lf
  ⟩
}

BudgetBlock ← {𝕊 eventId‿linkId‿creditAmount:
  lines ← ⟨
    "2026-08-03 * Household budget | consume",
    "    ; event-id: " ∾ eventId,
    "    ; layer: budget"
  ⟩
  lines ↩ {lines ∾ ⟨"    ; actual-event-id: " ∾ linkId⟩}⍟(0 < ≠ linkId) lines
  lines ∾↩ ⟨
    "    budget:spent:daily 10 JPY",
    "    budget:daily -" ∾ creditAmount ∾ " JPY"
  ⟩
  ∾ (lines ∾¨ lf)
}

BuildCarrierInput ← {𝕊 journalText:
  lines ← (@+10) loader.SplitKeepEmpty Join ⟨v1Defaults, journalText⟩
  { source_file ⇐ "test-fail-closed.journal", lines ⇐ lines }
}

# 1. Missing link
missingLinkText ← (BudgetBlock ⟨"event-budget-missing", "", "10"⟩)
missingLinkParser ← parser.Parse Join ⟨v1Defaults, missingLinkText⟩
"error" lib.AssertEq missingLinkParser.state
lib.Assert HasCode ⟨"budget_link_missing", missingLinkParser⟩

missingLinkCarrier ← carrier_module.Build ⟨BuildCarrierInput missingLinkText, resolved, cycleStart⟩
"error" lib.AssertEq missingLinkCarrier.state
0 lib.AssertEq ≠ missingLinkCarrier.posting_rows

# 2. Invalid or mismatched link
invalidLinkText ← (BudgetBlock ⟨"event-budget-unknown", "event-does-not-exist", "10"⟩)
invalidLinkParser ← parser.Parse Join ⟨v1Defaults, invalidLinkText⟩
"error" lib.AssertEq invalidLinkParser.state
lib.Assert HasCode ⟨"actual_event_target_invalid", invalidLinkParser⟩

invalidLinkCarrier ← carrier_module.Build ⟨BuildCarrierInput invalidLinkText, resolved, cycleStart⟩
"error" lib.AssertEq invalidLinkCarrier.state
0 lib.AssertEq ≠ invalidLinkCarrier.posting_rows

# 3. Unbalanced companion
unbalancedText ← (ActualBlock @) ∾ lf ∾ (BudgetBlock ⟨"event-budget-unbalanced", "event-purchase-1", "9"⟩)
unbalancedParser ← parser.Parse Join ⟨v1Defaults, unbalancedText⟩
"error" lib.AssertEq unbalancedParser.state
lib.Assert HasCode ⟨"event_unbalanced", unbalancedParser⟩

unbalancedCarrier ← carrier_module.Build ⟨BuildCarrierInput unbalancedText, resolved, cycleStart⟩
"error" lib.AssertEq unbalancedCarrier.state
0 lib.AssertEq ≠ unbalancedCarrier.posting_rows

# 4. Unknown budget account
# Declared in journal header, but absent from resolved account registry -> fails at Stage 2A
unknownAccountText ← (ActualBlock @) ∾ lf ∾ (∾ (⟨
  "2026-08-03 * Household budget | consume",
  "    ; event-id: event-budget-unknown-acc",
  "    ; layer: budget",
  "    ; actual-event-id: event-purchase-1",
  "    budget:spent:unknown 10 JPY",
  "    budget:unknown -10 JPY"
⟩ ∾¨ lf))
unknownAccountCarrier ← carrier_module.Build ⟨BuildCarrierInput unknownAccountText, resolved, cycleStart⟩
"error" lib.AssertEq unknownAccountCarrier.state
0 lib.AssertEq ≠ unknownAccountCarrier.posting_rows
lib.Assert HasCode ⟨"posting_account_unknown", unknownAccountCarrier⟩

# 5. Unsupported layer
unsupportedLayerText ← (ActualBlock @) ∾ lf ∾ (∾ (⟨
  "2026-08-03 * Household budget | consume",
  "    ; event-id: event-budget-unsupported-layer",
  "    ; layer: unknown_layer",
  "    ; actual-event-id: event-purchase-1",
  "    budget:spent:daily 10 JPY",
  "    budget:daily -10 JPY"
⟩ ∾¨ lf))
unsupportedLayerParser ← parser.Parse Join ⟨v1Defaults, unsupportedLayerText⟩
"error" lib.AssertEq unsupportedLayerParser.state
lib.Assert HasCode ⟨"layer_unsupported", unsupportedLayerParser⟩

unsupportedLayerCarrier ← carrier_module.Build ⟨BuildCarrierInput unsupportedLayerText, resolved, cycleStart⟩
"error" lib.AssertEq unsupportedLayerCarrier.state
0 lib.AssertEq ≠ unsupportedLayerCarrier.posting_rows

# 6. Layer separation explicit checks
lib.Assert ∧´ {cube.layer_actual = 𝕩.layer_index}¨ actualRowsOnly
budgetRowsOnly ← (cube.layer_budget = {𝕩.layer_index}¨ postingRowsV1) / postingRowsV1
lib.Assert ∧´ {cube.layer_budget = 𝕩.layer_index}¨ budgetRowsOnly

actualActiveKeys ← {𝕩.account_key}¨ ((({𝕩.movement}¨ actualTbdsA) ≠ 0) / actualTbdsA)
budgetActiveKeys ← {𝕩.account_key}¨ ((({𝕩.movement}¨ budgetTbdsA) ≠ 0) / budgetTbdsA)

lib.Assert 0 = ≠ (actualActiveKeys Intersect budgetActiveKeys)

•Out "test_journal_budget_companion_projection_characterization.bqn: OK"
