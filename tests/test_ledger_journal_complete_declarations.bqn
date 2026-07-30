#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
admission ← •Import "../src/ledger/journal_complete_admission.bqn"

lf ← @+10
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry

validRaw ← ∾⟨
  "commodity ILS"∾lf,
  ""∾lf,
  "commodity JPY"∾lf,
  ""∾lf,
  "commodity USD"∾lf
⟩
valid ← admission.Admit ⟨validRaw,⟨⟩,registry⟩
"ok" lib.AssertEq valid.state
⟨"ILS","JPY","USD"⟩ lib.AssertEq valid.declared_domains
⟨"actual"⟩ lib.AssertEq valid.declared_layers
0 lib.AssertEq ≠valid.transactions
0 lib.AssertEq ≠valid.diagnostics

duplicateRaw ← ∾⟨
  "commodity JPY"∾lf,
  ""∾lf,
  "commodity ILS"∾lf,
  ""∾lf,
  "commodity JPY"∾lf
⟩
duplicate ← admission.Admit ⟨duplicateRaw,⟨⟩,registry⟩
"error" lib.AssertEq duplicate.state
0 lib.AssertEq ≠duplicate.transactions
1 lib.AssertEq ≠duplicate.diagnostics
"commodity_domain_duplicate" lib.AssertEq (⊑duplicate.diagnostics).code
0 lib.AssertEq (⊑duplicate.diagnostics).line

mixedPostingRaw ← ∾⟨
  "commodity JPY"∾lf,
  ""∾lf,
  "commodity ILS"∾lf,
  ""∾lf,
  "2026-01-01 * mixed domain"∾lf,
  "    assets:cash 10 JPY"∾lf,
  "    expenses:food 5 ILS"∾lf,
  "    assets:cash -15 JPY"
⟩
mixedPosting ← admission.Admit ⟨mixedPostingRaw,⟨⟩,registry⟩
"error" lib.AssertEq mixedPosting.state
⟨"JPY","ILS"⟩ lib.AssertEq mixedPosting.declared_domains
0 lib.AssertEq ≠mixedPosting.transactions
1 lib.AssertEq ≠mixedPosting.diagnostics
"transaction_domain_count_invalid" lib.AssertEq (⊑mixedPosting.diagnostics).code
5 lib.AssertEq (⊑mixedPosting.diagnostics).line

accounts ← {
  key⇐⟨"assets:cash","income:salary","expenses:food","budget:opening","budget:food"⟩,
  currency⇐⟨"JPY","JPY","JPY","JPY","JPY"⟩
}
layeredRaw ← ∾⟨
  "commodity JPY"∾lf,
  ""∾lf,
  "account assets:cash"∾lf,
  ""∾lf,
  "account income:salary"∾lf,
  ""∾lf,
  "account expenses:food"∾lf,
  ""∾lf,
  "account budget:opening"∾lf,
  ""∾lf,
  "account budget:food"∾lf,
  ""∾lf,
  "2026-01-01 * salary"∾lf,
  "    ; event-id: actual-1"∾lf,
  "    assets:cash 100 JPY"∾lf,
  "    income:salary -100 JPY"∾lf,
  ""∾lf,
  "2026-01-02 * food plan"∾lf,
  "    ; event-id: plan-1"∾lf,
  "    ; layer: plan"∾lf,
  "    ; plan-id: plan-food-1"∾lf,
  "    expenses:food 20 JPY"∾lf,
  "    assets:cash -20 JPY"∾lf,
  ""∾lf,
  "2026-01-03 * food actual"∾lf,
  "    ; event-id: actual-2"∾lf,
  "    expenses:food 10 JPY"∾lf,
  "    assets:cash -10 JPY"∾lf,
  ""∾lf,
  "2026-01-04 * budget allocation"∾lf,
  "    ; event-id: budget-1"∾lf,
  "    ; layer: budget"∾lf,
  "    ; allocation-id: allocation-1"∾lf,
  "    budget:food 30 JPY"∾lf,
  "    budget:opening -30 JPY"
⟩
layered ← admission.Admit ⟨layeredRaw,accounts,registry⟩
"ok" lib.AssertEq layered.state
⟨"actual","plan","budget"⟩ lib.AssertEq layered.declared_layers
⟨"actual","plan","actual","budget"⟩ lib.AssertEq {𝕩.layer_name}¨layered.transactions
⟨"actual-1","plan-1","actual-2","budget-1"⟩ lib.AssertEq {𝕩.source_event_id}¨layered.transactions
⟨"durable","durable","durable","durable"⟩ lib.AssertEq {𝕩.identity_kind}¨layered.transactions
4 lib.AssertEq ≠layered.transactions
0 lib.AssertEq ≠layered.diagnostics

•Out "test_ledger_journal_complete_declarations: ok"
