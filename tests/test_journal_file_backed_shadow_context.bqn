#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
shadow ← •Import "../src_next/journal_shadow_context.bqn"
context ← •Import "../src_next/context.bqn"
trial_balance ← •Import "../src_next/trial_balance.bqn"
balances ← •Import "../src_next/balances.bqn"
cube ← •Import "../src_next/cube.bqn"
loader ← •Import "../src_next/loader.bqn"

base ← "fixtures/journal-file-backed-shadow-context"
journalPath ← base ∾ "/shadow.journal"
asOf ← "2026-08-15"

# The Journal source is read only from the physical fixture by the builder.
result ← shadow.Build ⟨base, journalPath, asOf⟩
"ok" lib.AssertEq result.state
"journal-shadow" lib.AssertEq result.source_mode
journalPath lib.AssertEq result.source_path
0 lib.AssertEq ≠ result.diagnostics
2 lib.AssertEq ≠ result.transactions
5 lib.AssertEq ≠ result.posting_rows
lib.Assert ∧´ {𝕩.status ≡ "ok"}¨ result.posting_rows

shadowCtx ← result.context
base lib.AssertEq shadowCtx.base
asOf lib.AssertEq shadowCtx.as_of
"journal-shadow" lib.AssertEq shadowCtx.source_mode
journalPath lib.AssertEq shadowCtx.source_path
result.transactions lib.AssertEq shadowCtx.transactions
result.posting_rows lib.AssertEq shadowCtx.posting_rows
0 lib.AssertEq ≠ shadowCtx.issues
0 lib.AssertEq ≠ shadowCtx.diagnostics

# Native transaction grouping, durable identity, posting order, and physical lines.
⟨"event-opening-001", "event-split-001"⟩ lib.AssertEq {𝕩.source_event_id}¨ result.transactions
⟨"durable", "durable"⟩ lib.AssertEq {𝕩.identity_kind}¨ result.transactions
⟨18, 24⟩ lib.AssertEq {𝕩.source_start_line}¨ result.transactions
⟨22, 29⟩ lib.AssertEq {𝕩.source_end_line}¨ result.transactions
⟨2, 3⟩ lib.AssertEq ≠¨ {𝕩.postings}¨ result.transactions
⟨
  "assets:cash", "equity:opening",
  "expenses:food", "expenses:household", "assets:cash"
⟩ lib.AssertEq ∾ {𝕩.account_key}¨¨ {𝕩.postings}¨ result.transactions
⟨0, 1, 0, 1, 2⟩ lib.AssertEq ∾ {𝕩.posting_index}¨¨ {𝕩.postings}¨ result.transactions
⟨21, 22, 27, 28, 29⟩ lib.AssertEq ∾ {𝕩.source_line}¨¨ {𝕩.postings}¨ result.transactions
⟨
  "event-opening-001:0", "event-opening-001:1",
  "event-split-001:0", "event-split-001:1", "event-split-001:2"
⟩ lib.AssertEq {𝕩.posting_id}¨ ∾ {𝕩.postings}¨ result.transactions
lib.Assert ∧´ {0 = +´ {𝕩.delta}¨ 𝕩.postings}¨ result.transactions

# Path A is the unchanged TSV BuildContext; Path B is the file-backed shadow.
tsvCtx ← context.BuildContext ⟨base, asOf⟩
⟨31, 4, 4⟩ lib.AssertEq ≢ shadowCtx.cube.cube
(≢ tsvCtx.cube.cube) lib.AssertEq ≢ shadowCtx.cube.cube
(≠ tsvCtx.tbds) lib.AssertEq ≠ shadowCtx.tbds
16 lib.AssertEq ≠ shadowCtx.tbds

ActualRows ← {𝕊 rows: (cube.layer_actual = {𝕩.layer_index}¨ rows) / rows}
tsvActual ← ActualRows tsvCtx.tbds
shadowActual ← ActualRows shadowCtx.tbds
4 lib.AssertEq ≠ shadowActual
({𝕩.account_key}¨ tsvActual) lib.AssertEq ({𝕩.account_key}¨ shadowActual)
({𝕩.layer_name}¨ tsvActual) lib.AssertEq ({𝕩.layer_name}¨ shadowActual)
({𝕩.opening}¨ tsvActual) lib.AssertEq ({𝕩.opening}¨ shadowActual)
({𝕩.debit_movement}¨ tsvActual) lib.AssertEq ({𝕩.debit_movement}¨ shadowActual)
({𝕩.credit_movement}¨ tsvActual) lib.AssertEq ({𝕩.credit_movement}¨ shadowActual)
({𝕩.movement}¨ tsvActual) lib.AssertEq ({𝕩.movement}¨ shadowActual)
({𝕩.closing}¨ tsvActual) lib.AssertEq ({𝕩.closing}¨ shadowActual)

# Trial Balance equality field by field.
tsvTb ← trial_balance.Build ⟨tsvCtx, cube.layer_actual⟩
shadowTb ← trial_balance.Build ⟨shadowCtx, cube.layer_actual⟩
tsvTb.period_start lib.AssertEq shadowTb.period_start
tsvTb.period_end_exclusive lib.AssertEq shadowTb.period_end_exclusive
tsvTb.as_of lib.AssertEq shadowTb.as_of
tsvTb.layer_name lib.AssertEq shadowTb.layer_name
tsvTb.accounts lib.AssertEq shadowTb.accounts
tsvTb.openings lib.AssertEq shadowTb.openings
tsvTb.debits lib.AssertEq shadowTb.debits
tsvTb.credits lib.AssertEq shadowTb.credits
tsvTb.closings lib.AssertEq shadowTb.closings

