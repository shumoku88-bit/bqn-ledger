#!/usr/bin/env bqn

ak ← •Import "../src_next/account_key.bqn"
container ← •Import "../src_next/journal_multi_currency_container_admission_for_test.bqn"

lf ← @+10
tab ← @+9
Raw ← {𝕊 lines: ∾ (lines ∾¨ lf) }

resolved ← ak.Resolve ⟨
  "assets:bank-jpy" ∾ tab ∾ "role=asset" ∾ tab ∾ "currency=JPY",
  "assets:cash-ils" ∾ tab ∾ "role=asset" ∾ tab ∾ "currency=ILS"
⟩

result ← container.Admit ⟨Raw ⟨"commodity JPY", "", "commodity ILS"⟩, resolved⟩

•Out "test_journal_multi_currency_container_admission_proof.bqn: TWO DECLARATIONS CALL OK"
