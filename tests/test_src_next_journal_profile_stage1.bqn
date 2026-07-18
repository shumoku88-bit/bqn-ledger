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

unsupported ← Prefix @ ∾ "include another.journal" ∾ lf
CheckFail ⟨unsupported, "unsupported_group"⟩

•Out "test_src_next_journal_profile_stage1.bqn: OK"
