#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registryBuilder ← •Import "../src/ledger/currency_registry.bqn"
accountAdmission ← •Import "../src/ledger/account_admission.bqn"
fundingScope ← •Import "../src/application/funding_scope.bqn"

base ← "fixtures/ledger-facts-phase1-proof/"
registry ← (registryBuilder.Build loader.ReadLines "config/currencies.tsv").registry
accounts ← (accountAdmission.Admit ⟨loader.ReadLines base∾"accounts.tsv",registry⟩).accounts
ok ← fundingScope.Build ⟨accounts,"JPY",⟨"assets:cash"⟩⟩
"ok" lib.AssertEq ok.state
⟨0⟩ lib.AssertEq ok.account_indices

CheckError ← {𝕊 domain‿keys‿code:
  result ← fundingScope.Build ⟨accounts,domain,keys⟩
  "error" lib.AssertEq result.state
  0 lib.AssertEq ≠result.account_indices
  code lib.AssertEq (⊑result.diagnostics).code
}
CheckError ⟨"JPY",⟨⟩,"funding_scope_empty"⟩
CheckError ⟨"JPY",⟨"assets:cash","assets:cash"⟩,"funding_scope_duplicate"⟩
CheckError ⟨"JPY",⟨"assets:missing"⟩,"funding_account_unknown"⟩
CheckError ⟨"USD",⟨"assets:cash"⟩,"funding_account_domain_mismatch"⟩
CheckError ⟨"JPY",⟨"expenses:food"⟩,"funding_account_role_invalid"⟩
•Out "test_application_funding_scope: ok"
