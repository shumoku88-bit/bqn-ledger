#!/usr/bin/env bqn

# test_journal_minimal_actual_surface_characterization.bqn
# Characterization test for minimal actual Journal surface vs metadata-bearing actual surface.
#
# Finite Question:
#   Does an actual transaction with `event-id`, `layer: actual`, `currency: JPY` metadata
#   and a minimal actual transaction without them pass the parser and Stage 2A to produce
#   identical accounting semantics, Cube numeric materialization, and TBDS dataset,
#   differing only in identity kind, source event ID, physical lines, and generic metadata?
#
# Interpretation / Boundary:
#   Same (会計上同じ):
#     - accounting semantics (date, status_marker, description, layer_name)
#     - posting order and deltas (account_key, delta, commodity, amount_text, side, posting_index)
#     - actual layer classification
#     - Cube materialized array, totals, valid/skipped counts
#     - TBDS period view, opening, debit/credit movements, closing balances
#   Intentionally different (意図的に違う):
#     - durable vs physical fallback identity (identity_kind)
#     - source_event_id ("entry-example" vs "stage0-line-...")
#     - posting_id ("entry-example:0" vs "stage0-line-...:0")
#     - generic transaction metadata carrier
#     - physical source lines (source_start_line, source_end_line)

lib ← •Import "test_lib.bqn"
parser ← •Import "../src_next/journal_profile_stage1.bqn"
adapter ← •Import "../src_next/journal_posting_ir_stage2a.bqn"
ak ← •Import "../src_next/account_key.bqn"
loader ← •Import "../src_next/loader.bqn"
cube ← •Import "../src_next/cube.bqn"
tbds ← •Import "../src_next/tbds.bqn"

base ← "fixtures/journal-minimal-actual-surface"
cycleStart ← "2026-07-01"
dayCount ← 31

# 1. Accounts setup
accountLines ← loader.ReadLines (base ∾ "/accounts.tsv")
resolved ← ak.Resolve accountLines
2 lib.AssertEq resolved.count
⟨"assets:bank", "expenses:food"⟩ lib.AssertEq resolved.accounts
⟨"assets:bank/JPY", "expenses:food/JPY"⟩ lib.AssertEq resolved.account_keys

# 2. Parse both fixtures
verboseRaw ← •FChars ("../" ∾ base ∾ "/verbose.journal")
minimalRaw ← •FChars ("../" ∾ base ∾ "/minimal.journal")

verboseParsed ← parser.Parse verboseRaw
minimalParsed ← parser.Parse minimalRaw

# 9.1 Parse success
"ok" lib.AssertEq verboseParsed.state
"ok" lib.AssertEq minimalParsed.state
0 lib.AssertEq ≠ verboseParsed.diagnostics
0 lib.AssertEq ≠ minimalParsed.diagnostics
1 lib.AssertEq ≠ verboseParsed.transactions
1 lib.AssertEq ≠ minimalParsed.transactions

verboseTx ← ⊑ verboseParsed.transactions
minimalTx ← ⊑ minimalParsed.transactions

2 lib.AssertEq ≠ verboseTx.postings
2 lib.AssertEq ≠ minimalTx.postings

0 lib.AssertEq +´ {𝕩.delta}¨ verboseTx.postings
0 lib.AssertEq +´ {𝕩.delta}¨ minimalTx.postings

# 9.2 Expected identity difference
"durable" lib.AssertEq verboseTx.identity_kind
"entry-example" lib.AssertEq verboseTx.source_event_id
⟨"event-id", "layer", "currency"⟩ lib.AssertEq {𝕩.key}¨ verboseTx.metadata

"physical_fallback" lib.AssertEq minimalTx.identity_kind
0 lib.AssertEq ≠ minimalTx.metadata
lib.Assert 0 < ≠ minimalTx.source_event_id

# 9.3 Transaction semantic equality
verboseTx.date lib.AssertEq minimalTx.date
"2026-07-23" lib.AssertEq verboseTx.date

