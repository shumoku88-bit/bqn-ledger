#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
parser ← •Import "../src_next/journal_profile_stage1.bqn"
adapter ← •Import "../src_next/journal_posting_ir_stage2a.bqn"
context ← •Import "../src_next/context.bqn"
cube ← •Import "../src_next/cube.bqn"
ak ← •Import "../src_next/account_key.bqn"
loader ← •Import "../src_next/loader.bqn"

base ← "fixtures/journal-native-three-posting-parity"
cycleStart ← "2026-08-01"
dayCount ← 31
layerAxis ← cube.layer_names
expectedTxnId ← "txn-anonymous-split-001"

accountLines ← loader.ReadLines (base ∾ "/accounts.tsv")
resolved ← ak.Resolve accountLines
accountAxis ← resolved.account_keys
⟨"assets:anonymous", "expenses:anonymous-first", "expenses:anonymous-second"⟩ lib.AssertEq resolved.accounts
⟨"assets:anonymous/JPY", "expenses:anonymous-first/JPY", "expenses:anonymous-second/JPY"⟩ lib.AssertEq accountAxis
⟨"actual", "plan", "budget", "forecast"⟩ lib.AssertEq layerAxis

# Journal: Parse -> Stage 2A Build.
raw ← •FChars ("../" ∾ base ∾ "/profile.journal")
parsed ← parser.Parse raw
"ok" lib.AssertEq parsed.state
0 lib.AssertEq ≠ parsed.diagnostics
1 lib.AssertEq ≠ parsed.transactions

transaction ← ⊑ parsed.transactions
"actual" lib.AssertEq transaction.layer_name
'*' lib.AssertEq transaction.status_marker
"physical_fallback" lib.AssertEq transaction.identity_kind
0 lib.AssertEq +´ {"event-id" ≡ 𝕩.key}¨ transaction.metadata
3 lib.AssertEq ≠ transaction.postings
⟨"expenses:anonymous-first", "expenses:anonymous-second", "assets:anonymous"⟩ lib.AssertEq {𝕩.account_key}¨ transaction.postings
⟨800, 300, -1100⟩ lib.AssertEq {𝕩.delta}¨ transaction.postings
⟨0, 1, 2⟩ lib.AssertEq {𝕩.posting_index}¨ transaction.postings

journalResult ← adapter.Build ⟨parsed.transactions, resolved, cycleStart⟩
"ok" lib.AssertEq journalResult.state
0 lib.AssertEq ≠ journalResult.diagnostics
journalRows ← journalResult.posting_rows
3 lib.AssertEq ≠ journalRows
lib.Assert ∧´ {𝕩.status ≡ "ok"}¨ journalRows
⟨"expenses:anonymous-first/JPY", "expenses:anonymous-second/JPY", "assets:anonymous/JPY"⟩ lib.AssertEq {𝕩.account_key}¨ journalRows
⟨800, 300, -1100⟩ lib.AssertEq {𝕩.delta}¨ journalRows
⟨"debit", "debit", "credit"⟩ lib.AssertEq {𝕩.side}¨ journalRows

# Legacy: exactly two physical TSV rows -> four Posting IR rows.
legacyLines ← loader.ReadLines (base ∾ "/journal.tsv")
2 lib.AssertEq ≠ legacyLines
legacyFields ← loader.SplitTsvKeepEmpty¨ legacyLines
⟨6, 6⟩ lib.AssertEq ≠¨ legacyFields
lib.Assert ∧´ {("txn_id=" ∾ expectedTxnId) ≡ 5 ⊑ 𝕩}¨ legacyFields

snapshot ← {
  sources⇐⟨
    {source_file⇐"journal.tsv", required⇐1, lines⇐legacyLines},
    {source_file⇐"plan.tsv", required⇐0, lines⇐⟨⟩},
    {source_file⇐"budget_alloc.tsv", required⇐0, lines⇐⟨⟩}
  ⟩
}
legacyResult ← context.BuildCheckedPostingProjectionFromSnapshot ⟨snapshot, resolved, cycleStart⟩
"ok" lib.AssertEq legacyResult.state
0 lib.AssertEq ≠ legacyResult.diagnostics
2 lib.AssertEq ≠ legacyResult.row_evidence
lib.Assert ∧´ {
  ∨´ (("txn_id=" ∾ expectedTxnId)⊸≡¨ 5 ↓ 𝕩.flds)
}¨ legacyResult.row_evidence
legacyRows ← legacyResult.posting_rows
4 lib.AssertEq ≠ legacyRows
lib.Assert ∧´ {𝕩.status ≡ "ok"}¨ legacyRows
lib.Assert 0 < ≠ expectedTxnId
⟨<expectedTxnId, <expectedTxnId, <expectedTxnId, <expectedTxnId⟩ lib.AssertEq {<𝕩.tx_id}¨ legacyRows
⟨0, 0, 1, 1⟩ lib.AssertEq {𝕩.source_row}¨ legacyRows

