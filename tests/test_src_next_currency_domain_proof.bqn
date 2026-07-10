#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ctx ← •Import "../src_next/context.bqn"
proj ← •Import "../src_next/projection.bqn"

tab ← @+9
Line ← {𝕊 fields: ∾ fields ∾¨ tab}

ProofSnapshot ← {𝕊 jlines‿plines‿blines:
  {
    sources ⇐ ⟨
      {source_file⇐"journal.tsv", required⇐1, lines⇐jlines},
      {source_file⇐"plan.tsv", required⇐0, lines⇐plines},
      {source_file⇐"budget_alloc.tsv", required⇐0, lines⇐blines}
    ⟩
  }
}

legacy ← ctx.BuildContext "fixtures/src-next-golden"
"proven" lib.AssertEq legacy.arithmetic_currency_proof.state
"JPY" lib.AssertEq legacy.arithmetic_currency_proof.domain
"legacy_compatibility" lib.AssertEq legacy.arithmetic_currency_proof.basis
1 lib.AssertEq proj.AuthorizeArithmeticCurrencyProof legacy.arithmetic_currency_proof
1 lib.AssertEq 0 < ≠ legacy.posting_rows

empty ← ctx.BuildContext "fixtures/src-next-empty-projection"
"proven" lib.AssertEq empty.arithmetic_currency_proof.state
"JPY" lib.AssertEq empty.arithmetic_currency_proof.domain
"empty_source_compatibility" lib.AssertEq empty.arithmetic_currency_proof.basis
1 lib.AssertEq proj.AuthorizeArithmeticCurrencyProof empty.arithmetic_currency_proof
0 lib.AssertEq ≠ empty.posting_rows

explicitJournal ← ctx.ResolveArithmeticCurrencyProof ProofSnapshot ⟨⟨Line ⟨"2026-06-15", "memo", "assets:bank", "expenses:food", "100", "currency=JPY"⟩⟩, ⟨⟩, ⟨⟩⟩
"unsupported" lib.AssertEq explicitJournal.state
"" lib.AssertEq explicitJournal.domain
"explicit_source_currency" lib.AssertEq explicitJournal.basis
0 lib.AssertEq proj.AuthorizeArithmeticCurrencyProof explicitJournal

explicitPlan ← ctx.ResolveArithmeticCurrencyProof ProofSnapshot ⟨⟨Line ⟨"2026-06-15", "memo", "assets:bank", "expenses:food", "100"⟩⟩, ⟨Line ⟨"2026-06-16", "plan", "assets:bank", "expenses:food", "20", "currency=USD"⟩⟩, ⟨⟩⟩
"unsupported" lib.AssertEq explicitPlan.state
"explicit_source_currency" lib.AssertEq explicitPlan.basis

explicitBudget ← ctx.ResolveArithmeticCurrencyProof ProofSnapshot ⟨⟨Line ⟨"2026-06-15", "memo", "assets:bank", "expenses:food", "100"⟩⟩, ⟨⟩, ⟨Line ⟨"2026-06-16", "budget", "assets:bank", "budget:food", "20", "currency="⟩⟩⟩
"unsupported" lib.AssertEq explicitBudget.state
"explicit_source_currency" lib.AssertEq explicitBudget.basis

precision ← ctx.ResolveArithmeticCurrencyProof ProofSnapshot ⟨
  ⟨
    Line ⟨"2026-06-15", "memo currency=JPY", "assets:bank", "expenses:food", "100"⟩,
    Line ⟨"2026-06-16", "memo", "assets:bank", "expenses:food", "100", "currency_hint=JPY"⟩,
    Line ⟨"2026-06-17", "memo", "assets:bank", "expenses:food", "100", "note=currency=JPY"⟩
  ⟩,
  ⟨⟩,
  ⟨⟩
⟩
"proven" lib.AssertEq precision.state
"JPY" lib.AssertEq precision.domain
"legacy_compatibility" lib.AssertEq precision.basis
1 lib.AssertEq proj.AuthorizeArithmeticCurrencyProof precision

