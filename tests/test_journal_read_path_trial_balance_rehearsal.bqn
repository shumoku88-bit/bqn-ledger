#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
parser ← •Import "../src_next/journal_profile_stage1.bqn"
adapter ← •Import "../src_next/journal_posting_ir_stage2a.bqn"
context ← •Import "../src_next/context.bqn"
trial_balance ← •Import "../src_next/trial_balance.bqn"
cube ← •Import "../src_next/cube.bqn"
ak ← •Import "../src_next/account_key.bqn"
loader ← •Import "../src_next/loader.bqn"

base ← "fixtures/journal-native-three-posting-parity"
cycleStart ← "2026-08-01"
cy ← {
  start ⇐ cycleStart,
  end_exclusive ⇐ "2026-09-01",
  day_count ⇐ 31,
  mode ⇐ "explicit"
}

accountLines ← loader.ReadLines (base ∾ "/accounts.tsv")
resolved ← ak.Resolve accountLines
⟨"assets:anonymous/JPY", "expenses:anonymous-first/JPY", "expenses:anonymous-second/JPY"⟩ lib.AssertEq resolved.account_keys

raw ← •FChars ("../" ∾ base ∾ "/profile.journal")
parsed ← parser.Parse raw
"ok" lib.AssertEq parsed.state
0 lib.AssertEq ≠ parsed.diagnostics
1 lib.AssertEq ≠ parsed.transactions
transaction ← ⊑ parsed.transactions
3 lib.AssertEq ≠ transaction.postings

journalResult ← adapter.Build ⟨parsed.transactions, resolved, cycleStart⟩
"ok" lib.AssertEq journalResult.state
0 lib.AssertEq ≠ journalResult.diagnostics
journalRows ← journalResult.posting_rows
3 lib.AssertEq ≠ journalRows
lib.Assert ∧´ {𝕩.status ≡ "ok"}¨ journalRows
lib.Assert ∧´ {𝕩.source_file ≡ "profile.journal"}¨ journalRows
⟨800, 300, -1100⟩ lib.AssertEq {𝕩.delta}¨ journalRows
0 lib.AssertEq +´ {𝕩.delta}¨ journalRows

view ← context.BuildPeriodView ⟨journalRows, resolved, cy⟩
3 lib.AssertEq view.cube.valid_count
0 lib.AssertEq view.cube.skipped_count
0 lib.AssertEq ≠ view.cube.skipped_rows
⟨-1100, 800, 300⟩ lib.AssertEq view.cube.actual_account_totals
12 lib.AssertEq ≠ view.tbds
actualRows ← (cube.layer_actual = {𝕩.layer_index}¨ view.tbds) / view.tbds
3 lib.AssertEq ≠ actualRows

ctx ← {cy ⇐ cy, tbds ⇐ view.tbds}
tb ← trial_balance.Build ⟨ctx, cube.layer_actual⟩
"2026-08-01" lib.AssertEq tb.period_start
"2026-09-01" lib.AssertEq tb.period_end_exclusive
"actual" lib.AssertEq tb.layer_name
⟨"assets:anonymous/JPY", "expenses:anonymous-first/JPY", "expenses:anonymous-second/JPY"⟩ lib.AssertEq tb.accounts

•Out "test_journal_read_path_trial_balance_rehearsal.bqn: OK"
