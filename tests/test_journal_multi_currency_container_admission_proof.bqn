#!/usr/bin/env bqn

ak ← •Import "../src_next/account_key.bqn"
container ← •Import "../src_next/journal_multi_currency_container_admission_for_test.bqn"

lf ← @+10
tab ← @+9
Raw ← {𝕊 lines: ∾ (lines ∾¨ lf) }

resolved ← ak.Resolve ⟨
  "assets:bank-jpy" ∾ tab ∾ "role=asset" ∾ tab ∾ "currency=JPY",
  "expenses:food-jpy" ∾ tab ∾ "role=expense" ∾ tab ∾ "currency=JPY",
  "assets:cash-ils" ∾ tab ∾ "role=asset" ∾ tab ∾ "currency=ILS",
  "expenses:food-ils" ∾ tab ∾ "role=expense" ∾ tab ∾ "currency=ILS"
⟩

multiRaw ← Raw ⟨
  "commodity JPY",
  "",
  "commodity ILS",
  "",
  "account assets:bank-jpy",
  "",
  "account expenses:food-jpy",
  "",
  "account assets:cash-ils",
  "",
  "account expenses:food-ils",
  "",
  "2026-07-20 * synthetic JPY meal",
  "  ; event-id: proof-jpy-container-1",
  "  assets:bank-jpy  -1200 JPY",
  "  expenses:food-jpy  1200 JPY",
  "",
  "2026-07-21 * synthetic ILS meal",
  "  ; event-id: proof-ils-container-1",
  "  assets:cash-ils  -12.34 ILS",
  "  expenses:food-ils  12.34 ILS"
⟩

multi ← container.Admit ⟨multiRaw, resolved⟩

•Out "test_journal_multi_currency_container_admission_proof.bqn: CALL OK"
