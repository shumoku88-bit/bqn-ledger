#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ctx ← •Import "../src_next/context.bqn"
ak ← •Import "../src_next/account_key.bqn"

tab ← @+9
Line ← {𝕊 fields: ∾ fields ∾¨ tab}
Snapshot ← {𝕊 jlines‿plines‿blines:
  {
    sources ⇐ ⟨
      {source_file⇐"journal.tsv", required⇐1, lines⇐jlines},
      {source_file⇐"plan.tsv", required⇐0, lines⇐plines},
      {source_file⇐"budget_alloc.tsv", required⇐0, lines⇐blines}
    ⟩
  }
}

resolved ← ak.Resolve ⟨
  "assets:bank"∾tab∾"role=asset",
  "expenses:food"∾tab∾"role=expense"
⟩
cycleStart ← "2026-06-15"

CheckSuccess ← {𝕊 result:
  "ok" lib.AssertEq result.state
  0 lib.AssertEq ≠ result.diagnostics
}

CheckError ← {𝕊 result‿stage‿code‿message:
  "error" lib.AssertEq result.state
  0 lib.AssertEq ≠ result.posting_rows
  1 lib.AssertEq ≠ result.diagnostics
  diagnostic ← ⊑ result.diagnostics
  "error" lib.AssertEq diagnostic.severity
  stage lib.AssertEq diagnostic.stage
  code lib.AssertEq diagnostic.code
  message lib.AssertEq diagnostic.message
}

CheckWrapperParity ← {𝕊 result‿built:
  result.arithmetic_currency_proof.state lib.AssertEq built.arithmetic_currency_proof.state
  result.arithmetic_currency_proof.domain lib.AssertEq built.arithmetic_currency_proof.domain
  result.arithmetic_currency_proof.basis lib.AssertEq built.arithmetic_currency_proof.basis
  result.arithmetic_currency_proof.amount_scale lib.AssertEq built.arithmetic_currency_proof.amount_scale
  ({𝕩.delta}¨ result.posting_rows) lib.AssertEq ({𝕩.delta}¨ built.rows)
  ({𝕩.status}¨ result.posting_rows) lib.AssertEq ({𝕩.status}¨ built.rows)
  ({𝕩.message}¨ result.posting_rows) lib.AssertEq ({𝕩.message}¨ built.rows)
}

# 1. Legacy-compatible all-JPY success
legacySnapshot ← Snapshot ⟨
  ⟨Line ⟨"2026-06-15", "legacy", "assets:bank", "expenses:food", "1200"⟩⟩,
  ⟨⟩,
  ⟨⟩
⟩
legacyResult ← ctx.BuildCheckedPostingProjectionFromSnapshot ⟨legacySnapshot, resolved, cycleStart⟩
CheckSuccess legacyResult
"legacy_compatibility" lib.AssertEq legacyResult.arithmetic_currency_proof.basis
"JPY" lib.AssertEq legacyResult.arithmetic_currency_proof.domain
2 lib.AssertEq ≠ legacyResult.posting_rows
1200 lib.AssertEq (⊑ legacyResult.posting_rows).delta
legacyBuilt ← ctx.BuildAuthorizedRowsFromSnapshot ⟨legacySnapshot, resolved, cycleStart⟩
CheckWrapperParity ⟨legacyResult, legacyBuilt⟩

# 2. Explicit all-JPY success
explicitSnapshot ← Snapshot ⟨
  ⟨Line ⟨"2026-06-15", "explicit", "assets:bank", "expenses:food", "42.50", "currency=JPY"⟩⟩,
  ⟨⟩,
  ⟨⟩
⟩
explicitResult ← ctx.BuildCheckedPostingProjectionFromSnapshot ⟨explicitSnapshot, resolved, cycleStart⟩
CheckSuccess explicitResult
"resolved_single_currency" lib.AssertEq explicitResult.arithmetic_currency_proof.basis
"JPY" lib.AssertEq explicitResult.arithmetic_currency_proof.domain
425 lib.AssertEq (⊑ explicitResult.posting_rows).delta
explicitBuilt ← ctx.BuildAuthorizedRowsFromSnapshot ⟨explicitSnapshot, resolved, cycleStart⟩
CheckWrapperParity ⟨explicitResult, explicitBuilt⟩

