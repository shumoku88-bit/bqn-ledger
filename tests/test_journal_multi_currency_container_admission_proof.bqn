#!/usr/bin/env bqn

ak ← •Import "../src_next/account_key.bqn"
container ← •Import "../src_next/journal_multi_currency_container_admission_for_test.bqn"

lf ← @+10
tab ← @+9
Raw ← {𝕊 lines: ∾ (lines ∾¨ lf) }
resolved ← ak.Resolve ⟨
  "assets:bank-jpy" ∾ tab ∾ "role=asset" ∾ tab ∾ "currency=JPY"
⟩

raw ← Raw ⟨
  "commodity JPY",
  "",
  "2026-07-20 * invalid posting shape",
  "  broken"
⟩

result ← container.Admit ⟨raw, resolved⟩

•Out "test_journal_multi_currency_container_admission_proof.bqn: POSTING SHAPE OK"
