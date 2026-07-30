#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
accounts ← •Import "../src/ledger/account_admission.bqn"
loader ← •Import "../src/application/source_io.bqn"

tab ← @+9
registryResult ← registry_core.Build loader.ReadLines "config/currencies.tsv"
"ok" lib.AssertEq registryResult.state
registry ← registryResult.registry

proof ← accounts.Admit ⟨loader.ReadLines "fixtures/ledger-facts-phase1-proof/accounts.tsv",registry⟩
"ok" lib.AssertEq proof.state
0 lib.AssertEq ≠proof.diagnostics
8 lib.AssertEq proof.accounts.count
⟨"assets:cash","income:salary","expenses:food","expenses:transport","budget:opening","budget:unassigned","budget:food","budget:spent"⟩ lib.AssertEq proof.accounts.key
⟨"JPY","JPY","JPY","JPY","JPY","JPY","JPY","JPY"⟩ lib.AssertEq proof.accounts.currency
⟨"asset","income","expense","expense","budget","budget","budget","budget"⟩ lib.AssertEq proof.accounts.role

missingCurrency ← accounts.Admit ⟨⟨"assets:cash"∾tab∾"role=asset"⟩,registry⟩
"error" lib.AssertEq missingCurrency.state
0 lib.AssertEq missingCurrency.accounts.count
"account_currency_missing" lib.AssertEq (⊑missingCurrency.diagnostics).code

unclassified ← accounts.Admit ⟨⟨"assets:cash"∾tab∾"currency=JPY"⟩,registry⟩
"ok" lib.AssertEq unclassified.state
1 lib.AssertEq unclassified.accounts.count
"" lib.AssertEq ⊑unclassified.accounts.role
"warning" lib.AssertEq (⊑unclassified.diagnostics).severity
"account_role_unclassified" lib.AssertEq (⊑unclassified.diagnostics).code

unsupportedCurrency ← accounts.Admit ⟨⟨"assets:cash"∾tab∾"currency=EUR"∾tab∾"role=asset"⟩,registry⟩
"error" lib.AssertEq unsupportedCurrency.state
0 lib.AssertEq unsupportedCurrency.accounts.count
lib.Assert ∨´{𝕩.code≡"account_currency_unsupported"}¨unsupportedCurrency.diagnostics

duplicateMetadata ← accounts.Admit ⟨⟨"assets:cash"∾tab∾"currency=JPY"∾tab∾"role=asset"∾tab∾"currency=JPY"⟩,registry⟩
"error" lib.AssertEq duplicateMetadata.state
0 lib.AssertEq duplicateMetadata.accounts.count
"account_metadata_duplicate" lib.AssertEq (⊑duplicateMetadata.diagnostics).code
lib.Assert ∨´{𝕩.code≡"account_metadata_duplicate"}¨duplicateMetadata.diagnostics

unknownMetadata ← accounts.Admit ⟨⟨"assets:cash"∾tab∾"currency=JPY"∾tab∾"role=asset"∾tab∾"mystery=x"⟩,registry⟩
"error" lib.AssertEq unknownMetadata.state
lib.Assert ∨´{𝕩.code≡"account_metadata_unsupported"}¨unknownMetadata.diagnostics

duplicateKeys ← accounts.Admit ⟨
  ⟨
    "assets:cash"∾tab∾"currency=JPY"∾tab∾"role=asset",
    "income:salary"∾tab∾"currency=JPY"∾tab∾"role=income",
    "assets:cash"∾tab∾"currency=JPY"∾tab∾"role=asset"
  ⟩,
  registry
⟩
"error" lib.AssertEq duplicateKeys.state
0 lib.AssertEq duplicateKeys.accounts.count
1 lib.AssertEq ≠duplicateKeys.diagnostics
"account_key_duplicate" lib.AssertEq (⊑duplicateKeys.diagnostics).code

•Out "test_ledger_account_admission: ok"
