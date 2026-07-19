#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
parser ← •Import "../src_next/journal_profile_stage1.bqn"
adapter ← •Import "../src_next/journal_posting_ir_stage2a.bqn"
context ← •Import "../src_next/context.bqn"
cube ← •Import "../src_next/cube.bqn"
ak ← •Import "../src_next/account_key.bqn"
loader ← •Import "../src_next/loader.bqn"

base ← "fixtures/journal-posting-ir-stage2c"
cycleStart ← "2026-02-01"
dayCount ← 28

resolved ← ak.Resolve loader.ReadLines (base ∾ "/accounts.tsv")
⟨"assets:anonymous", "expenses:anonymous"⟩ lib.AssertEq resolved.accounts
⟨"asset", "expense"⟩ lib.AssertEq resolved.roles

cases ← ⟨
  {
    case_key⇐"invalid_date", stem⇐"invalid-date",
    date⇐"2026-02-30", description⇐"Invalid date movement",
    from_account⇐"assets:anonymous", to_account⇐"expenses:anonymous", amount_text⇐"100"
  },
  {
    case_key⇐"invalid_exact_integer_amount", stem⇐"invalid-exact-integer-amount",
    date⇐"2026-02-20", description⇐"Invalid exact integer amount movement",
    from_account⇐"assets:anonymous", to_account⇐"expenses:anonymous", amount_text⇐"12x"
  },
  {
    case_key⇐"unknown_account", stem⇐"unknown-account",
    date⇐"2026-02-20", description⇐"Unknown account movement",
    from_account⇐"assets:undeclared", to_account⇐"expenses:anonymous", amount_text⇐"100"
  }
⟩

# This is fixture verification, not another source parser. Exact expected lines
# prove that each pair describes the same one-row movement and posting signs.
AssertPairedMovement ← {𝕊 spec:
  journalPath ← base ∾ "/" ∾ spec.stem ∾ ".journal"
  tsvPath ← base ∾ "/" ∾ spec.stem ∾ ".tsv"
  journalLines ← loader.ReadLines journalPath
  tsvLines ← loader.ReadLines tsvPath

  6 lib.AssertEq ≠ journalLines
  "commodity JPY" lib.AssertEq 0 ⊑ journalLines
  "account assets:anonymous" lib.AssertEq 1 ⊑ journalLines
  "account expenses:anonymous" lib.AssertEq 2 ⊑ journalLines
  (spec.date ∾ " * " ∾ spec.description) lib.AssertEq 3 ⊑ journalLines
  ("    " ∾ spec.to_account ∾ " " ∾ spec.amount_text ∾ " JPY") lib.AssertEq 4 ⊑ journalLines
  ("    " ∾ spec.from_account ∾ " -" ∾ spec.amount_text ∾ " JPY") lib.AssertEq 5 ⊑ journalLines

  1 lib.AssertEq ≠ tsvLines
  fields ← loader.SplitTsvKeepEmpty ⊑ tsvLines
  5 lib.AssertEq ≠ fields
  spec.date lib.AssertEq 0 ⊑ fields
  spec.from_account lib.AssertEq 2 ⊑ fields
  spec.to_account lib.AssertEq 3 ⊑ fields
  spec.amount_text lib.AssertEq 4 ⊑ fields
}

SnapshotFor ← {𝕊 lines:
  {sources⇐⟨
    {source_file⇐"journal.tsv", required⇐1, lines⇐lines},
    {source_file⇐"plan.tsv", required⇐0, lines⇐⟨⟩},
    {source_file⇐"budget_alloc.tsv", required⇐0, lines⇐⟨⟩}
  ⟩}
}

OkRows ← {𝕊 rows: ({𝕩.status ≡ "ok"}¨ rows) / rows}
RejectedRows ← {𝕊 rows: ({𝕩.status ≢ "ok"}¨ rows) / rows}

