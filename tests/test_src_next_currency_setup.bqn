#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
setup ← •Import "../src_next/currency_setup.bqn"
registry_core ← •Import "../src_next/currency_registry.bqn"
loader ← •Import "../src_next/loader.bqn"
util ← •Import "../src_next/util.bqn"

tab ← @+9

# Repository registry keeps the current JPY/ILS policy, while the parser remains
# pure and rejects malformed registry fixtures without partial admission.
validRegistry ← registry_core.Build (loader.ReadLines "fixtures/currency-registry/valid.tsv")
"ok" lib.AssertEq validRegistry.state
⟨"JPY", "ILS"⟩ lib.AssertEq validRegistry.registry.codes
"₪" lib.AssertEq (validRegistry.registry.Policy "ILS").symbol
"currency_registry_currency_duplicate" lib.AssertEq (registry_core.Build (loader.ReadLines "fixtures/currency-registry-invalid/duplicate.tsv")).code
"currency_registry_currency_empty" lib.AssertEq (registry_core.Build (loader.ReadLines "fixtures/currency-registry-invalid/empty-code.tsv")).code
"currency_registry_fraction_digits_invalid" lib.AssertEq (registry_core.Build (loader.ReadLines "fixtures/currency-registry-invalid/invalid-fraction.tsv")).code

# Runtime policy is resolved from config/currencies.tsv through currency_setup.
⟨"JPY", "ILS", "USD"⟩ lib.AssertEq setup.supported_currencies
jpyPolicy ← setup.Policy "JPY"
"ok" lib.AssertEq jpyPolicy.state
"JPY" lib.AssertEq jpyPolicy.currency
¯1 lib.AssertEq jpyPolicy.max_fraction_digits
ilsPolicy ← setup.Policy "ILS"
"ok" lib.AssertEq ilsPolicy.state
"ILS" lib.AssertEq ilsPolicy.currency
2 lib.AssertEq ilsPolicy.max_fraction_digits
unknownPolicy ← setup.Policy "EUR"
"error" lib.AssertEq unknownPolicy.state
"unsupported_currency" lib.AssertEq unknownPolicy.code
0 lib.AssertEq setup.IsSupportedCurrency "EUR"

configLines ← ⟨
  "# explicit ledger-level default",
  "DEFAULT_CURRENCY=JPY"
⟩

accountLines ← ⟨
  "# account order and metadata must remain exact",
  "assets:bank" ∾ tab ∾ "role=asset" ∾ tab ∾ "type=liquid",
  "expenses:food" ∾ tab ∾ "role=expense" ∾ tab ∾ "report_group=food",
  "",
  "assets:cash-ils" ∾ tab ∾ "role=asset" ∾ tab ∾ "type=liquid" ∾ tab ∾ "currency=ILS",
  "expenses:food-ils" ∾ tab ∾ "role=expense" ∾ tab ∾ "report_group=food" ∾ tab ∾ "currency=ILS"
⟩

journalLines ← ⟨
  "# empty memo and unrelated metadata must survive",
  "2026-07-01" ∾ tab ∾ "" ∾ tab ∾ "assets:bank" ∾ tab ∾ "expenses:food" ∾ tab ∾ "1200" ∾ tab ∾ "party=shop",
  "2026-07-02" ∾ tab ∾ "explicit JPY" ∾ tab ∾ "assets:bank" ∾ tab ∾ "expenses:food" ∾ tab ∾ "300" ∾ tab ∾ "currency=JPY" ∾ tab ∾ "note=keep",
  "2026-07-03" ∾ tab ∾ "ILS bread" ∾ tab ∾ "assets:cash-ils" ∾ tab ∾ "expenses:food-ils" ∾ tab ∾ "12.50" ∾ tab ∾ "currency=ILS"
⟩

# Explicit ledger default is required and independently resolved.
defaultResult ← setup.ResolveDefault configLines
"ok" lib.AssertEq defaultResult.state
"DEFAULT_CURRENCY" lib.AssertEq defaultResult.key
"JPY" lib.AssertEq defaultResult.currency
"ledger_config" lib.AssertEq defaultResult.provenance