# 3. Proven all-ILS success
ilsSnapshot ← Snapshot ⟨
  ⟨Line ⟨"2026-06-15", "ils", "assets:bank", "expenses:food", "42.50", "currency=ILS"⟩⟩,
  ⟨⟩,
  ⟨⟩
⟩
ilsResult ← ctx.BuildCheckedPostingProjectionFromSnapshot ⟨ilsSnapshot, resolved, cycleStart⟩
CheckSuccess ilsResult
"resolved_single_currency" lib.AssertEq ilsResult.arithmetic_currency_proof.basis
"ILS" lib.AssertEq ilsResult.arithmetic_currency_proof.domain
425 lib.AssertEq (⊑ ilsResult.posting_rows).delta
ilsBuilt ← ctx.BuildAuthorizedRowsFromSnapshot ⟨ilsSnapshot, resolved, cycleStart⟩
CheckWrapperParity ⟨ilsResult, ilsBuilt⟩

# 4. Empty posting sources preserve compatibility proof semantics
emptySnapshot ← Snapshot ⟨⟨⟩, ⟨⟩, ⟨⟩⟩
emptyResult ← ctx.BuildCheckedPostingProjectionFromSnapshot ⟨emptySnapshot, resolved, cycleStart⟩
CheckSuccess emptyResult
"empty_source_compatibility" lib.AssertEq emptyResult.arithmetic_currency_proof.basis
"JPY" lib.AssertEq emptyResult.arithmetic_currency_proof.domain
0 lib.AssertEq ≠ emptyResult.posting_rows
emptyBuilt ← ctx.BuildAuthorizedRowsFromSnapshot ⟨emptySnapshot, resolved, cycleStart⟩
CheckWrapperParity ⟨emptyResult, emptyBuilt⟩

# 5. Mixed JPY / ILS rejects before posting construction
mixedSnapshot ← Snapshot ⟨
  ⟨
    Line ⟨"2026-06-15", "jpy", "assets:bank", "expenses:food", "100", "currency=JPY"⟩,
    Line ⟨"2026-06-16", "ils", "assets:bank", "expenses:food", "50", "currency=ILS"⟩
  ⟩,
  ⟨⟩,
  ⟨⟩
⟩
mixedResult ← ctx.BuildCheckedPostingProjectionFromSnapshot ⟨mixedSnapshot, resolved, cycleStart⟩
CheckError ⟨mixedResult, "authorization", "arithmetic_currency_proof_rejected", "mixed_currency_domains"⟩

# 6. Unsupported currency metadata rejection
unsupportedSnapshot ← Snapshot ⟨
  ⟨Line ⟨"2026-06-15", "eur", "assets:bank", "expenses:food", "100", "currency=EUR"⟩⟩,
  ⟨⟩,
  ⟨⟩
⟩
unsupportedResult ← ctx.BuildCheckedPostingProjectionFromSnapshot ⟨unsupportedSnapshot, resolved, cycleStart⟩
CheckError ⟨
  unsupportedResult,
  "authorization",
  "arithmetic_currency_proof_rejected",
  "explicit source currency unsupported in Stage 2 minimal runtime slice: journal.tsv row 0: unsupported currency: EUR"
⟩

# 7. Duplicate currency metadata rejection
duplicateSnapshot ← Snapshot ⟨
  ⟨Line ⟨"2026-06-15", "duplicate", "assets:bank", "expenses:food", "100", "currency=JPY", "currency=JPY"⟩⟩,
  ⟨⟩,
  ⟨⟩
