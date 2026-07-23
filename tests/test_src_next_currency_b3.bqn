#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ctx ← •Import "../src_next/context.bqn"
proj ← •Import "../src_next/projection.bqn"
arith ← •Import "../src_next/currency_arithmetic.bqn"
ak ← •Import "../src_next/account_key.bqn"
loader ← •Import "../src_next/loader.bqn"

tab ← @+9
Line ← {𝕊 fields: ∾ fields ∾¨ tab}

ProofSnapshot ← {𝕊 planLines‿budgetLines‿moreBudgetLines:
  {sources ⇐ ⟨
    {source_file⇐"plan.tsv", required⇐0, lines⇐planLines},
    {source_file⇐"budget_alloc.tsv", required⇐0, lines⇐budgetLines∾moreBudgetLines}
  ⟩}
}

# Exact-decimal non-actual TSV projection remains covered independently of the
# canonical native Journal actual source.
resolved ← ak.Resolve loader.ReadLines "fixtures/src-next-golden/accounts.tsv"

# ── Per-case non-actual snapshot posting tests ─────────────

# 1. Legacy JPY regression (scale 0, deltas unchanged)
legacySnap ← ProofSnapshot ⟨⟨Line ⟨"2026-06-15", "legacy", "assets:bank", "expenses:food", "1200"⟩⟩, ⟨⟩, ⟨⟩⟩
legacyBuilt ← ctx.BuildAuthorizedRowsFromSnapshot ⟨legacySnap, resolved, "2026-06-15"⟩
"proven" lib.AssertEq legacyBuilt.arithmetic_currency_proof.state
"JPY" lib.AssertEq legacyBuilt.arithmetic_currency_proof.domain
"legacy_compatibility" lib.AssertEq legacyBuilt.arithmetic_currency_proof.basis
0 lib.AssertEq legacyBuilt.arithmetic_currency_proof.amount_scale
debits1 ← (({𝕩.side}¨ legacyBuilt.rows) ≡¨ <"debit") / legacyBuilt.rows
1200 lib.AssertEq (⊑ debits1).delta

# 2. Empty-source regression
emptySnap ← ProofSnapshot ⟨⟨⟩, ⟨⟩, ⟨⟩⟩
emptyBuilt ← ctx.BuildAuthorizedRowsFromSnapshot ⟨emptySnap, resolved, "2026-06-15"⟩
"proven" lib.AssertEq emptyBuilt.arithmetic_currency_proof.state
"JPY" lib.AssertEq emptyBuilt.arithmetic_currency_proof.domain
"empty_source_compatibility" lib.AssertEq emptyBuilt.arithmetic_currency_proof.basis
0 lib.AssertEq emptyBuilt.arithmetic_currency_proof.amount_scale
0 lib.AssertEq ≠ emptyBuilt.rows

# 3. Implicit decimal JPY (legacy basis, max scale, normalized deltas)
implicitSnap ← ProofSnapshot ⟨⟨Line ⟨"2026-06-15", "dec", "assets:bank", "expenses:food", "42.50"⟩⟩, ⟨⟩, ⟨⟩⟩
implicitBuilt ← ctx.BuildAuthorizedRowsFromSnapshot ⟨implicitSnap, resolved, "2026-06-15"⟩
"proven" lib.AssertEq implicitBuilt.arithmetic_currency_proof.state
"JPY" lib.AssertEq implicitBuilt.arithmetic_currency_proof.domain
"legacy_compatibility" lib.AssertEq implicitBuilt.arithmetic_currency_proof.basis
1 lib.AssertEq implicitBuilt.arithmetic_currency_proof.amount_scale
debits2 ← (({𝕩.side}¨ implicitBuilt.rows) ≡¨ <"debit") / implicitBuilt.rows
425 lib.AssertEq (⊑ debits2).delta

# 4. Explicit JPY decimal (resolved basis, admitted, normalized deltas)
explicitSnap ← ProofSnapshot ⟨⟨Line ⟨"2026-06-15", "dec", "assets:bank", "expenses:food", "42.50", "currency=JPY"⟩⟩, ⟨⟩, ⟨⟩⟩
explicitBuilt ← ctx.BuildAuthorizedRowsFromSnapshot ⟨explicitSnap, resolved, "2026-06-15"⟩
"proven" lib.AssertEq explicitBuilt.arithmetic_currency_proof.state
"JPY" lib.AssertEq explicitBuilt.arithmetic_currency_proof.domain
"resolved_single_currency" lib.AssertEq explicitBuilt.arithmetic_currency_proof.basis
1 lib.AssertEq explicitBuilt.arithmetic_currency_proof.amount_scale
debits3 ← (({𝕩.side}¨ explicitBuilt.rows) ≡¨ <"debit") / explicitBuilt.rows
425 lib.AssertEq (⊑ debits3).delta