missingDefault ← setup.ResolveDefault ⟨"POLICY_BUDGET_STYLE=envelope"⟩
"error" lib.AssertEq missingDefault.state
"missing_default_currency" lib.AssertEq missingDefault.code

duplicateDefault ← setup.ResolveDefault ⟨"DEFAULT_CURRENCY=JPY", "DEFAULT_CURRENCY=ILS"⟩
"error" lib.AssertEq duplicateDefault.state
"duplicate_default_currency" lib.AssertEq duplicateDefault.code

unknownDefault ← setup.ResolveDefault ⟨"DEFAULT_CURRENCY=EUR"⟩
"error" lib.AssertEq unknownDefault.state
"unsupported_default_currency" lib.AssertEq unknownDefault.code

# Selection provenance distinguishes ledger default from explicit override.
defaultSelection ← setup.ResolveSelection ⟨defaultResult, ""⟩
"ok" lib.AssertEq defaultSelection.state
"JPY" lib.AssertEq defaultSelection.currency
"ledger_default" lib.AssertEq defaultSelection.provenance

explicitSelection ← setup.ResolveSelection ⟨defaultResult, "ILS"⟩
"ok" lib.AssertEq explicitSelection.state
"ILS" lib.AssertEq explicitSelection.currency
"explicit_selection" lib.AssertEq explicitSelection.provenance

unsupportedSelection ← setup.ResolveSelection ⟨defaultResult, "EUR"⟩
"error" lib.AssertEq unsupportedSelection.state
"unsupported_selected_currency" lib.AssertEq unsupportedSelection.code

# AuditFile / AuditLine tests (used by balances etc.)
accountsFile ← setup.AuditFile ⟨"accounts.tsv", "accounts", accountLines, "JPY"⟩
"ok" lib.AssertEq accountsFile.state

journalFile ← setup.AuditFile ⟨"journal.tsv", "journal", journalLines, "JPY"⟩
"ok" lib.AssertEq journalFile.state

# Classifications check (missing / explicit / ignored)
"ignored" lib.AssertEq (0 ⊑ accountsFile.rows).classification
"missing" lib.AssertEq (1 ⊑ accountsFile.rows).classification
"missing" lib.AssertEq (2 ⊑ accountsFile.rows).classification
"ignored" lib.AssertEq (3 ⊑ accountsFile.rows).classification
"explicit" lib.AssertEq (4 ⊑ accountsFile.rows).classification

"ignored" lib.AssertEq (0 ⊑ journalFile.rows).classification
"missing" lib.AssertEq (1 ⊑ journalFile.rows).classification
"explicit" lib.AssertEq (2 ⊑ journalFile.rows).classification
"explicit" lib.AssertEq (3 ⊑ journalFile.rows).classification

# Unknown, duplicate, and invalid structure fail closed
unknownRow ← "2026-07-01"∾tab∾"x"∾tab∾"assets:bank"∾tab∾"expenses:food"∾tab∾"1"∾tab∾"currency=EUR"
unknownFile ← setup.AuditFile ⟨"journal.tsv", "journal", ⟨unknownRow⟩, "JPY"⟩
"error" lib.AssertEq unknownFile.state
"unknown" lib.AssertEq (0 ⊑ unknownFile.rows).classification

duplicateRow ← unknownRow ∾ tab ∾ "currency=JPY"
duplicateFile ← setup.AuditFile ⟨"journal.tsv", "journal", ⟨duplicateRow⟩, "JPY"⟩
"error" lib.AssertEq duplicateFile.state
"duplicate" lib.AssertEq (0 ⊑ duplicateFile.rows).classification

invalidRow ← "invalid line without tabs"
invalidFile ← setup.AuditFile ⟨"journal.tsv", "journal", ⟨invalidRow⟩, "JPY"⟩
"error" lib.AssertEq invalidFile.state
"invalid_structure" lib.AssertEq (0 ⊑ invalidFile.rows).classification

•Out "test_src_next_currency_setup.bqn: OK"
