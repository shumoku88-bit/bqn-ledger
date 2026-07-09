#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ctx ← •Import "../src_next/context.bqn"
proj ← •Import "../src_next/projection.bqn"

tab ← @+9
Line ← {𝕊 fields: ∾ fields ∾¨ tab}

ProofSnapshot ← {𝕊 jlines‿plines‿blines:
  {
    journal ⇐ {source_file⇐"journal.tsv", required⇐1, lines⇐jlines},
    plan ⇐ {source_file⇐"plan.tsv", required⇐0, lines⇐plines},
    budget_alloc ⇐ {source_file⇐"budget_alloc.tsv", required⇐0, lines⇐blines},
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

0 lib.AssertEq proj.AuthorizeArithmeticCurrencyProof {state⇐"unsupported", domain⇐"", basis⇐"explicit_source_currency", message⇐"x"}
0 lib.AssertEq proj.AuthorizeArithmeticCurrencyProof {state⇐"unresolved", domain⇐"JPY", basis⇐"legacy_compatibility", message⇐"x"}
0 lib.AssertEq proj.AuthorizeArithmeticCurrencyProof {state⇐"proven", domain⇐"", basis⇐"legacy_compatibility", message⇐"x"}
0 lib.AssertEq proj.AuthorizeArithmeticCurrencyProof {state⇐"proven", domain⇐"USD", basis⇐"legacy_compatibility", message⇐"x"}
0 lib.AssertEq proj.AuthorizeArithmeticCurrencyProof {state⇐"proven", domain⇐"JPY", basis⇐"forged_basis", message⇐"x"}
0 lib.AssertEq proj.AuthorizeArithmeticCurrencyProof {state⇐"proven", basis⇐"legacy_compatibility", message⇐"x"}
0 lib.AssertEq proj.AuthorizeArithmeticCurrencyProof {state⇐"proven", domain⇐"JPY", message⇐"x"}
0 lib.AssertEq proj.AuthorizeArithmeticCurrencyProof "not-a-proof"

•Out "test_src_next_currency_domain_proof.bqn: OK"
