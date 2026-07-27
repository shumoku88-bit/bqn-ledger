#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ak ← •Import "../src_next/account_key.bqn"
admission ← •Import "../src/ledger/journal_complete_admission.bqn"
setup ← •Import "../src_next/currency_setup.bqn"
carrier ← •Import "../src_next/journal_currency_proof_carrier_stage2a.bqn"

lf ← @+10
tab ← @+9
MakeRaw ← {𝕊 lines: ∾ (lines ∾¨ lf) }
HasCode ← {𝕊 code‿result: ∨´ 0 ∾ {code ≡ 𝕩.code}¨ result.diagnostics }

resolved ← ak.Resolve ⟨
  "assets:bank-jpy" ∾ tab ∾ "role=asset" ∾ tab ∾ "currency=JPY",
  "expenses:food-jpy" ∾ tab ∾ "role=expense" ∾ tab ∾ "currency=JPY",
  "assets:cash-ils" ∾ tab ∾ "role=asset" ∾ tab ∾ "currency=ILS",
  "expenses:food-ils" ∾ tab ∾ "role=expense" ∾ tab ∾ "currency=ILS",
  "assets:cash-usd" ∾ tab ∾ "role=asset" ∾ tab ∾ "currency=USD",
  "expenses:food-usd" ∾ tab ∾ "role=expense" ∾ tab ∾ "currency=USD"
⟩
admittedAccounts ← {key⇐resolved.accounts,currency⇐resolved.currencies}
Admit ← {𝕊 raw: admission.Admit ⟨raw,admittedAccounts,setup.registry_value⟩ }

jpyIlsRaw ← MakeRaw ⟨
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
  "2026-07-25 * carrier JPY meal",
  "  ; event-id: carrier-jpy-1",
  "  assets:bank-jpy  -800 JPY",
  "  expenses:food-jpy  800 JPY",
  "",
  "2026-07-26 * carrier ILS meal",
  "  ; event-id: carrier-ils-1",
  "  assets:cash-ils  -12.34 ILS",
  "  expenses:food-ils  12.34 ILS"
⟩
admitted ← Admit jpyIlsRaw
"ok" lib.AssertEq admitted.state

result ← carrier.BuildForSource ⟨admitted.transactions, resolved, "2026-07-01", "synthetic-multi.journal"⟩
"ok" lib.AssertEq result.state
0 lib.AssertEq ≠ result.diagnostics
⟨"JPY", "ILS"⟩ lib.AssertEq result.transaction_domains
4 lib.AssertEq ≠ result.currency_proof_rows
rows ← result.currency_proof_rows

first ← 0 ⊑ rows
"synthetic-multi.journal" lib.AssertEq first.source_file
0 lib.AssertEq first.source_row
0 lib.AssertEq first.transaction_index
13 lib.AssertEq first.source_start_line
16 lib.AssertEq first.source_end_line
"carrier-jpy-1" lib.AssertEq first.source_id
"durable" lib.AssertEq first.identity_kind
"carrier-jpy-1" lib.AssertEq first.tx_id
lib.Assert 0 < ≠ first.posting_id
0 lib.AssertEq first.posting_index
15 lib.AssertEq first.source_line
"2026-07-25" lib.AssertEq first.date
24 lib.AssertEq first.day_index
"assets:bank-jpy" lib.AssertEq first.account_name
"assets:bank-jpy/JPY" lib.AssertEq first.account_key
0 lib.AssertEq first.account_key_index
"actual" lib.AssertEq first.layer_name
0 lib.AssertEq first.layer_index
"credit" lib.AssertEq first.side
"expense" lib.AssertEq first.kind
"JPY" lib.AssertEq first.domain
0 lib.AssertEq first.calculation_scale
"JPY" lib.AssertEq first.account_currency
"JPY" lib.AssertEq first.commodity
"-800" lib.AssertEq first.amount_text
¯800 lib.AssertEq first.source_coefficient
0 lib.AssertEq first.source_scale
¯800 lib.AssertEq first.normalized_coefficient
"ok" lib.AssertEq first.status
"" lib.AssertEq first.message

