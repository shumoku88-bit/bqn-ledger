#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
admission ← •Import "../src/ledger/journal_complete_admission.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
io ← •Import "../src/application/source_io.bqn"
facts ← •Import "../src/ledger/facts.bqn"

lf ← @+10
registry ← (registry_core.Build io.ReadLines "config/currencies.tsv").registry

# Deliberately keep Account order independent from Domain and Posting order.
accounts ← {
  key⇐⟨"assets:usd","expenses:jpy","assets:jpy","expenses:usd"⟩,
  currency⇐⟨"USD","JPY","JPY","USD"⟩,
  role⇐⟨"asset","expense","asset","expense"⟩,
  type⇐⟨"asset","expense","asset","expense"⟩,
  metadata⇐⟨⟨⟩,⟨⟩,⟨⟩,⟨⟩⟩,
  source_row⇐1+↕4
}

raw ← ∾⟨
  "commodity JPY"∾lf,
  "commodity USD"∾lf,
  ""∾lf,
  "2026-01-01 * jpy purchase"∾lf,
  "  expenses:jpy  1 JPY"∾lf,
  "  assets:jpy  -1 JPY"∾lf,
  ""∾lf,
  "2026-01-02 * usd purchase"∾lf,
  "  expenses:usd  2 USD"∾lf,
  "  assets:usd  -2 USD"∾lf
⟩

admitted ← admission.Admit ⟨raw,accounts,registry⟩
result ← facts.Project ⟨admitted,accounts⟩

"ok" lib.AssertEq admitted.state
"ok" lib.AssertEq result.state
0 lib.AssertEq ≠result.diagnostics

# Domain coordinates follow admitted Domain order, independently of Account order.
⟨"JPY","USD"⟩ lib.AssertEq result.domains.code
⟨0,1⟩ lib.AssertEq result.transactions.domain_index
⟨0,0,1,1⟩ lib.AssertEq result.postings.domain_index

# Account coordinates follow admitted Account order and Posting rows stay
# transaction-major/source ordered rather than Account-grouped.
accounts.key lib.AssertEq result.accounts.key
⟨1,2,3,0⟩ lib.AssertEq result.postings.account_index
⟨0,0,1,1⟩ lib.AssertEq result.postings.transaction_index
⟨0,1,0,1⟩ lib.AssertEq result.postings.transaction_posting_index
⟨1,¯1,2,¯2⟩ lib.AssertEq result.postings.coefficient

# One source-specific Fact result has one explicit Layer axis.
⟨"actual"⟩ lib.AssertEq result.layers.name
⟨0,0⟩ lib.AssertEq result.transactions.layer_index
⟨0,0,0,0⟩ lib.AssertEq result.postings.layer_index

# Projection diagnostics remain transaction-major and preserve the established
# validation order even though the join relations are classified beforehand.
forgedPosting ← {account_key⇐"missing:account",normalized_coefficient⇐1}
forgedTransaction ← {
  date⇐"2026-02-30",domain⇐"USD",layer_name⇐"",source_event_id⇐"",
  postings⇐⟨forgedPosting⟩
}
forgedAdmission ← {
  state⇐"ok",transactions⇐⟨forgedTransaction⟩,
  declared_domains⇐⟨"JPY"⟩,declared_layers⇐⟨"actual"⟩,source_name⇐"actual.journal"
}
forged ← facts.Project ⟨forgedAdmission,accounts⟩
"error" lib.AssertEq forged.state
⟨
  "transaction_date_invalid",
  "transaction_domain_undeclared",
  "transaction_layer_missing",
  "transaction_layer_undeclared",
  "transaction_identity_missing",
  "posting_account_unknown",
  "transaction_unbalanced"
⟩ lib.AssertEq {𝕩.code}¨forged.diagnostics
0 lib.AssertEq forged.transactions.count
0 lib.AssertEq forged.postings.count

•Out "test_ledger_facts_coordinates: ok"
