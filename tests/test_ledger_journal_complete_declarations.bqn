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

•Out "test_ledger_journal_complete_declarations: ok"