# The canonical snapshot source representation is sources. Extra legacy-looking
# fields must not become a second projection input that can diverge from proof input.
inconsistent ← {
  journal ⇐ {source_file⇐"journal.tsv", required⇐1, lines⇐⟨Line ⟨"2026-06-15", "dirty", "assets:bank", "expenses:food", "999", "currency=USD"⟩⟩},
  sources ⇐ ⟨
    {source_file⇐"journal.tsv", required⇐1, lines⇐⟨Line ⟨"2026-06-15", "clean", "assets:bank", "expenses:food", "100"⟩⟩},
    {source_file⇐"plan.tsv", required⇐0, lines⇐⟨⟩},
    {source_file⇐"budget_alloc.tsv", required⇐0, lines⇐⟨⟩}
  ⟩
}
inconsistentBuilt ← ctx.BuildAuthorizedRowsFromSnapshot ⟨inconsistent, legacy.resolved, legacy.cy.start⟩
"proven" lib.AssertEq inconsistentBuilt.arithmetic_currency_proof.state
debits ← (({𝕩.side}¨ inconsistentBuilt.rows) ≡¨ <"debit") / inconsistentBuilt.rows
100 lib.AssertEq (⊑ debits).delta

0 lib.AssertEq proj.AuthorizeArithmeticCurrencyProof {state⇐"unsupported", domain⇐"", basis⇐"explicit_source_currency", message⇐"x"}
0 lib.AssertEq proj.AuthorizeArithmeticCurrencyProof {state⇐"unresolved", domain⇐"JPY", basis⇐"legacy_compatibility", message⇐"x"}
0 lib.AssertEq proj.AuthorizeArithmeticCurrencyProof {state⇐"proven", domain⇐"", basis⇐"legacy_compatibility", message⇐"x"}
0 lib.AssertEq proj.AuthorizeArithmeticCurrencyProof {state⇐"proven", domain⇐"USD", basis⇐"legacy_compatibility", message⇐"x"}
0 lib.AssertEq proj.AuthorizeArithmeticCurrencyProof {state⇐"proven", domain⇐"JPY", basis⇐"forged_basis", message⇐"x"}
0 lib.AssertEq proj.AuthorizeArithmeticCurrencyProof {domain⇐"JPY", basis⇐"legacy_compatibility", message⇐"message mentions state"}
0 lib.AssertEq proj.AuthorizeArithmeticCurrencyProof {state⇐"proven", basis⇐"legacy_compatibility", message⇐"message mentions domain"}
0 lib.AssertEq proj.AuthorizeArithmeticCurrencyProof {state⇐"proven", domain⇐"JPY", message⇐"message mentions basis"}
0 lib.AssertEq proj.AuthorizeArithmeticCurrencyProof {state⇐"proven", basis⇐"legacy_compatibility", message⇐"x"}
0 lib.AssertEq proj.AuthorizeArithmeticCurrencyProof {state⇐"proven", domain⇐"JPY", message⇐"x"}
0 lib.AssertEq proj.AuthorizeArithmeticCurrencyProof "not-a-proof"

# Slice B1 Row Ingestion and Pre-Gate Row Evidence tests
CheckRowEvidence ← {𝕊 args:
  line‿expectedCurrency‿expectedProvenance‿expectedState‿expectedCoef‿expectedScale ← args
  snapshot ← ProofSnapshot ⟨⟨line⟩, ⟨⟩, ⟨⟩⟩
  ev ← ⊑ ctx.BuildRowEvidenceFromSnapshot snapshot
  expectedCurrency lib.AssertEq ev.currency
  expectedProvenance lib.AssertEq ev.provenance
  expectedState lib.AssertEq ev.state
  expectedCoef lib.AssertEq ev.parsed.coefficient
  expectedScale lib.AssertEq ev.parsed.scale
  1
}

CheckProofGateFail ← {𝕊 args:
  line‿expectedMsgSubstring ← args
  snapshot ← ProofSnapshot ⟨⟨line⟩, ⟨⟩, ⟨⟩⟩
  proof ← ctx.ResolveArithmeticCurrencyProof snapshot
  "unsupported" lib.AssertEq proof.state
  1 lib.AssertEq ∨´ expectedMsgSubstring ⍷ proof.message
  1
}

# 1. Legacy integer JPY success
CheckRowEvidence ⟨Line ⟨"2026-06-15", "memo", "assets:bank", "expenses:food", "1200"⟩, "JPY", "legacy_compatibility", "ok", 1200, 0⟩

