#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
admission ← •Import "../src/ledger/journal_complete_admission.bqn"

lf ← @+10
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry

# Declaration diagnostics remain source-major, with the whole-source duplicate
# diagnostic appended after row-local declaration diagnostics.
declarationRaw ← ∾⟨
  "commodity JPY extra"∾lf,
  ""∾lf,
  "commodity XYZ"∾lf,
  ""∾lf,
  "commodity JPY"∾lf,
  ""∾lf,
  "commodity ILS"∾lf,
  ""∾lf,
  "commodity JPY"
⟩
declarations ← admission.Admit ⟨declarationRaw,⟨⟩,registry⟩
"error" lib.AssertEq declarations.state
⟨"JPY","ILS"⟩ lib.AssertEq declarations.declared_domains
0 lib.AssertEq ≠declarations.transactions
⟨"commodity_shape_invalid","commodity_unsupported","commodity_domain_duplicate"⟩ lib.AssertEq {𝕩.code}¨declarations.diagnostics
⟨1,3,0⟩ lib.AssertEq {𝕩.line}¨declarations.diagnostics

# Posting-domain shape diagnostics remain source-major inside one transaction.
# Shape failure owns the transaction boundary and suppresses later domain-count
# and single-domain semantic admission for that block.
postingRaw ← ∾⟨
  "commodity JPY"∾lf,
  ""∾lf,
  "2026-01-01 * malformed postings"∾lf,
  "    assets:cash  10 JPY extra"∾lf,
  "    assets:cash  10 JPY"∾lf,
  "    expenses:food  5 JPY extra"
⟩
postings ← admission.Admit ⟨postingRaw,⟨⟩,registry⟩
"error" lib.AssertEq postings.state
⟨"JPY"⟩ lib.AssertEq postings.declared_domains
0 lib.AssertEq ≠postings.transactions
⟨"posting_shape_invalid","posting_shape_invalid"⟩ lib.AssertEq {𝕩.code}¨postings.diagnostics
⟨4,6⟩ lib.AssertEq {𝕩.line}¨postings.diagnostics

•Out "test_ledger_journal_complete_source_relations: ok"
