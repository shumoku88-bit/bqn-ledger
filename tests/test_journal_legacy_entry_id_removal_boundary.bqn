#!/usr/bin/env bqn

# Proved:
# - an unreferenced structurally ordinary legacy entry-* event-id may be removed without changing accounting semantics
# - nonidentity metadata remains attached to the transaction
# - referenced legacy entry-* event-id removal fails global cross-link validation
# - plan-linked entry-* actuals are not cleanup candidates
# - parser and Stage 2A success alone are insufficient cleanup authorization
#
# Not proved:
# - production Journals may be rewritten automatically
# - every entry-* event-id is removable
# - physical fallback IDs are durable
# - line numbers or posting IDs remain stable
# - referenced event-ids may be rewritten
# - plan completion identity may be removed
# - cleanup can run without backup and exact snapshot guards

lib ← •Import "test_lib.bqn"
parser ← •Import "../src_next/journal_profile_stage1.bqn"
adapter ← •Import "../src_next/journal_posting_ir_stage2a.bqn"
ak ← •Import "../src_next/account_key.bqn"
loader ← •Import "../src_next/loader.bqn"
cube ← •Import "../src_next/cube.bqn"
tbds ← •Import "../src_next/tbds.bqn"

fixtureDir ← "fixtures/journal-legacy-entry-id-removal-boundary"
profile ← "historical_external_plan"
cycleStart ← "2026-07-01"
dayCount ← 31

cy ← {
  start ⇐ cycleStart,
  end_exclusive ⇐ "2026-08-01",
  day_count ⇐ dayCount,
  mode ⇐ "explicit"
}

IsLegacyEntryId ← {𝕊 text:
  (30 = ≠ text) ∧ ("entry-" ≡ 6 ↑ text) ∧ ∧´ 1 ∾ ((6 ↓ text) ∊ "0123456789abcdef")
}

MetaValues ← {𝕊 key‿tx:
  {𝕩.value}¨ ({key ≡ 𝕩.key}¨ tx.metadata) / tx.metadata
}

IsCandidate ← {𝕊 tx‿allTransactions:
  budgetTransactions ← ({𝕩.layer_name ≡ "budget"}¨ allTransactions) / allTransactions
  incomingReferences ← ({tx.source_event_id ≡ 𝕩.actual_event_id}¨ budgetTransactions) / budgetTransactions
  ∧´ ⟨
    tx.layer_name ≡ "actual",
    tx.identity_kind ≡ "durable",
    IsLegacyEntryId tx.source_event_id,
    0 = ≠ tx.plan_id,
    0 = ≠ tx.txn_id,
    0 = ≠ tx.allocation_id,
    0 = ≠ tx.actual_event_id,
    0 = ≠ tx.execution_envelope,
    0 = ≠ incomingReferences
  ⟩
}

FindDescription ← {𝕊 description‿transactions:
  ⊑ ({description ≡ 𝕩.description}¨ transactions) / transactions
}

# Exact generated-ID shape, not prefix-only classification.
lib.Assert IsLegacyEntryId "entry-0123456789abcdef01234567"
lib.Assert IsLegacyEntryId "entry-aaaaaaaaaaaaaaaaaaaaaaaa"
lib.Assert IsLegacyEntryId "entry-bbbbbbbbbbbbbbbbbbbbbbbb"
lib.Assert ¬ IsLegacyEntryId "entry-short"
lib.Assert ¬ IsLegacyEntryId "entry-0123456789ABCDEF01234567"
lib.Assert ¬ IsLegacyEntryId "opening-20260701-001"
lib.Assert ¬ IsLegacyEntryId "budget-companion-household-001"
lib.Assert ¬ IsLegacyEntryId "stage0-line-26"

beforeRaw ← loader.ReadRaw (fixtureDir ∾ "/before.journal")
beforeParsed ← parser.ParseWithProfile ⟨beforeRaw, profile⟩
"ok" lib.AssertEq beforeParsed.state
0 lib.AssertEq ≠ beforeParsed.diagnostics
5 lib.AssertEq ≠ beforeParsed.transactions
beforeTxs ← beforeParsed.transactions