# The observation carrier is deliberately local to this focused test. Its
# eleven fields normalize only structural evidence, never diagnostic meanings.
MakeObservation ← {𝕊 caseKey‿sourceKind‿sourceState‿admittedCount‿rows‿diagnostics‿downstreamCount‿sourceCodes:
  okRows ← OkRows rows
  rejectedRows ← RejectedRows rows
  {
    case_key⇐caseKey,
    source_kind⇐sourceKind,
    source_state⇐sourceState,
    admitted_transaction_count⇐admittedCount,
    posting_row_count⇐≠ rows,
    ok_posting_count⇐≠ okRows,
    rejected_posting_count⇐≠ rejectedRows,
    diagnostic_count⇐≠ diagnostics,
    has_rejection_evidence⇐(0 < ≠ diagnostics) ∨ 0 < ≠ rejectedRows,
    downstream_admitted_count⇐downstreamCount,
    source_codes⇐sourceCodes
  }
}

CarrierFields ← {𝕊 observation: ⟨
  <observation.case_key, <observation.source_kind, <observation.source_state,
  observation.admitted_transaction_count, observation.posting_row_count,
  observation.ok_posting_count, observation.rejected_posting_count,
  observation.diagnostic_count, observation.has_rejection_evidence,
  observation.downstream_admitted_count, <observation.source_codes
⟩}

ObserveCase ← {𝕊 spec:
  AssertPairedMovement spec

  raw ← •FChars ("../" ∾ base ∾ "/" ∾ spec.stem ∾ ".journal")
  parsed ← parser.Parse raw
  journalPosting ← adapter.Build ⟨parsed.transactions, resolved, cycleStart⟩
  journalCodes ← {<𝕩.code}¨ parsed.diagnostics
  journalObservation ← MakeObservation ⟨
    spec.case_key, "journal", parsed.state, ≠ parsed.transactions,
    journalPosting.posting_rows, parsed.diagnostics,
    ≠ journalPosting.posting_rows, journalCodes
  ⟩

  tsvLines ← loader.ReadLines (base ∾ "/" ∾ spec.stem ∾ ".tsv")
  legacy ← context.BuildCheckedPostingProjectionFromSnapshot ⟨SnapshotFor tsvLines, resolved, cycleStart⟩
  materialized ← cube.Materialize ⟨legacy.posting_rows, dayCount, resolved.count⟩
  topCodes ← {<𝕩.code}¨ legacy.diagnostics
  rowStatuses ← {<𝕩.status}¨ legacy.posting_rows
  legacyCodes ← topCodes ∾ rowStatuses
  legacyObservation ← MakeObservation ⟨
    spec.case_key, "legacy_tsv", legacy.state, 0,
    legacy.posting_rows, legacy.diagnostics,
    ≠ materialized.valid_rows, legacyCodes
  ⟩

  {
    spec⇐spec,
    parsed⇐parsed,
    journal_posting⇐journalPosting,
    journal_observation⇐journalObservation,
    legacy⇐legacy,
    materialized⇐materialized,
    legacy_observation⇐legacyObservation
  }
}

results ← ObserveCase¨ cases

# Structural parity is deliberately weaker than state/code/row-count equality.
{𝕊 result:
  journal ← result.journal_observation
  legacy ← result.legacy_observation

  11 lib.AssertEq ≠ CarrierFields journal
  11 lib.AssertEq ≠ CarrierFields legacy
  "journal" lib.AssertEq journal.source_kind
  "legacy_tsv" lib.AssertEq legacy.source_kind

  0 lib.AssertEq journal.ok_posting_count
  0 lib.AssertEq legacy.ok_posting_count
  1 lib.AssertEq journal.has_rejection_evidence
  1 lib.AssertEq legacy.has_rejection_evidence
  0 lib.AssertEq journal.downstream_admitted_count
  0 lib.AssertEq legacy.downstream_admitted_count
  0 lib.AssertEq journal.admitted_transaction_count
  lib.Assert 0 < ≠ journal.source_codes
  lib.Assert 0 < ≠ legacy.source_codes

  # No successful delta, account total, expense total, or Cube value leaks.
  0 lib.AssertEq +´ 0 ∾ {𝕩.delta}¨ OkRows result.journal_posting.posting_rows
  0 lib.AssertEq +´ 0 ∾ {𝕩.delta}¨ OkRows result.legacy.posting_rows
  0 lib.AssertEq result.materialized.valid_total_delta
  (4 ⥊ 0) lib.AssertEq result.materialized.layer_totals_vec
  (resolved.count ⥊ 0) lib.AssertEq result.materialized.ak_totals
  (resolved.count ⥊ 0) lib.AssertEq result.materialized.actual_account_totals
  0 lib.AssertEq result.materialized.actual_expense_total

  # If legacy rejected rows exist, both their status and message stay visible.
  rejected ← RejectedRows result.legacy.posting_rows
  legacy.rejected_posting_count lib.AssertEq ≠ rejected
  lib.Assert ∧´ {0 < ≠ 𝕩.status}¨ rejected
  lib.Assert ∧´ {0 < ≠ 𝕩.message}¨ rejected
}¨ results