# 5. Missing + Explicit JPY (resolved basis, admitted)
mixedSnap ← ProofSnapshot ⟨
  ⟨
    Line ⟨"2026-06-15", "legacy", "assets:bank", "expenses:food", "1200"⟩,
    Line ⟨"2026-06-16", "explicit", "assets:bank", "expenses:food", "42.50", "currency=JPY"⟩
  ⟩,
  ⟨⟩,
  ⟨⟩
⟩
mixedBuilt ← ctx.BuildAuthorizedRowsFromSnapshot ⟨mixedSnap, resolved, "2026-06-15"⟩
"proven" lib.AssertEq mixedBuilt.arithmetic_currency_proof.state
"JPY" lib.AssertEq mixedBuilt.arithmetic_currency_proof.domain
"resolved_single_currency" lib.AssertEq mixedBuilt.arithmetic_currency_proof.basis
1 lib.AssertEq mixedBuilt.arithmetic_currency_proof.amount_scale
debits4 ← (({𝕩.side}¨ mixedBuilt.rows) ≡¨ <"debit") / mixedBuilt.rows
12000 lib.AssertEq (0 ⊑ debits4).delta # 1200 normalized to scale 1
425 lib.AssertEq (1 ⊑ debits4).delta # 42.50 normalized to scale 1

# 6. All-ILS proof resolves and the Slice C authorizer admits it
ilsSnap ← ProofSnapshot ⟨⟨Line ⟨"2026-06-15", "ils", "assets:bank", "expenses:food", "42.50", "currency=ILS"⟩⟩, ⟨⟩, ⟨⟩⟩
ilsEv ← ctx.BuildRowEvidenceFromSnapshot ilsSnap
ilsProof ← ctx.ResolveArithmeticCurrencyProof ⟨ilsEv, arith.Build ilsEv⟩
"proven" lib.AssertEq ilsProof.state
"ILS" lib.AssertEq ilsProof.domain
"resolved_single_currency" lib.AssertEq ilsProof.basis
1 lib.AssertEq ilsProof.amount_scale
1 lib.AssertEq proj.AuthorizeArithmeticCurrencyProof ilsProof

# 7. Mixed JPY/ILS fails closed
mixedCurrencySnap ← ProofSnapshot ⟨
  ⟨
    Line ⟨"2026-06-15", "jpy", "assets:bank", "expenses:food", "100", "currency=JPY"⟩,
    Line ⟨"2026-06-16", "ils", "assets:bank", "expenses:food", "42.50", "currency=ILS"⟩
  ⟩,
  ⟨⟩,
  ⟨⟩
⟩
mixedCurrencyEv ← ctx.BuildRowEvidenceFromSnapshot mixedCurrencySnap
mixedCurrencyProof ← ctx.ResolveArithmeticCurrencyProof ⟨mixedCurrencyEv, arith.Build mixedCurrencyEv⟩
"unsupported" lib.AssertEq mixedCurrencyProof.state
"" lib.AssertEq mixedCurrencyProof.domain
"" lib.AssertEq mixedCurrencyProof.basis
"mixed_currency_domains" lib.AssertEq mixedCurrencyProof.message

# 8. Invalid row fails closed
invalidRowSnap ← ProofSnapshot ⟨⟨Line ⟨"2026-06-15", "invalid", "assets:bank", "expenses:food", "12x", "currency=JPY"⟩⟩, ⟨⟩, ⟨⟩⟩
invalidRowEv ← ctx.BuildRowEvidenceFromSnapshot invalidRowSnap
invalidRowProof ← ctx.ResolveArithmeticCurrencyProof ⟨invalidRowEv, arith.Build invalidRowEv⟩
"unsupported" lib.AssertEq invalidRowProof.state
"explicit_source_currency" lib.AssertEq invalidRowProof.basis
1 lib.AssertEq ∨´ "invalid_decimal_syntax" ⍷ invalidRowProof.message

