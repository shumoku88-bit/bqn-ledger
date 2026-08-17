#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
snapshot ← •Import "canonical_snapshot_fixture.bqn"
entitlementAdmission ← •Import "../src/ledger/entitlement_journal_admission.bqn"
canonicalPlan ← •Import "canonical_plan_test_facts.bqn"
envelopePolicyAdmission ← •Import "../src/ledger/envelope_policy_admission.bqn"
historyFixture ← •Import "envelope_history_test_fixture.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
core ← •Import "../src/accounting/envelope_backing.bqn"

base ← "fixtures/ledger-facts-phase1-proof/"
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
accountSource ← •FChars "../"∾base∾"accounts.journal"
actual ← (snapshot.Build ⟨accountSource,•FChars "../"∾base∾"actual.journal",registry⟩).facts
lf ← @+10
Raw ← {𝕊 lines: ∾lines∾¨lf}

plan ← (canonicalPlan.Build ⟨•FChars "../"∾base∾"plan.journal",actual.accounts,registry⟩).facts
history ← historyFixture.Managed ⟨⟨"food"⟩,⟨"expenses:food"⟩,⟨"food"⟩⟩

entitlementRaw ← Raw ⟨
  "2026-01-01 origin JPY",
  "2026-01-01 transfer unallocated -> food 60 JPY ; allocate-food"
⟩
entitlement ← entitlementAdmission.Admit ⟨entitlementRaw,history,registry⟩
"ok" lib.AssertEq entitlement.state

policyRaw ← •FChars "../"∾base∾"envelope.toml"
policy ← envelopePolicyAdmission.Admit ⟨policyRaw,actual.accounts⟩
"ok" lib.AssertEq policy.state

start ← dates.Ordinal "2026-01-01"
finish ← dates.Ordinal "2026-02-01"
observation ← dates.Ordinal "2026-01-12"
EmptyRetirements ← {𝕊: {plan_id⇐⟨⟩,retired_on⇐⟨⟩}}

Build ← {𝕊 policyValue‿historyValue:
  core.Build ⟨entitlement,policyValue,historyValue,actual,plan,EmptyRetirements @,"JPY",start,finish,observation⟩
}
HasCode ← {𝕊 code‿diagnostics: ∨´0∾{𝕩.code≡code}¨diagnostics}
AssertOwnershipError ← {𝕊 label‿expectedCode‿result:
  •Out "ownership law: "∾label
  "error" lib.AssertEq result.state
  "" lib.AssertEq result.reason
  0 lib.AssertEq result.envelopes.count
  lib.Assert HasCode ⟨expectedCode,result.diagnostics⟩
}

# 1. Missing backing asset account on current Facts axis
missingFundingPolicy ← {
  state⇐"ok",source_name⇐"envelope.toml",
  backing_pools⇐{asset_account_keys⇐⟨⟨"assets:missing"⟩⟩},
  envelopes⇐policy.envelopes
}
missingFunding ← Build ⟨missingFundingPolicy,history⟩
AssertOwnershipError ⟨"missing funding key","envelope_policy_asset_account_unknown",missingFunding⟩

# 2. Non-asset backing account
invalidRoleFundingPolicy ← {
  state⇐"ok",source_name⇐"envelope.toml",
  backing_pools⇐{asset_account_keys⇐⟨⟨"expenses:food"⟩⟩},
  envelopes⇐policy.envelopes
}
invalidRoleFunding ← Build ⟨invalidRoleFundingPolicy,history⟩
AssertOwnershipError ⟨"invalid role funding","envelope_policy_asset_account_role_invalid",invalidRoleFunding⟩

# 3. Envelope in policy missing from history
missingHistory ← historyFixture.Managed ⟨⟨"other_id"⟩,⟨"expenses:food"⟩,⟨"other_id"⟩⟩
missingHistoryResult ← Build ⟨policy,missingHistory⟩
AssertOwnershipError ⟨"missing history identity","envelope_identity_missing",missingHistoryResult⟩

•Out "test_accounting_envelope_backing_ownership_law: ok"
