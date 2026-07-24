# tests/test_journal_reconstructible_identity_cleanup.bqn
# Unit test for reconstructible Journal identity cleanup.

lib ← •Import "test_lib.bqn"
cleanup ← •Import "../src_edit/journal_reconstructible_identity_cleanup.bqn"

lf ← @+10

# Construct public synthetic fixture
# Transactions:
# 1. Removable migration identity (no functional link)
# 2. Preserved migration identity (with plan-id functional link)
# 3. Preserved completion identity (with plan-id functional link)
# 4. Preserved purchase-shaped identity 1 (no functional link)
# 5. Preserved purchase-shaped identity 2 (no functional link)
# 6. Identity-free transaction (multi-posting, Unicode, metadata before/after event-id)

syntheticJournal ← "account assets:cash
  ; role: asset

account expenses:food
  ; role: expense

account income:salary
  ; role: income

commodity JPY

; Comment before transactions

2026-01-01 * ""Removable migration item""
  ; layer: actual
  ; event-id: legacy:synthetic-source:0
  ; note: test note
  assets:cash -1000 JPY
  expenses:food 1000 JPY

2026-01-02 * ""Preserved migration with plan""
  ; layer: actual
  ; event-id: legacy:synthetic-source:1
  ; plan-id: plan-2026-001
  assets:cash -2000 JPY
  expenses:food 2000 JPY

2026-01-03 * ""Preserved completion item""
  ; layer: actual
  ; event-id: completion-plan-2026-002-2026-01-03
  ; plan-id: plan-2026-002
  assets:cash -3000 JPY
  expenses:food 3000 JPY

2026-01-04 * ""Preserved purchase item 1""
  ; layer: actual
  ; event-id: purchase-synthetic-item-001
  assets:cash -4000 JPY
  expenses:food 4000 JPY

2026-01-05 * ""Preserved purchase item 2""
  ; layer: actual
  ; event-id: purchase-synthetic-item-002
  assets:cash -5000 JPY
  expenses:food 5000 JPY

2026-01-06 * ""Identity free multi-posting 食費・スーパー買い物""
  ; layer: actual
  ; note: multi posting note
  assets:cash -6000 JPY
  expenses:food 5000 JPY
  expenses:food 1000 JPY
"

# 1. Test Analyze
an ← cleanup.Analyze ⟨syntheticJournal, "historical_external_plan"⟩
"ok" lib.AssertEq an.state
6 lib.AssertEq an.total_transactions
5 lib.AssertEq an.explicit_event_id
1 lib.AssertEq an.identity_free
1 lib.AssertEq an.removable_count
2 lib.AssertEq an.preserved_functional
2 lib.AssertEq an.preserved_purchase
0 lib.AssertEq an.rejected_unknown

# 2. Test BuildCandidate success path
res ← cleanup.BuildCandidate ⟨syntheticJournal, "historical_external_plan", 1⟩
"ok" lib.AssertEq res.state
6 lib.AssertEq res.analysis_after.total_transactions
4 lib.AssertEq res.analysis_after.explicit_event_id
2 lib.AssertEq res.analysis_after.identity_free
2 lib.AssertEq res.analysis_after.preserved_functional
2 lib.AssertEq res.analysis_after.preserved_purchase

# Check transformed text preserves final newline, comments, Unicode, and other metadata
candRaw ← res.candidate_raw
lib.Assert (lf = ¯1 ⊑ candRaw)
lib.Assert (0 = +´ 0 ∾ "legacy:synthetic-source:0" ⍷ candRaw)
lib.Assert (0 < +´ 0 ∾ "legacy:synthetic-source:1" ⍷ candRaw)
lib.Assert (0 < +´ 0 ∾ "completion-plan-2026-002-2026-01-03" ⍷ candRaw)
lib.Assert (0 < +´ 0 ∾ "purchase-synthetic-item-001" ⍷ candRaw)
lib.Assert (0 < +´ 0 ∾ "purchase-synthetic-item-002" ⍷ candRaw)
lib.Assert (0 < +´ 0 ∾ "食費・スーパー買い物" ⍷ candRaw)
lib.Assert (0 < +´ 0 ∾ "; Comment before transactions" ⍷ candRaw)
lib.Assert (0 < +´ 0 ∾ "; note: test note" ⍷ candRaw)

# 3. Test Failure path: removal count mismatch
errRes1 ← cleanup.BuildCandidate ⟨syntheticJournal, "historical_external_plan", 2⟩
"error" lib.AssertEq errRes1.state
"removal_count_mismatch" lib.AssertEq errRes1.code

# 4. Test Failure path: malformed Journal
malformedJournal ← "2026-99-99 * ""invalid date""\n  assets:cash -100 JPY\n"
errRes2 ← cleanup.Analyze ⟨malformedJournal, "historical_external_plan"⟩
"error" lib.AssertEq errRes2.state

•Out "test_journal_reconstructible_identity_cleanup.bqn: PASS"
