#!/usr/bin/env bqn

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
raw ← •FChars ("../" ∾ base ∾ "/profile.journal")
parsed ← parser.Parse raw
journalResult ← adapter.Build ⟨parsed.transactions, resolved, cycleStart⟩
journalRows ← journalResult.posting_rows
view ← context.BuildPeriodView ⟨journalRows, resolved, cy⟩
ctx ← {cy ⇐ cy, tbds ⇐ view.tbds}
tb ← trial_balance.Build ⟨ctx, cube.layer_actual⟩

•Out "test_journal_read_path_trial_balance_rehearsal.bqn: OK"