opening ← FindDescription ⟨"Synthetic opening", beforeTxs⟩
unreferenced ← FindDescription ⟨"Legacy ordinary groceries", beforeTxs⟩
referenced ← FindDescription ⟨"Referenced legacy household purchase", beforeTxs⟩
companion ← FindDescription ⟨"Household budget companion", beforeTxs⟩
planLinked ← FindDescription ⟨"Legacy plan completion", beforeTxs⟩

# Conservative before classification and its disqualifying reasons.
lib.Assert ¬ IsCandidate ⟨opening, beforeTxs⟩
lib.Assert IsCandidate ⟨unreferenced, beforeTxs⟩
lib.Assert ¬ IsCandidate ⟨referenced, beforeTxs⟩
lib.Assert ¬ IsCandidate ⟨companion, beforeTxs⟩
lib.Assert ¬ IsCandidate ⟨planLinked, beforeTxs⟩

lib.Assert IsLegacyEntryId unreferenced.source_event_id
"" lib.AssertEq unreferenced.plan_id
"" lib.AssertEq unreferenced.txn_id
"" lib.AssertEq unreferenced.execution_envelope
0 lib.AssertEq +´ {unreferenced.source_event_id ≡ 𝕩.actual_event_id}¨ beforeTxs
1 lib.AssertEq +´ {referenced.source_event_id ≡ 𝕩.actual_event_id}¨ beforeTxs
"plan-legacy-household-001" lib.AssertEq planLinked.plan_id

# Each derived fixture is exactly before.journal minus one specified line.
beforeLines ← (@+10) loader.SplitKeepEmpty beforeRaw
AssertOneLineRemoval ← {𝕊 targetLine‿afterName:
  afterLines ← (@+10) loader.SplitKeepEmpty loader.ReadRaw (fixtureDir ∾ "/" ∾ afterName)
  1 lib.AssertEq +´ {targetLine ≡ 𝕩}¨ beforeLines
  filtered ← ({targetLine ≢ 𝕩}¨ beforeLines) / beforeLines
  filtered lib.AssertEq afterLines
}
AssertOneLineRemoval ⟨"    ; event-id: entry-0123456789abcdef01234567", "after-unreferenced.journal"⟩
AssertOneLineRemoval ⟨"    ; event-id: entry-aaaaaaaaaaaaaaaaaaaaaaaa", "after-referenced-invalid.journal"⟩
AssertOneLineRemoval ⟨"    ; event-id: entry-bbbbbbbbbbbbbbbbbbbbbbbb", "after-plan-linked.journal"⟩

# Removing the unreferenced ordinary identity preserves parsing and metadata.
afterRaw ← loader.ReadRaw (fixtureDir ∾ "/after-unreferenced.journal")
afterParsed ← parser.ParseWithProfile ⟨afterRaw, profile⟩
"ok" lib.AssertEq afterParsed.state
0 lib.AssertEq ≠ afterParsed.diagnostics
5 lib.AssertEq ≠ afterParsed.transactions
afterTxs ← afterParsed.transactions
afterOrdinary ← FindDescription ⟨"Legacy ordinary groceries", afterTxs⟩

"physical_fallback" lib.AssertEq afterOrdinary.identity_kind
lib.Assert "stage0-line-" ≡ 12 ↑ afterOrdinary.source_event_id
"" lib.AssertEq afterOrdinary.plan_id
"" lib.AssertEq afterOrdinary.txn_id
⟨"receipt kept"⟩ lib.AssertEq MetaValues ⟨"note", afterOrdinary⟩
⟨"JPY"⟩ lib.AssertEq MetaValues ⟨"currency", afterOrdinary⟩
0 lib.AssertEq ≠ MetaValues ⟨"event-id", afterOrdinary⟩
2 lib.AssertEq ≠ afterOrdinary.postings

⟨
  "opening-20260701-001",
  "entry-aaaaaaaaaaaaaaaaaaaaaaaa",
  "budget-companion-household-001",
  "entry-bbbbbbbbbbbbbbbbbbbbbbbb"
⟩ lib.AssertEq {𝕩.source_event_id}¨ 0‿2‿3‿4 ⊏ afterTxs

afterCompanion ← FindDescription ⟨"Household budget companion", afterTxs⟩
"entry-aaaaaaaaaaaaaaaaaaaaaaaa" lib.AssertEq afterCompanion.actual_event_id

