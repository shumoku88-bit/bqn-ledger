#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
parser ← •Import "../src_next/journal_profile_stage1.bqn"
adapter ← •Import "../src_next/journal_posting_ir_stage2a.bqn"
context ← •Import "../src_next/context.bqn"
cube ← •Import "../src_next/cube.bqn"
ak ← •Import "../src_next/account_key.bqn"
loader ← •Import "../src_next/loader.bqn"
tb ← •Import "../src_next/trial_balance.bqn"

base ← "fixtures/journal-native-three-posting-parity"
cycleStart ← "2026-08-01"
cycleEnd ← "2026-09-01"
dayCount ← 31

# 1. Load resolved accounts
accountLines ← loader.ReadLines (base ∾ "/accounts.tsv")
resolved ← ak.Resolve accountLines

# 2. Parse profile.journal -> Transaction IR
raw ← •FChars ("../" ∾ base ∾ "/profile.journal")
parsed ← parser.Parse raw
"ok" lib.AssertEq parsed.state

# 3. Build Posting IR rows from Transaction IR
journalResult ← adapter.Build ⟨parsed.transactions, resolved, cycleStart⟩
"ok" lib.AssertEq journalResult.state
journalRows ← journalResult.posting_rows

# 4. Define cycle coordinate
cy ← {
  start ⇐ cycleStart,
  end_exclusive ⇐ cycleEnd,
  day_count ⇐ dayCount,
  mode ⇐ "monthly"
}

# 5. Build Rehearsal Cube and TBDS
view ← context.BuildPeriodView ⟨journalRows, resolved, cy⟩

# 6. Assemble Rehearsal Context
rehearsalCtx ← {
  cy ⇐ cy,
  tbds ⇐ view.tbds
}

# 7. Build Trial Balance Report
trialBalanceActual ← tb.Build ⟨rehearsalCtx, cube.layer_actual⟩

# 8. Setup legacy TSV projection for verification
legacyLines ← loader.ReadLines (base ∾ "/journal.tsv")
legacySnapshot ← {
  sources ⇐ ⟨
    {source_file⇐"journal.tsv", required⇐1, lines⇐legacyLines},
    {source_file⇐"plan.tsv", required⇐0, lines⇐⟨⟩},
    {source_file⇐"budget_alloc.tsv", required⇐0, lines⇐⟨⟩}
  ⟩
}
legacyProjection ← context.BuildCheckedPostingProjectionFromSnapshot ⟨legacySnapshot, resolved, cycleStart⟩
"ok" lib.AssertEq legacyProjection.state
legacyRows ← legacyProjection.posting_rows

legacyView ← context.BuildPeriodView ⟨legacyRows, resolved, cy⟩
legacyCtx ← {
  cy ⇐ cy,
  tbds ⇐ legacyView.tbds
}
trialBalanceLegacy ← tb.Build ⟨legacyCtx, cube.layer_actual⟩

# 9. Verify Jounal-rehearsed Trial Balance matches legacy TSV Trial Balance
trialBalanceActual.openings lib.AssertEq trialBalanceLegacy.openings
trialBalanceActual.debits lib.AssertEq trialBalanceLegacy.debits
trialBalanceActual.credits lib.AssertEq trialBalanceLegacy.credits
trialBalanceActual.closings lib.AssertEq trialBalanceLegacy.closings
trialBalanceActual.accounts lib.AssertEq trialBalanceLegacy.accounts

# 10. Verify accounting invariants (zero-sum check)
0 lib.AssertEq +´ trialBalanceActual.openings
0 lib.AssertEq (+´ trialBalanceActual.debits) + (+´ trialBalanceActual.credits)
0 lib.AssertEq +´ trialBalanceActual.closings

# 11. Format human report to verify display routing doesn't fail
humanOutput ← tb.FormatHuman trialBalanceActual

•Out "test_journal_read_path_trial_balance_rehearsal.bqn: OK"