# Balance is local to the native event and to each legacy physical row.
0 lib.AssertEq +´ {𝕩.delta}¨ journalRows
⟨0, 0⟩ lib.AssertEq {
  sourceRow ← 𝕩
  +´ {𝕩.delta}¨ ({𝕩.source_row = sourceRow}¨ legacyRows) / legacyRows
}¨ 0‿1
0 lib.AssertEq +´ {𝕩.delta}¨ legacyRows

# Primary boundary: one explicit common (date, account_key, layer_name) axis.
semanticAxis ← ⟨
  {date⇐"2026-08-03", account_key⇐"assets:anonymous/JPY", layer_name⇐"actual"},
  {date⇐"2026-08-03", account_key⇐"expenses:anonymous-first/JPY", layer_name⇐"actual"},
  {date⇐"2026-08-03", account_key⇐"expenses:anonymous-second/JPY", layer_name⇐"actual"}
⟩
expectedSemanticVector ← ⟨-1100, 800, 300⟩

ReduceCoordinates ← {𝕊 rows:
  {𝕊 coordinate:
    matches ← {
      dateOk ← 𝕩.date ≡ coordinate.date
      accountOk ← 𝕩.account_key ≡ coordinate.account_key
      layerOk ← 𝕩.layer_name ≡ coordinate.layer_name
      dateOk ∧ accountOk ∧ layerOk
    }¨ rows
    +´ 0 ∾ {𝕩.delta}¨ matches / rows
  }¨ semanticAxis
}

# This comparison carrier is intentionally local: it preserves topology while
# comparing only the selected semantic coordinate reduction.
MakeSemanticEvidence ← {𝕊 sourceKind‿rows:
  {source_kind⇐sourceKind, row_count⇐≠ rows, axis⇐semanticAxis, values⇐ReduceCoordinates rows}
}
journalEvidence ← MakeSemanticEvidence ⟨"journal", journalRows⟩
legacyEvidence ← MakeSemanticEvidence ⟨"legacy_tsv", legacyRows⟩
expectedSemanticVector lib.AssertEq journalEvidence.values
expectedSemanticVector lib.AssertEq legacyEvidence.values
journalEvidence.values lib.AssertEq legacyEvidence.values
3 lib.AssertEq journalEvidence.row_count
4 lib.AssertEq legacyEvidence.row_count

# Secondary evidence: materialize both paths on the same explicit axes.
AssertRowsUseAxes ← {𝕊 rows:
  lib.Assert ∧´ {
    accountIndexOk ← 𝕩.account_key ≡ 𝕩.account_key_index ⊑ accountAxis
    layerIndexOk ← 𝕩.layer_name ≡ 𝕩.layer_index ⊑ layerAxis
    dayOk ← 𝕩.day_index = 2
    accountIndexOk ∧ layerIndexOk ∧ dayOk
  }¨ rows
}
AssertRowsUseAxes journalRows
AssertRowsUseAxes legacyRows

journalCube ← cube.Materialize ⟨journalRows, dayCount, resolved.count⟩
legacyCube ← cube.Materialize ⟨legacyRows, dayCount, resolved.count⟩
expectedShape ← ⟨dayCount, resolved.count, cube.layer_count⟩
expectedShape lib.AssertEq ≢ journalCube.cube
expectedShape lib.AssertEq ≢ legacyCube.cube
journalCube.cube lib.AssertEq legacyCube.cube

# Selected account and layer projections remain numeric Cube evidence, not
# whole-carrier equality.
expectedSemanticVector lib.AssertEq journalCube.actual_account_totals
expectedSemanticVector lib.AssertEq legacyCube.actual_account_totals
journalCube.actual_account_totals lib.AssertEq legacyCube.actual_account_totals
journalCube.ak_totals lib.AssertEq legacyCube.ak_totals
journalCube.layer_totals_vec lib.AssertEq legacyCube.layer_totals_vec
⟨0, 0, 0, 0⟩ lib.AssertEq journalCube.layer_totals_vec
1100 lib.AssertEq journalCube.actual_expense_total
journalCube.actual_expense_total lib.AssertEq legacyCube.actual_expense_total

3 lib.AssertEq journalCube.valid_count
4 lib.AssertEq legacyCube.valid_count
0 lib.AssertEq journalCube.skipped_count
0 lib.AssertEq legacyCube.skipped_count
0 lib.AssertEq ≠ journalCube.skipped_rows
0 lib.AssertEq ≠ legacyCube.skipped_rows

# The 3-versus-4 Posting IR topology is evidence and is never normalized.
3 lib.AssertEq ≠ journalRows
4 lib.AssertEq ≠ legacyRows

•Out "test_journal_native_three_posting_semantic_parity.bqn: OK"
