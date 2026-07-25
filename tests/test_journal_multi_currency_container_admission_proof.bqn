#!/usr/bin/env bqn

ak ← •Import "../src_next/account_key.bqn"
container ← •Import "../src_next/journal_multi_currency_container_admission_for_test.bqn"

tab ← @+9
resolved ← ak.Resolve ⟨
  "assets:bank-jpy" ∾ tab ∾ "role=asset" ∾ tab ∾ "currency=JPY"
⟩

result ← container.Admit ⟨"2026-07-20 * synthetic header", resolved⟩

•Out "test_journal_multi_currency_container_admission_proof.bqn: RANGE CALL OK"
