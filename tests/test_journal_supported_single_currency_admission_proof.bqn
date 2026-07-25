#!/usr/bin/env bqn

ak ← •Import "../src_next/account_key.bqn"
admission ← •Import "../src_next/journal_supported_single_currency_admission_for_test.bqn"

lf ← @+10
tab ← @+9
Raw ← {𝕊 lines: ∾ (lines ∾¨ lf) }

resolved ← ak.Resolve ⟨
  "assets:cash-ils" ∾ tab ∾ "role=asset" ∾ tab ∾ "currency=ILS",
  "expenses:food-ils" ∾ tab ∾ "role=expense" ∾ tab ∾ "currency=ILS"
⟩
ilsRaw ← Raw ⟨"commodity ILS"⟩
ils ← admission.Admit ⟨ilsRaw, resolved⟩

•Out "test_journal_supported_single_currency_admission_proof.bqn: COMMODITY CALL OK"
