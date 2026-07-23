#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
parser ← •Import "../src_next/journal_profile_stage1.bqn"
loader ← •Import "../src_next/loader.bqn"
util ← •Import "../src_next/util.bqn"

lf ← @+10

raw ← •FChars "../fixtures/journal-profile-stage0/profile.journal"
result ← parser.Parse raw

"ok" lib.AssertEq result.state
0 lib.AssertEq ≠ result.diagnostics
9 lib.AssertEq ≠ result.accounts
1 lib.AssertEq ≠ result.commodities
5 lib.AssertEq ≠ result.transactions

expectedLayers ← ⟨<"actual", <"plan", <"actual", <"budget", <"actual"⟩
actualLayers ← {<𝕩.layer_name}¨ result.transactions
expectedLayers lib.AssertEq actualLayers

"physical_fallback" lib.AssertEq (0 ⊑ result.transactions).identity_kind
"durable" lib.AssertEq (1 ⊑ result.transactions).identity_kind
"plan-rent-2026-08" lib.AssertEq (1 ⊑ result.transactions).plan_id
"plan-rent-2026-08" lib.AssertEq (2 ⊑ result.transactions).plan_id
"reserve" lib.AssertEq (1 ⊑ result.transactions).execution_envelope
"reserve" lib.AssertEq (2 ⊑ result.transactions).execution_envelope
"allocation-daily-2026-08" lib.AssertEq (3 ⊑ result.transactions).allocation_id
⟨
  "Example Market | groceries and soap",
  "Example Landlord | August rent plan",
  "Example Landlord | August rent paid early",
  "Household | allocate daily budget",
  "Example Lender | loan repayment"
⟩ lib.AssertEq {𝕩.description}¨ result.transactions

expectedPostingCounts ← 3‿2‿2‿2‿3
expectedPostingCounts lib.AssertEq {≠𝕩.postings}¨ result.transactions
{0 lib.AssertEq +´ 0 ∾ {𝕩.delta}¨ 𝕩.postings}¨ result.transactions

matrixLines ← loader.ReadLines "fixtures/journal-profile-stage0/expected-posting-matrix.tsv"
header ← loader.SplitTsvKeepEmpty ⊑ matrixLines
accountKeys ← <¨ 2 ↓ ¯1 ↓ header
expectedMatrix ← {
  fields ← loader.SplitTsvKeepEmpty 𝕩
  util.ToNum¨ 2 ↓ ¯1 ↓ fields
}¨ 1 ↓ matrixLines
actualMatrix ← parser.BuildMatrix ⟨result.transactions, accountKeys⟩
expectedMatrix lib.AssertEq actualMatrix

HasCode ← {𝕊 code‿parseResult:
  ∨´ 0 ∾ {code ≡ 𝕩.code}¨ parseResult.diagnostics
}

CheckFail ← {𝕊 source‿code:
  failed ← parser.Parse source
  "error" lib.AssertEq failed.state
  lib.Assert HasCode ⟨code, failed⟩
}

Prefix ← {𝕊:
  ∾ ⟨
    "commodity JPY", lf, lf,
    "account assets:bank", lf, lf,
    "account expenses:rent", lf, lf
  ⟩
}

missingEventId ← ∾ ⟨
  Prefix @,
  "2026-08-15 ! Rent plan", lf,
  "    ; layer: plan", lf,
  "    ; plan-id: plan-1", lf,
  "    expenses:rent 10 JPY", lf,
  "    assets:bank -10 JPY", lf
⟩
CheckFail ⟨missingEventId, "plan_event_id_missing"⟩

duplicateMetadata ← ∾ ⟨
  Prefix @,
  "2026-08-15 ! Rent plan", lf,
  "    ; event-id: event-1", lf,
  "    ; layer: plan", lf,
  "    ; layer: plan", lf,
  "    ; plan-id: plan-1", lf,
  "    expenses:rent 10 JPY", lf,
  "    assets:bank -10 JPY", lf
⟩
CheckFail ⟨duplicateMetadata, "metadata_duplicate"⟩

unbalanced ← ∾ ⟨
  Prefix @,
  "2026-08-15 * Broken purchase", lf,
  "    expenses:rent 10 JPY", lf,
  "    assets:bank -9 JPY", lf
⟩
CheckFail ⟨unbalanced, "event_unbalanced"⟩

missingHeaderDelimiter ← ∾ ⟨
  Prefix @,
  "2026-08-15 *Missing delimiter", lf,
  "    expenses:rent 10 JPY", lf,
  "    assets:bank -10 JPY", lf
⟩
CheckFail ⟨missingHeaderDelimiter, "header_description_delimiter_missing"⟩

emptyHeaderDescription ← ∾ ⟨
  Prefix @,
  "2026-08-15 * ", lf,
  "    expenses:rent 10 JPY", lf,
  "    assets:bank -10 JPY", lf
⟩
CheckFail ⟨emptyHeaderDescription, "header_description_missing"⟩
lib.Assert ¬HasCode ⟨"header_description_delimiter_missing", parser.Parse emptyHeaderDescription⟩

unsupportedMetadata ← ∾ ⟨
  Prefix @,
  "2026-08-15 * Unsupported metadata", lf,
  "    ; include: another.journal", lf,
  "    expenses:rent 10 JPY", lf,
  "    assets:bank -10 JPY", lf
⟩
CheckFail ⟨unsupportedMetadata, "metadata_unsupported"⟩

# recur and series are an explicit opaque allowlist: their values are preserved
# only in generic transaction.metadata and receive no recurrence interpretation.
opaqueMetadata ← ∾ ⟨
  Prefix @,
  "2026-08-15 * Opaque legacy metadata", lf,
  "    ; recur: synthetic-cycle", lf,
  "    ; series: synthetic-series", lf,
  "    expenses:rent 10 JPY", lf,
  "    assets:bank -10 JPY", lf
⟩
opaqueResult ← parser.Parse opaqueMetadata
"ok" lib.AssertEq opaqueResult.state
0 lib.AssertEq ≠opaqueResult.diagnostics
opaqueTransaction ← ⊑opaqueResult.transactions
⟨"recur","series"⟩ lib.AssertEq {𝕩.key}¨opaqueTransaction.metadata
⟨"synthetic-cycle","synthetic-series"⟩ lib.AssertEq {𝕩.value}¨opaqueTransaction.metadata
"actual" lib.AssertEq opaqueTransaction.layer_name
"" lib.AssertEq opaqueTransaction.txn_id
"" lib.AssertEq opaqueTransaction.plan_id

recurDuplicate ← ∾ ⟨
  Prefix @,
  "2026-08-15 * Duplicate recur", lf,
  "    ; recur: first", lf,
  "    ; recur: second", lf,
  "    expenses:rent 10 JPY", lf,
  "    assets:bank -10 JPY", lf
⟩
CheckFail ⟨recurDuplicate, "metadata_duplicate"⟩

seriesDuplicate ← ∾ ⟨
  Prefix @,
  "2026-08-15 * Duplicate series", lf,
  "    ; series: first", lf,
  "    ; series: second", lf,
  "    expenses:rent 10 JPY", lf,
  "    assets:bank -10 JPY", lf
⟩
CheckFail ⟨seriesDuplicate, "metadata_duplicate"⟩

•Out "test_src_next_journal_profile_stage1.bqn: OK"