ilsFirst ← 2 ⊑ rows
"ILS" lib.AssertEq ilsFirst.domain
2 lib.AssertEq ilsFirst.calculation_scale
"-12.34" lib.AssertEq ilsFirst.amount_text
¯1234 lib.AssertEq ilsFirst.source_coefficient
2 lib.AssertEq ilsFirst.source_scale
¯1234 lib.AssertEq ilsFirst.normalized_coefficient
"ILS" lib.AssertEq ilsFirst.account_currency
"ILS" lib.AssertEq ilsFirst.commodity
"assets:cash-ils/ILS" lib.AssertEq ilsFirst.account_key
20 lib.AssertEq ilsFirst.source_line

0 lib.AssertEq +´ {𝕩.normalized_coefficient}¨ 0‿1 ⊏ rows
0 lib.AssertEq +´ {𝕩.normalized_coefficient}¨ 2‿3 ⊏ rows

jpyUsdRaw ← MakeRaw ⟨
  "commodity USD",
  "",
  "account assets:cash-usd",
  "",
  "account expenses:food-usd",
  "",
  "2026-07-27 * carrier USD meal",
  "  ; event-id: carrier-usd-1",
  "  assets:cash-usd  -7.5 USD",
  "  expenses:food-usd  7.5 USD"
⟩
admittedUsd ← Admit jpyUsdRaw
"ok" lib.AssertEq admittedUsd.state
usdResult ← carrier.Build ⟨admittedUsd.transactions, resolved, "2026-07-01"⟩
"ok" lib.AssertEq usdResult.state
⟨"USD"⟩ lib.AssertEq usdResult.transaction_domains
2 lib.AssertEq ≠ usdResult.currency_proof_rows
usdFirst ← 0 ⊑ usdResult.currency_proof_rows
"USD" lib.AssertEq usdFirst.domain
1 lib.AssertEq usdFirst.calculation_scale
¯75 lib.AssertEq usdFirst.normalized_coefficient

CopyPosting ← {𝕊 posting‿commodity‿accountCurrency‿normalizedCoefficient:
  {
    posting_id⇐posting.posting_id,
    posting_index⇐posting.posting_index,
    side⇐posting.side,
    source_line⇐posting.source_line,
    account_key⇐posting.account_key,
    account_currency⇐accountCurrency,
    commodity⇐commodity,
    amount_text⇐posting.amount_text,
    source_coefficient⇐posting.source_coefficient,
    source_scale⇐posting.source_scale,
    normalized_coefficient⇐normalizedCoefficient
  }
}

CopyPostingTrace ← {𝕊 posting‿postingId‿sourceLine:
  {
    posting_id⇐postingId,
    posting_index⇐posting.posting_index,
    side⇐posting.side,
    source_line⇐sourceLine,
    account_key⇐posting.account_key,
    account_currency⇐posting.account_currency,
    commodity⇐posting.commodity,
    amount_text⇐posting.amount_text,
    source_coefficient⇐posting.source_coefficient,
    source_scale⇐posting.source_scale,
    normalized_coefficient⇐posting.normalized_coefficient
  }
}

CopyTransaction ← {𝕊 transaction‿sourceEventId‿domain‿postings:
  {
    source_event_id⇐sourceEventId,
    identity_kind⇐transaction.identity_kind,
    source_start_line⇐transaction.source_start_line,
    source_end_line⇐transaction.source_end_line,
    date⇐transaction.date,
    status_marker⇐transaction.status_marker,
    description⇐transaction.description,
    layer_name⇐transaction.layer_name,
    txn_id⇐transaction.txn_id,
    plan_id⇐transaction.plan_id,
    allocation_id⇐transaction.allocation_id,
    execution_envelope⇐transaction.execution_envelope,
    actual_event_id⇐transaction.actual_event_id,
    domain⇐domain,
    calculation_scale⇐transaction.calculation_scale,
    metadata⇐transaction.metadata,
    postings⇐postings
  }
}

jpyTransaction ← 0 ⊑ admitted.transactions
ilsTransaction ← 1 ⊑ admitted.transactions
ilsPosting0 ← 0 ⊑ ilsTransaction.postings
ilsPosting1 ← 1 ⊑ ilsTransaction.postings

badNormalizedPosting ← CopyPosting ⟨ilsPosting0, ilsPosting0.commodity, ilsPosting0.account_currency, ¯1233⟩
badNormalizedTransaction ← CopyTransaction ⟨ilsTransaction, ilsTransaction.source_event_id, ilsTransaction.domain, ⟨badNormalizedPosting, ilsPosting1⟩⟩
badNormalized ← carrier.Build ⟨⟨jpyTransaction, badNormalizedTransaction⟩, resolved, "2026-07-01"⟩
"error" lib.AssertEq badNormalized.state
lib.Assert HasCode ⟨"posting_normalization_mismatch", badNormalized⟩
lib.Assert HasCode ⟨"transaction_unbalanced", badNormalized⟩
0 lib.AssertEq ≠ badNormalized.currency_proof_rows