verboseTx.status_marker lib.AssertEq minimalTx.status_marker
'*' lib.AssertEq verboseTx.status_marker

verboseTx.description lib.AssertEq minimalTx.description
"Example purchase" lib.AssertEq verboseTx.description

verboseTx.layer_name lib.AssertEq minimalTx.layer_name
"actual" lib.AssertEq verboseTx.layer_name

verboseTx.txn_id lib.AssertEq minimalTx.txn_id
"" lib.AssertEq verboseTx.txn_id

verboseTx.plan_id lib.AssertEq minimalTx.plan_id
"" lib.AssertEq verboseTx.plan_id

verboseTx.allocation_id lib.AssertEq minimalTx.allocation_id
"" lib.AssertEq verboseTx.allocation_id

verboseTx.execution_envelope lib.AssertEq minimalTx.execution_envelope
"" lib.AssertEq verboseTx.execution_envelope

verboseTx.actual_event_id lib.AssertEq minimalTx.actual_event_id
"" lib.AssertEq verboseTx.actual_event_id

# 9.4 Ordered posting equality
vAccounts ← {𝕩.account_key}¨ verboseTx.postings
mAccounts ← {𝕩.account_key}¨ minimalTx.postings
vDeltas ← {𝕩.delta}¨ verboseTx.postings
mDeltas ← {𝕩.delta}¨ minimalTx.postings
vCommodities ← {𝕩.commodity}¨ verboseTx.postings
mCommodities ← {𝕩.commodity}¨ minimalTx.postings
vAmountTexts ← {𝕩.amount_text}¨ verboseTx.postings
mAmountTexts ← {𝕩.amount_text}¨ minimalTx.postings
vSides ← {𝕩.side}¨ verboseTx.postings
mSides ← {𝕩.side}¨ minimalTx.postings
vPostingIndexes ← {𝕩.posting_index}¨ verboseTx.postings
mPostingIndexes ← {𝕩.posting_index}¨ minimalTx.postings

vAccounts lib.AssertEq mAccounts
vDeltas lib.AssertEq mDeltas
vCommodities lib.AssertEq mCommodities
vAmountTexts lib.AssertEq mAmountTexts
vSides lib.AssertEq mSides
vPostingIndexes lib.AssertEq mPostingIndexes

⟨"expenses:food", "assets:bank"⟩ lib.AssertEq vAccounts
⟨1200, ¯1200⟩ lib.AssertEq vDeltas
⟨"JPY", "JPY"⟩ lib.AssertEq vCommodities
⟨"debit", "credit"⟩ lib.AssertEq vSides
⟨0, 1⟩ lib.AssertEq vPostingIndexes

# 9.5 Stage 2A success
verboseStage2a ← adapter.Build ⟨verboseParsed.transactions, resolved, cycleStart⟩
minimalStage2a ← adapter.Build ⟨minimalParsed.transactions, resolved, cycleStart⟩

"ok" lib.AssertEq verboseStage2a.state
"ok" lib.AssertEq minimalStage2a.state
0 lib.AssertEq ≠ verboseStage2a.diagnostics
0 lib.AssertEq ≠ minimalStage2a.diagnostics
2 lib.AssertEq ≠ verboseStage2a.posting_rows
2 lib.AssertEq ≠ minimalStage2a.posting_rows
lib.Assert ∧´ {𝕩.status ≡ "ok"}¨ verboseStage2a.posting_rows
lib.Assert ∧´ {𝕩.status ≡ "ok"}¨ minimalStage2a.posting_rows

# 9.6 Stage 2A semantic equality
MakeStage2aCarrier ← {𝕊 rows:
  ⟨
    {𝕩.date}¨ rows,
    {𝕩.day_index}¨ rows,
    {𝕩.account_key}¨ rows,
    {𝕩.account_key_index}¨ rows,
    {𝕩.layer_name}¨ rows,
    {𝕩.layer_index}¨ rows,
    {𝕩.side}¨ rows,
    {𝕩.delta}¨ rows,
    {𝕩.kind}¨ rows,
    {𝕩.status}¨ rows,
    {𝕩.message}¨ rows
  ⟩
}