# 9. Normalized overflow fails closed
overflowSnap ← ProofSnapshot ⟨
  ⟨
    Line ⟨"2026-06-15", "huge", "assets:bank", "expenses:food", "900719925474099"⟩, # scale 0
    Line ⟨"2026-06-16", "dec", "assets:bank", "expenses:food", "0.05"⟩ # scale 2, forces scale-up of huge by 100
  ⟩,
  ⟨⟩,
  ⟨⟩
⟩
overflowEv ← ctx.BuildRowEvidenceFromSnapshot overflowSnap
overflowProof ← ctx.ResolveArithmeticCurrencyProof ⟨overflowEv, arith.Build overflowEv⟩
"unsupported" lib.AssertEq overflowProof.state
"normalized_amount_out_of_exact_range" lib.AssertEq overflowProof.message

# 10. Evidence/coefficient alignment (multiple non-sorted amounts across sources)
alignSnap ← ProofSnapshot ⟨
  ⟨
    Line ⟨"2026-06-15", "j1", "assets:bank", "expenses:food", "42.50", "currency=JPY"⟩,
    Line ⟨"2026-06-17", "j2", "assets:bank", "expenses:food", "1200", "currency=JPY"⟩
  ⟩,
  ⟨
    Line ⟨"2026-06-16", "p1", "assets:bank", "expenses:food", "0.05", "currency=JPY"⟩
  ⟩,
  ⟨⟩
⟩
alignBuilt ← ctx.BuildAuthorizedRowsFromSnapshot ⟨alignSnap, resolved, "2026-06-15"⟩
debits5 ← (({𝕩.side}¨ alignBuilt.rows) ≡¨ <"debit") / alignBuilt.rows
# Check output order: two plan rows followed by one budget row.
# Max scale is 2; expected normalized: 4250, 120000, 5.
4250 lib.AssertEq (0 ⊑ debits5).delta
"plan.tsv" lib.AssertEq (0 ⊑ debits5).source_file
120000 lib.AssertEq (1 ⊑ debits5).delta
"plan.tsv" lib.AssertEq (1 ⊑ debits5).source_file
5 lib.AssertEq (2 ⊑ debits5).delta
"budget_alloc.tsv" lib.AssertEq (2 ⊑ debits5).source_file

# 11. Proof authorizer boundary cases
0 lib.AssertEq proj.AuthorizeArithmeticCurrencyProof {state⇐"proven", domain⇐"JPY", basis⇐"legacy_compatibility", message⇐""} # missing scale
0 lib.AssertEq proj.AuthorizeArithmeticCurrencyProof {state⇐"proven", domain⇐"JPY", basis⇐"legacy_compatibility", amount_scale⇐¯1, message⇐""} # negative scale
0 lib.AssertEq proj.AuthorizeArithmeticCurrencyProof {state⇐"proven", domain⇐"JPY", basis⇐"legacy_compatibility", amount_scale⇐1.5, message⇐""} # fractional scale
0 lib.AssertEq proj.AuthorizeArithmeticCurrencyProof {state⇐"proven", domain⇐"JPY", basis⇐"legacy_compatibility", amount_scale⇐"2", message⇐""} # string scale
0 lib.AssertEq proj.AuthorizeArithmeticCurrencyProof {state⇐"proven", domain⇐"JPY", basis⇐"empty_source_compatibility", amount_scale⇐1, message⇐""} # wrong empty-source scale
0 lib.AssertEq proj.AuthorizeArithmeticCurrencyProof {state⇐"proven", domain⇐"JPY", basis⇐"forged_basis", amount_scale⇐0, message⇐""} # forged basis
1 lib.AssertEq proj.AuthorizeArithmeticCurrencyProof {state⇐"proven", domain⇐"ILS", basis⇐"resolved_single_currency", amount_scale⇐0, message⇐""} # checked ILS domain
0 lib.AssertEq proj.AuthorizeArithmeticCurrencyProof {state⇐"proven", domain⇐"ILS", basis⇐"legacy_compatibility", amount_scale⇐0, message⇐""} # impossible ILS legacy basis
0 lib.AssertEq proj.AuthorizeArithmeticCurrencyProof {state⇐"proven", domain⇐"ILS", basis⇐"empty_source_compatibility", amount_scale⇐0, message⇐""} # impossible ILS empty basis

•Out "test_src_next_currency_b3.bqn: OK"
