#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
parser ← •Import "../src_next/journal_profile_stage1.bqn"
adapter ← •Import "../src_next/journal_posting_ir_stage2a.bqn"
context ← •Import "../src_next/context.bqn"
ak ← •Import "../src_next/account_key.bqn"
loader ← •Import "../src_next/loader.bqn"

base ← "fixtures/journal-posting-ir-stage2a"
cycleStart ← "2026-08-01"

raw ← •FChars "../fixtures/journal-posting-ir-stage2a/profile.journal"
parsed ← parser.Parse raw
"ok" lib.AssertEq parsed.state
0 lib.AssertEq ≠ parsed.diagnostics
2 lib.AssertEq ≠ parsed.transactions
⟨2, 2⟩ lib.AssertEq {≠𝕩.postings}¨ parsed.transactions
⟨<"actual", <"plan"⟩ lib.AssertEq {<𝕩.layer_name}¨ parsed.transactions

accountLines ← loader.ReadLines (base ∾ "/accounts.tsv")
resolved ← ak.Resolve accountLines
resolved.accounts lib.AssertEq {𝕩.account_key}¨ parsed.accounts

journalResult ← adapter.Build ⟨parsed.transactions, resolved, cycleStart⟩
"ok" lib.AssertEq journalResult.state
0 lib.AssertEq ≠ journalResult.diagnostics
4 lib.AssertEq ≠ journalResult.posting_rows

snapshot ← {
  sources⇐⟨
    {source_file⇐"journal.tsv", required⇐1, lines⇐loader.ReadLines (base ∾ "/journal.tsv")},
    {source_file⇐"plan.tsv", required⇐0, lines⇐loader.ReadLines (base ∾ "/plan.tsv")},
    {source_file⇐"budget_alloc.tsv", required⇐0, lines⇐⟨⟩}
  ⟩
}
tsvResult ← context.BuildCheckedPostingProjectionFromSnapshot ⟨snapshot, resolved, cycleStart⟩
"ok" lib.AssertEq tsvResult.state
0 lib.AssertEq ≠ tsvResult.diagnostics
4 lib.AssertEq ≠ tsvResult.posting_rows

journalRows ← journalResult.posting_rows
tsvRows ← tsvResult.posting_rows

# Stage 2A compares only the selected semantic subset. Row order proves both
# transaction order and posting order because each fixture transaction has two postings.
({<𝕩.date}¨ tsvRows) lib.AssertEq {<𝕩.date}¨ journalRows
({<𝕩.account_key}¨ tsvRows) lib.AssertEq {<𝕩.account_key}¨ journalRows
({𝕩.delta}¨ tsvRows) lib.AssertEq {𝕩.delta}¨ journalRows
({<𝕩.side}¨ tsvRows) lib.AssertEq {<𝕩.side}¨ journalRows
({<𝕩.layer_name}¨ tsvRows) lib.AssertEq {<𝕩.layer_name}¨ journalRows

⟨<"2026-08-14", <"2026-08-15"⟩ lib.AssertEq {<𝕩.date}¨ 0‿2 ⊏ journalRows
⟨<"expenses:rent/JPY", <"assets:bank/JPY", <"expenses:rent/JPY", <"assets:bank/JPY"⟩ lib.AssertEq {<𝕩.account_key}¨ journalRows

0 lib.AssertEq +´ {𝕩.delta}¨ 0‿1 ⊏ journalRows
0 lib.AssertEq +´ {𝕩.delta}¨ 2‿3 ⊏ journalRows
lib.Assert ∧´ {𝕩.status ≡ "ok"}¨ journalRows
lib.Assert ∧´ {𝕩.status ≡ "ok"}¨ tsvRows

# Access and check every field in the 16-field Journal Posting IR row shape.
first ← ⊑ journalRows
"profile.journal" lib.AssertEq first.source_file
0 lib.AssertEq first.source_row
lib.Assert 0 < ≠ first.source_id
lib.Assert 0 < ≠ first.tx_id
lib.Assert 0 < ≠ first.posting_id
"2026-08-14" lib.AssertEq first.date
13 lib.AssertEq first.day_index
"expenses:rent/JPY" lib.AssertEq first.account_key
1 lib.AssertEq first.account_key_index
"actual" lib.AssertEq first.layer_name
0 lib.AssertEq first.layer_index
"debit" lib.AssertEq first.side
5000 lib.AssertEq first.delta
"expense" lib.AssertEq first.kind
"ok" lib.AssertEq first.status
"" lib.AssertEq first.message

•Out "test_journal_posting_ir_adapter_stage2a.bqn: OK"