# 2. Explicit JPY decimal internal evidence (fails proof gate)
CheckRowEvidence ⟨Line ⟨"2026-06-15", "memo", "assets:bank", "expenses:food", "12.34", "currency=JPY"⟩, "JPY", "explicit", "ok", 1234, 2⟩
CheckProofGateFail ⟨Line ⟨"2026-06-15", "memo", "assets:bank", "expenses:food", "12.34", "currency=JPY"⟩, "explicit source currency unsupported"⟩

# 3. Explicit ILS decimal internal evidence (fails proof gate)
CheckRowEvidence ⟨Line ⟨"2026-06-15", "memo", "assets:bank", "expenses:food", "42.50", "currency=ILS"⟩, "ILS", "explicit", "ok", 425, 1⟩
CheckProofGateFail ⟨Line ⟨"2026-06-15", "memo", "assets:bank", "expenses:food", "42.50", "currency=ILS"⟩, "explicit source currency unsupported"⟩

# 4. Implicit JPY decimal (fails proof gate due to scale > 0)
CheckRowEvidence ⟨Line ⟨"2026-06-15", "memo", "assets:bank", "expenses:food", "12.34"⟩, "JPY", "legacy_compatibility", "ok", 1234, 2⟩
CheckProofGateFail ⟨Line ⟨"2026-06-15", "memo", "assets:bank", "expenses:food", "12.34"⟩, "explicit source currency unsupported"⟩

# 5. Explicit JPY integer (fails proof gate because metadata is explicit)
CheckRowEvidence ⟨Line ⟨"2026-06-15", "memo", "assets:bank", "expenses:food", "1200", "currency=JPY"⟩, "JPY", "explicit", "ok", 1200, 0⟩
CheckProofGateFail ⟨Line ⟨"2026-06-15", "memo", "assets:bank", "expenses:food", "1200", "currency=JPY"⟩, "explicit source currency unsupported"⟩

# 6. Duplicate currency metadata (fails at row evidence stage)
CheckRowEvidence ⟨Line ⟨"2026-06-15", "memo", "assets:bank", "expenses:food", "1200", "currency=JPY", "currency=JPY"⟩, "JPY", "explicit", "error", 1200, 0⟩
CheckProofGateFail ⟨Line ⟨"2026-06-15", "memo", "assets:bank", "expenses:food", "1200", "currency=JPY", "currency=JPY"⟩, "duplicate currency metadata"⟩

# 7. Unsupported currency (fails at row evidence stage)
CheckRowEvidence ⟨Line ⟨"2026-06-15", "memo", "assets:bank", "expenses:food", "1200", "currency=USD"⟩, "JPY", "explicit", "error", 1200, 0⟩
CheckProofGateFail ⟨Line ⟨"2026-06-15", "memo", "assets:bank", "expenses:food", "1200", "currency=USD"⟩, "unsupported currency: USD"⟩

# 8. Invalid decimal syntax (propagates and fails gate on explicit currency)
CheckRowEvidence ⟨Line ⟨"2026-06-15", "memo", "assets:bank", "expenses:food", "12x", "currency=JPY"⟩, "JPY", "explicit", "error", ⟨⟩, ⟨⟩⟩
CheckProofGateFail ⟨Line ⟨"2026-06-15", "memo", "assets:bank", "expenses:food", "12x", "currency=JPY"⟩, "invalid_decimal_syntax"⟩

# 9. Parsed coefficient range failure (propagates and fails gate on explicit currency)
CheckRowEvidence ⟨Line ⟨"2026-06-15", "memo", "assets:bank", "expenses:food", "9007199254740993", "currency=JPY"⟩, "JPY", "explicit", "error", ⟨⟩, ⟨⟩⟩
CheckProofGateFail ⟨Line ⟨"2026-06-15", "memo", "assets:bank", "expenses:food", "9007199254740993", "currency=JPY"⟩, "amount_out_of_exact_range"⟩

# 10. Empty snapshot regression
emptyProof ← ctx.ResolveArithmeticCurrencyProof ProofSnapshot ⟨⟨⟩, ⟨⟩, ⟨⟩⟩
"proven" lib.AssertEq emptyProof.state
"empty_source_compatibility" lib.AssertEq emptyProof.basis

•Out "test_src_next_currency_domain_proof.bqn: OK"