# Balance entries are exact and both established formatters complete.
tsvBalances ← balances.Build tsvCtx
shadowBalances ← balances.Build shadowCtx
tsvBalances lib.AssertEq shadowBalances
lib.Assert 0 < ≠ balances.Format shadowBalances
lib.Assert 0 < ≠ balances.FormatHuman shadowBalances

# Native Journal topology is retained rather than re-flattened to TSV rows.
3 lib.AssertEq ≠ loader.ReadLines (base ∾ "/journal.tsv")
5 lib.AssertEq ≠ result.posting_rows
6 lib.AssertEq ≠ ({𝕩.source_file ≡ "journal.tsv"}¨ tsvCtx.posting_rows) / tsvCtx.posting_rows

HasCode ← {𝕊 code‿diagnostics: ∨´ 0 ∾ {𝕩.code ≡ code}¨ diagnostics}
AssertFailure ← {𝕊 failed‿expectedCode:
  "error" lib.AssertEq failed.state
  "journal-shadow" lib.AssertEq failed.source_mode
  0 lib.AssertEq ≠ failed.posting_rows
  @ lib.AssertEq failed.context
  lib.Assert 0 < ≠ failed.diagnostics
  lib.Assert HasCode ⟨expectedCode, failed.diagnostics⟩
  # An absent context proves no TSV fallback or downstream period/report result.
  1 lib.AssertEq ({𝕩.context.tbds ⋄ 0}⎊{𝕩⋄1}) failed
}

# Native I/O Catch paths: a missing file and a directory used as a file.
missing ← shadow.Build ⟨base, base ∾ "/missing-shadow.journal", asOf⟩
AssertFailure ⟨missing, "journal_file_read_failed"⟩
0 lib.AssertEq ≠ missing.transactions
unresolvable ← shadow.Build ⟨base, base, asOf⟩
AssertFailure ⟨unresolvable, "journal_file_read_failed"⟩
0 lib.AssertEq ≠ unresolvable.transactions

# Red paths derive from the physical fixture; no Journal document is embedded here.
raw ← loader.ReadRaw journalPath
tempPath ← "/tmp/bqn-ledger-journal-shadow-context-invalid.journal"
ReplaceOnce ← {𝕊 old‿new‿text:
  mask ← old ⍷ text
  hits ← mask / ↕ ≠ mask
  lib.Assert 0 < ≠ hits
  index ← ⊑ hits
  (index ↑ text) ∾ new ∾ (index + ≠ old) ↓ text
}
BuildTemp ← {𝕊 text:
  written ← tempPath •FChars text
  shadow.Build ⟨base, tempPath, asOf⟩
}

invalidHeaderRaw ← ReplaceOnce ⟨"2026-08-01 * Opening balance", "2026-08-01 ? Opening balance", raw⟩
invalidHeader ← BuildTemp invalidHeaderRaw
AssertFailure ⟨invalidHeader, "header_status_invalid"⟩

unsupportedRaw ← raw ∾ (@+10) ∾ "include unsupported.journal" ∾ (@+10)
unsupported ← BuildTemp unsupportedRaw
AssertFailure ⟨unsupported, "unsupported_group"⟩

unbalancedRaw ← ReplaceOnce ⟨"assets:cash        -1100 JPY", "assets:cash        -1099 JPY", raw⟩
unbalanced ← BuildTemp unbalancedRaw
AssertFailure ⟨unbalanced, "event_unbalanced"⟩

unsupportedLayerRaw ← ReplaceOnce ⟨"; layer: actual", "; layer: forecast", raw⟩
unsupportedLayer ← BuildTemp unsupportedLayerRaw
AssertFailure ⟨unsupportedLayer, "layer_unsupported"⟩

unknownAccountRaw ← ReplaceOnce ⟨"account expenses:household", "account expenses:unknown", raw⟩
unknownAccountRaw ↩ ReplaceOnce ⟨"expenses:household   300 JPY", "expenses:unknown       300 JPY", unknownAccountRaw⟩
unknownAccount ← BuildTemp unknownAccountRaw
AssertFailure ⟨unknownAccount, "posting_account_unresolved"⟩
2 lib.AssertEq ≠ unknownAccount.transactions

invalidDateRaw ← ReplaceOnce ⟨"2026-08-03 * Split purchase", "2026-02-30 * Split purchase", raw⟩
invalidDate ← BuildTemp invalidDateRaw
AssertFailure ⟨invalidDate, "unsupported_group"⟩

invalidAmountRaw ← ReplaceOnce ⟨"expenses:food        800 JPY", "expenses:food        8.5 JPY", raw⟩
invalidAmount ← BuildTemp invalidAmountRaw
AssertFailure ⟨invalidAmount, "posting_amount_invalid"⟩

{𝕊: •file.Remove tempPath}⍟(•file.Exists tempPath) @

•Out "test_journal_file_backed_shadow_context.bqn: OK"