badAccountPosting ← CopyPosting ⟨ilsPosting0, ilsPosting0.commodity, "USD", ilsPosting0.normalized_coefficient⟩
badAccountTransaction ← CopyTransaction ⟨ilsTransaction, ilsTransaction.source_event_id, ilsTransaction.domain, ⟨badAccountPosting, ilsPosting1⟩⟩
badAccount ← carrier.Build ⟨⟨jpyTransaction, badAccountTransaction⟩, resolved, "2026-07-01"⟩
"error" lib.AssertEq badAccount.state
lib.Assert HasCode ⟨"posting_account_currency_mismatch", badAccount⟩
lib.Assert HasCode ⟨"posting_resolved_currency_mismatch", badAccount⟩
0 lib.AssertEq ≠ badAccount.currency_proof_rows

badCommodityPosting ← CopyPosting ⟨ilsPosting0, "USD", ilsPosting0.account_currency, ilsPosting0.normalized_coefficient⟩
badCommodityTransaction ← CopyTransaction ⟨ilsTransaction, ilsTransaction.source_event_id, ilsTransaction.domain, ⟨badCommodityPosting, ilsPosting1⟩⟩
badCommodity ← carrier.Build ⟨⟨jpyTransaction, badCommodityTransaction⟩, resolved, "2026-07-01"⟩
"error" lib.AssertEq badCommodity.state
lib.Assert HasCode ⟨"posting_domain_mismatch", badCommodity⟩
0 lib.AssertEq ≠ badCommodity.currency_proof_rows

badSourcePosting ← CopyPostingTrace ⟨ilsPosting0, ilsPosting0.posting_id, 1⟩
badSourceTransaction ← CopyTransaction ⟨ilsTransaction, ilsTransaction.source_event_id, ilsTransaction.domain, ⟨badSourcePosting, ilsPosting1⟩⟩
badSource ← carrier.Build ⟨⟨jpyTransaction, badSourceTransaction⟩, resolved, "2026-07-01"⟩
"error" lib.AssertEq badSource.state
lib.Assert HasCode ⟨"posting_source_range_mismatch", badSource⟩
0 lib.AssertEq ≠ badSource.currency_proof_rows

duplicatePosting1 ← CopyPostingTrace ⟨ilsPosting1, ilsPosting0.posting_id, ilsPosting1.source_line⟩
duplicatePostingTransaction ← CopyTransaction ⟨ilsTransaction, ilsTransaction.source_event_id, ilsTransaction.domain, ⟨ilsPosting0, duplicatePosting1⟩⟩
duplicatePosting ← carrier.Build ⟨⟨jpyTransaction, duplicatePostingTransaction⟩, resolved, "2026-07-01"⟩
"error" lib.AssertEq duplicatePosting.state
lib.Assert HasCode ⟨"posting_id_duplicate", duplicatePosting⟩
0 lib.AssertEq ≠ duplicatePosting.currency_proof_rows

duplicateIdentityTransaction ← CopyTransaction ⟨ilsTransaction, jpyTransaction.source_event_id, ilsTransaction.domain, ilsTransaction.postings⟩
duplicateIdentity ← carrier.Build ⟨⟨jpyTransaction, duplicateIdentityTransaction⟩, resolved, "2026-07-01"⟩
"error" lib.AssertEq duplicateIdentity.state
lib.Assert HasCode ⟨"event_id_duplicate", duplicateIdentity⟩
0 lib.AssertEq ≠ duplicateIdentity.currency_proof_rows

unsupportedTransaction ← CopyTransaction ⟨ilsTransaction, ilsTransaction.source_event_id, "EUR", ilsTransaction.postings⟩
unsupported ← carrier.Build ⟨⟨unsupportedTransaction⟩, resolved, "2026-07-01"⟩
"error" lib.AssertEq unsupported.state
lib.Assert HasCode ⟨"transaction_domain_unsupported", unsupported⟩
0 lib.AssertEq ≠ unsupported.currency_proof_rows

•Out "test_journal_currency_proof_carrier_stage2a.bqn: OK"