verboseStage2aCarrier ← MakeStage2aCarrier verboseStage2a.posting_rows
minimalStage2aCarrier ← MakeStage2aCarrier minimalStage2a.posting_rows

verboseStage2aCarrier lib.AssertEq minimalStage2aCarrier

⟨"expense", "expense"⟩ lib.AssertEq 8 ⊑ verboseStage2aCarrier
⟨"expense", "expense"⟩ lib.AssertEq 8 ⊑ minimalStage2aCarrier

# 9.7 Cube equality
verboseCube ← cube.Materialize ⟨verboseStage2a.posting_rows, dayCount, resolved.count⟩
minimalCube ← cube.Materialize ⟨minimalStage2a.posting_rows, dayCount, resolved.count⟩

(≢ verboseCube.cube) lib.AssertEq (≢ minimalCube.cube)
verboseCube.cube lib.AssertEq minimalCube.cube
verboseCube.actual_account_totals lib.AssertEq minimalCube.actual_account_totals
verboseCube.ak_totals lib.AssertEq minimalCube.ak_totals
verboseCube.layer_totals_vec lib.AssertEq minimalCube.layer_totals_vec
verboseCube.actual_expense_total lib.AssertEq minimalCube.actual_expense_total
verboseCube.valid_count lib.AssertEq minimalCube.valid_count
verboseCube.skipped_count lib.AssertEq minimalCube.skipped_count
(≠ verboseCube.skipped_rows) lib.AssertEq (≠ minimalCube.skipped_rows)

1200 lib.AssertEq verboseCube.actual_expense_total
1200 lib.AssertEq minimalCube.actual_expense_total

# 9.8 TBDS equality
cy ← {start⇐"2026-07-01", end_exclusive⇐"2026-08-01"}

verboseTbds ← tbds.Build ⟨verboseStage2a.posting_rows, verboseCube, resolved, cy⟩
minimalTbds ← tbds.Build ⟨minimalStage2a.posting_rows, minimalCube, resolved, cy⟩

(≠ verboseTbds) lib.AssertEq (≠ minimalTbds)

MakeTbdsCarrier ← {𝕊 rows:
  ⟨
    {𝕩.period_id}¨ rows,
    {𝕩.period_start}¨ rows,
    {𝕩.period_end_exclusive}¨ rows,
    {𝕩.as_of}¨ rows,
    {𝕩.account_key}¨ rows,
    {𝕩.account_key_index}¨ rows,
    {𝕩.account_name}¨ rows,
    {𝕩.currency}¨ rows,
    {𝕩.type}¨ rows,
    {𝕩.role}¨ rows,
    {𝕩.layer_name}¨ rows,
    {𝕩.layer_index}¨ rows,
    {𝕩.opening}¨ rows,
    {𝕩.debit_movement}¨ rows,
    {𝕩.credit_movement}¨ rows,
    {𝕩.movement}¨ rows,
    {𝕩.closing}¨ rows,
    {𝕩.status}¨ rows,
    {𝕩.message}¨ rows
  ⟩
}

(MakeTbdsCarrier verboseTbds) lib.AssertEq MakeTbdsCarrier minimalTbds

actualTbds ← tbds.RowsForLayer ⟨cube.layer_actual, verboseTbds⟩
actualAkKeys ← {𝕩.account_key}¨ actualTbds

foodMask ← ("expenses:food/JPY")⊸≡¨ actualAkKeys
bankMask ← ("assets:bank/JPY")⊸≡¨ actualAkKeys

foodRow ← ⊑ foodMask / actualTbds
bankRow ← ⊑ bankMask / actualTbds

1200 lib.AssertEq foodRow.movement
¯1200 lib.AssertEq bankRow.movement

0 lib.AssertEq foodRow.opening
0 lib.AssertEq bankRow.opening

foodRow.movement lib.AssertEq foodRow.closing
bankRow.movement lib.AssertEq bankRow.closing

•Out "test_journal_minimal_actual_surface_characterization.bqn: OK"