⟩
duplicateResult ← ctx.BuildCheckedPostingProjectionFromSnapshot ⟨duplicateSnapshot, resolved, cycleStart⟩
CheckError ⟨
  duplicateResult,
  "authorization",
  "arithmetic_currency_proof_rejected",
  "explicit source currency unsupported in Stage 2 minimal runtime slice: journal.tsv row 0: duplicate currency metadata"
⟩

# 8. Malformed amount rejection
malformedSnapshot ← Snapshot ⟨
  ⟨Line ⟨"2026-06-15", "malformed", "assets:bank", "expenses:food", "12x", "currency=JPY"⟩⟩,
  ⟨⟩,
  ⟨⟩
⟩
malformedResult ← ctx.BuildCheckedPostingProjectionFromSnapshot ⟨malformedSnapshot, resolved, cycleStart⟩
CheckError ⟨
  malformedResult,
  "authorization",
  "arithmetic_currency_proof_rejected",
  "explicit source currency unsupported in Stage 2 minimal runtime slice: journal.tsv row 0: invalid_decimal_syntax"
⟩

# 9. Focused structural evidence / coefficient mismatch seam
legacyEvidence ← legacyResult.row_evidence
legacyArithmetic ← legacyResult.arithmetic_evidence
mismatchedArithmetic ← {
  state ⇐ legacyArithmetic.state,
  domain ⇐ legacyArithmetic.domain,
  amount_scale ⇐ legacyArithmetic.amount_scale,
  normalized_coefficients ⇐ ⟨⟩,
  message ⇐ legacyArithmetic.message
}
mismatchResult ← ctx.BuildCheckedPostingProjectionFromPreparedForTest ⟨legacyEvidence, mismatchedArithmetic, resolved, cycleStart⟩
CheckError ⟨
  mismatchResult,
  "structure",
  "normalized_coefficient_length_mismatch",
  "evidence and normalized coefficients length mismatch"
⟩

# 10. Unknown-account remains a row status, not aggregate failure
unknownSnapshot ← Snapshot ⟨
  ⟨Line ⟨"2026-06-15", "unknown", "assets:missing", "expenses:food", "100"⟩⟩,
  ⟨⟩,
  ⟨⟩
⟩
unknownResult ← ctx.BuildCheckedPostingProjectionFromSnapshot ⟨unknownSnapshot, resolved, cycleStart⟩
CheckSuccess unknownResult
2 lib.AssertEq ≠ unknownResult.posting_rows
⟨"unknown_account", "unknown_account"⟩ lib.AssertEq ({𝕩.status}¨ unknownResult.posting_rows)
⟨"unknown from account: assets:missing", "unknown from account: assets:missing"⟩ lib.AssertEq ({𝕩.message}¨ unknownResult.posting_rows)
unknownBuilt ← ctx.BuildAuthorizedRowsFromSnapshot ⟨unknownSnapshot, resolved, cycleStart⟩
CheckWrapperParity ⟨unknownResult, unknownBuilt⟩

# 11. Invalid date remains a row status, not aggregate failure
invalidDateSnapshot ← Snapshot ⟨
  ⟨Line ⟨"2026-02-30", "invalid-date", "assets:bank", "expenses:food", "100"⟩⟩,
  ⟨⟩,
  ⟨⟩
⟩
invalidDateResult ← ctx.BuildCheckedPostingProjectionFromSnapshot ⟨invalidDateSnapshot, resolved, cycleStart⟩
CheckSuccess invalidDateResult
2 lib.AssertEq ≠ invalidDateResult.posting_rows
⟨"invalid_date", "invalid_date"⟩ lib.AssertEq ({𝕩.status}¨ invalidDateResult.posting_rows)
⟨"invalid date: 2026-02-30", "invalid date: 2026-02-30"⟩ lib.AssertEq ({𝕩.message}¨ invalidDateResult.posting_rows)
invalidDateBuilt ← ctx.BuildAuthorizedRowsFromSnapshot ⟨invalidDateSnapshot, resolved, cycleStart⟩
CheckWrapperParity ⟨invalidDateResult, invalidDateBuilt⟩

•Out "test_src_next_checked_posting_projection.bqn: OK"