# Identity, metadata carriers, and physical source positions are deliberately excluded.
# All accounting-bearing transaction and ordered-posting fields remain equal.
5 lib.AssertEq ≠ afterTxs
{𝕊 i:
  b ← i ⊑ beforeTxs
  a ← i ⊑ afterTxs
  b.date lib.AssertEq a.date
  b.status_marker lib.AssertEq a.status_marker
  b.description lib.AssertEq a.description
  b.layer_name lib.AssertEq a.layer_name
  b.plan_id lib.AssertEq a.plan_id
  b.allocation_id lib.AssertEq a.allocation_id
  b.execution_envelope lib.AssertEq a.execution_envelope
  b.actual_event_id lib.AssertEq a.actual_event_id
  b.txn_id lib.AssertEq a.txn_id
  (≠ b.postings) lib.AssertEq ≠ a.postings
  ({𝕩.account_key}¨ b.postings) lib.AssertEq {𝕩.account_key}¨ a.postings
  ({𝕩.delta}¨ b.postings) lib.AssertEq {𝕩.delta}¨ a.postings
  ({𝕩.commodity}¨ b.postings) lib.AssertEq {𝕩.commodity}¨ a.postings
  ({𝕩.side}¨ b.postings) lib.AssertEq {𝕩.side}¨ a.postings
  ({𝕩.posting_index}¨ b.postings) lib.AssertEq {𝕩.posting_index}¨ a.postings
}¨ ↕ 5

# Stage 2A equality on semantic carriers only.
accountLines ← loader.ReadLines (fixtureDir ∾ "/accounts.tsv")
resolved ← ak.Resolve accountLines
6 lib.AssertEq resolved.count

beforeStage ← adapter.Build ⟨beforeTxs, resolved, cycleStart⟩
afterStage ← adapter.Build ⟨afterTxs, resolved, cycleStart⟩
"ok" lib.AssertEq beforeStage.state
"ok" lib.AssertEq afterStage.state
0 lib.AssertEq ≠ beforeStage.diagnostics
0 lib.AssertEq ≠ afterStage.diagnostics
10 lib.AssertEq ≠ beforeStage.posting_rows
10 lib.AssertEq ≠ afterStage.posting_rows
lib.Assert ∧´ {𝕩.status ≡ "ok"}¨ beforeStage.posting_rows
lib.Assert ∧´ {𝕩.status ≡ "ok"}¨ afterStage.posting_rows

beforeRows ← beforeStage.posting_rows
afterRows ← afterStage.posting_rows
({𝕩.date}¨ beforeRows) lib.AssertEq {𝕩.date}¨ afterRows
({𝕩.day_index}¨ beforeRows) lib.AssertEq {𝕩.day_index}¨ afterRows
({𝕩.account_key}¨ beforeRows) lib.AssertEq {𝕩.account_key}¨ afterRows
({𝕩.account_key_index}¨ beforeRows) lib.AssertEq {𝕩.account_key_index}¨ afterRows
({𝕩.layer_name}¨ beforeRows) lib.AssertEq {𝕩.layer_name}¨ afterRows
({𝕩.layer_index}¨ beforeRows) lib.AssertEq {𝕩.layer_index}¨ afterRows
({𝕩.side}¨ beforeRows) lib.AssertEq {𝕩.side}¨ afterRows
({𝕩.delta}¨ beforeRows) lib.AssertEq {𝕩.delta}¨ afterRows
({𝕩.kind}¨ beforeRows) lib.AssertEq {𝕩.kind}¨ afterRows
({𝕩.status}¨ beforeRows) lib.AssertEq {𝕩.status}¨ afterRows
({𝕩.message}¨ beforeRows) lib.AssertEq {𝕩.message}¨ afterRows

# Cube equality and accounting summaries.
beforeCube ← cube.Materialize ⟨beforeRows, dayCount, resolved.count⟩
afterCube ← cube.Materialize ⟨afterRows, dayCount, resolved.count⟩
beforeCube.cube lib.AssertEq afterCube.cube
beforeCube.actual_account_totals lib.AssertEq afterCube.actual_account_totals
beforeCube.layer_totals_vec lib.AssertEq afterCube.layer_totals_vec
beforeCube.actual_expense_total lib.AssertEq afterCube.actual_expense_total
beforeCube.valid_count lib.AssertEq afterCube.valid_count
beforeCube.skipped_count lib.AssertEq afterCube.skipped_count
2000 lib.AssertEq beforeCube.actual_expense_total
10 lib.AssertEq beforeCube.valid_count
0 lib.AssertEq beforeCube.skipped_count

