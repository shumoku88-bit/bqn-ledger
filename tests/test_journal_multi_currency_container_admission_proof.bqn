#!/usr/bin/env bqn

ak ← •Import "../src_next/account_key.bqn"
container ← •Import "../src_next/journal_multi_currency_container_admission_for_test.bqn"

lf ← @+10
tab ← @+9
Raw ← {𝕊 lines: ∾ (lines ∾¨ lf) }

resolved ← ak.Resolve ⟨
  "assets:cash-ils" ∾ tab ∾ "role=asset" ∾ tab ∾ "currency=ILS",
  "expenses:food-ils" ∾ tab ∾ "role=expense" ∾ tab ∾ "currency=ILS"
⟩

raw ← Raw ⟨
  "commodity JPY",
  "",
  "account assets:cash-ils",
  "",
  "account expenses:food-ils",
  "",
  "2026-07-20 * undeclared ILS transaction",
  "  assets:cash-ils  -1.00 ILS",
  "  expenses:food-ils  1.00 ILS"
⟩

result ← container.Admit ⟨raw, resolved⟩

•Out "test_journal_multi_currency_container_admission_proof.bqn: DOMAIN RESOLUTION OK"