invalidDate ← 0 ⊑ results
"error" lib.AssertEq invalidDate.parsed.state
0 lib.AssertEq ≠ invalidDate.parsed.transactions
⟨<"unsupported_group"⟩ lib.AssertEq invalidDate.journal_observation.source_codes
"ok" lib.AssertEq invalidDate.legacy.state
2 lib.AssertEq ≠ invalidDate.legacy.posting_rows
⟨<"invalid_date", <"invalid_date"⟩ lib.AssertEq {<𝕩.status}¨ invalidDate.legacy.posting_rows
0 lib.AssertEq ≠ invalidDate.legacy.diagnostics
0 lib.AssertEq ≠ invalidDate.materialized.valid_rows
2 lib.AssertEq ≠ invalidDate.materialized.skipped_rows

invalidAmount ← 1 ⊑ results
"error" lib.AssertEq invalidAmount.parsed.state
0 lib.AssertEq ≠ invalidAmount.parsed.transactions
⟨
  <"posting_amount_invalid", <"posting_amount_zero",
  <"posting_amount_invalid", <"posting_amount_zero", <"posting_missing"
⟩ lib.AssertEq invalidAmount.journal_observation.source_codes
0 lib.AssertEq ≠ invalidAmount.journal_posting.posting_rows
"error" lib.AssertEq invalidAmount.legacy.state
0 lib.AssertEq ≠ invalidAmount.legacy.posting_rows
1 lib.AssertEq ≠ invalidAmount.legacy.diagnostics
"arithmetic_currency_proof_rejected" lib.AssertEq (⊑ invalidAmount.legacy.diagnostics).code
⟨<"arithmetic_currency_proof_rejected"⟩ lib.AssertEq invalidAmount.legacy_observation.source_codes
0 lib.AssertEq ≠ invalidAmount.materialized.valid_rows
0 lib.AssertEq ≠ invalidAmount.materialized.skipped_rows
0 lib.AssertEq ≠ ({(𝕩.status ≡ "ok") ∧ 𝕩.delta = 0}¨ invalidAmount.legacy.posting_rows) / invalidAmount.legacy.posting_rows

unknownAccount ← 2 ⊑ results
"error" lib.AssertEq unknownAccount.parsed.state
0 lib.AssertEq ≠ unknownAccount.parsed.transactions
⟨<"posting_account_unknown", <"event_unbalanced"⟩ lib.AssertEq unknownAccount.journal_observation.source_codes
0 lib.AssertEq ≠ unknownAccount.journal_posting.posting_rows
"ok" lib.AssertEq unknownAccount.legacy.state
2 lib.AssertEq ≠ unknownAccount.legacy.posting_rows
⟨<"unknown_account", <"unknown_account"⟩ lib.AssertEq {<𝕩.status}¨ unknownAccount.legacy.posting_rows
0 lib.AssertEq ≠ unknownAccount.legacy.diagnostics
0 lib.AssertEq ≠ unknownAccount.materialized.valid_rows
2 lib.AssertEq ≠ unknownAccount.materialized.skipped_rows

•Out "test_journal_posting_ir_comparable_rejection_stage2c.bqn: OK"