# TBDS equality on accounting-state carriers.
beforeTbds ← tbds.Build ⟨beforeRows, beforeCube, resolved, cy⟩
afterTbds ← tbds.Build ⟨afterRows, afterCube, resolved, cy⟩
({𝕩.period_id}¨ beforeTbds) lib.AssertEq {𝕩.period_id}¨ afterTbds
({𝕩.period_start}¨ beforeTbds) lib.AssertEq {𝕩.period_start}¨ afterTbds
({𝕩.period_end_exclusive}¨ beforeTbds) lib.AssertEq {𝕩.period_end_exclusive}¨ afterTbds
({𝕩.account_key}¨ beforeTbds) lib.AssertEq {𝕩.account_key}¨ afterTbds
({𝕩.currency}¨ beforeTbds) lib.AssertEq {𝕩.currency}¨ afterTbds
({𝕩.role}¨ beforeTbds) lib.AssertEq {𝕩.role}¨ afterTbds
({𝕩.layer_name}¨ beforeTbds) lib.AssertEq {𝕩.layer_name}¨ afterTbds
({𝕩.opening}¨ beforeTbds) lib.AssertEq {𝕩.opening}¨ afterTbds
({𝕩.debit_movement}¨ beforeTbds) lib.AssertEq {𝕩.debit_movement}¨ afterTbds
({𝕩.credit_movement}¨ beforeTbds) lib.AssertEq {𝕩.credit_movement}¨ afterTbds
({𝕩.movement}¨ beforeTbds) lib.AssertEq {𝕩.movement}¨ afterTbds
({𝕩.closing}¨ beforeTbds) lib.AssertEq {𝕩.closing}¨ afterTbds
({𝕩.status}¨ beforeTbds) lib.AssertEq {𝕩.status}¨ afterTbds
({𝕩.message}¨ beforeTbds) lib.AssertEq {𝕩.message}¨ afterTbds

# Referenced removal fails because actual-event-id targets require durable actual identity.
referencedInvalidRaw ← loader.ReadRaw (fixtureDir ∾ "/after-referenced-invalid.journal")
referencedInvalid ← parser.ParseWithProfile ⟨referencedInvalidRaw, profile⟩
"error" lib.AssertEq referencedInvalid.state
lib.Assert ∨´ {𝕩.code ≡ "actual_event_target_invalid"}¨ referencedInvalid.diagnostics
invalidCompanion ← FindDescription ⟨"Household budget companion", referencedInvalid.transactions⟩
"entry-aaaaaaaaaaaaaaaaaaaaaaaa" lib.AssertEq invalidCompanion.actual_event_id
invalidTarget ← FindDescription ⟨"Referenced legacy household purchase", referencedInvalid.transactions⟩
"physical_fallback" lib.AssertEq invalidTarget.identity_kind

# Parser and Stage 2A acceptance do not authorize removal of durable plan-completion identity.
planAfterRaw ← loader.ReadRaw (fixtureDir ∾ "/after-plan-linked.journal")
planAfterParsed ← parser.ParseWithProfile ⟨planAfterRaw, profile⟩
"ok" lib.AssertEq planAfterParsed.state
0 lib.AssertEq ≠ planAfterParsed.diagnostics
5 lib.AssertEq ≠ planAfterParsed.transactions
planAfterTx ← FindDescription ⟨"Legacy plan completion", planAfterParsed.transactions⟩
"physical_fallback" lib.AssertEq planAfterTx.identity_kind
"plan-legacy-household-001" lib.AssertEq planAfterTx.plan_id
planAfterStage ← adapter.Build ⟨planAfterParsed.transactions, resolved, cycleStart⟩
"ok" lib.AssertEq planAfterStage.state
0 lib.AssertEq ≠ planAfterStage.diagnostics
lib.Assert ¬ IsCandidate ⟨planLinked, beforeTxs⟩

•Out "test_journal_legacy_entry_id_removal_boundary.bqn: OK"
