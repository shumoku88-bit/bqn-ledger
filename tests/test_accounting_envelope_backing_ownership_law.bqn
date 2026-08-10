#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
snapshot ← •Import "../src/ledger/snapshot.bqn"
canonicalBudget ← •Import "canonical_budget_test_facts.bqn"
canonicalPlan ← •Import "canonical_plan_test_facts.bqn"
budgetPolicyAdmission ← •Import "../src/ledger/budget_policy_admission.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
envelopes ← •Import "../src/accounting/envelope_backing.bqn"

base ← "fixtures/ledger-facts-phase1-proof/"
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
accountLines ← loader.ReadLines base∾"accounts.tsv"
actual ← (snapshot.Build ⟨accountLines,•FChars "../"∾base∾"actual.journal",registry⟩).facts
lf ← @+10
Raw ← {𝕊 lines: ∾lines∾¨lf}
AccountIndex ← {𝕊 key‿accounts: ⊑accounts.key⊐⟨key⟩}

plan ← (canonicalPlan.Build ⟨"",actual.accounts,registry⟩).facts
budget ← (canonicalBudget.Build ⟨Raw ⟨
  "2026-01-01 seed",
  "  budget:opening     -100 JPY",
  "  budget:unassigned   100 JPY","",
  "2026-01-01 allocate-food",
  "  budget:unassigned  -60 JPY",
  "  budget:food         60 JPY"
⟩,actual.accounts,registry⟩).facts
policy ← budgetPolicyAdmission.Admit ⟨•FChars "../"∾base∾"budget.toml",actual.accounts⟩
"ok" lib.AssertEq policy.state

foodBudget ← AccountIndex ⟨"budget:food",actual.accounts⟩
unassignedBudget ← AccountIndex ⟨"budget:unassigned",actual.accounts⟩
foodExpense ← AccountIndex ⟨"expenses:food",actual.accounts⟩
start ← dates.Ordinal "2026-01-01"
finish ← dates.Ordinal "2026-02-01"
observation ← dates.Ordinal "2026-01-12"

Household ← {𝕊 envelopeIds‿allocationIndices‿unassignedIndices:
  {
    state⇐"ok",source_name⇐"household.toml",
    budget⇐{
      envelope_id⇐envelopeIds,
      allocation_account_index⇐allocationIndices,
      unassigned_account_indices⇐unassignedIndices
    },
    account_policy⇐{account_key⇐actual.accounts.key}
  }
}
Build ← {𝕊 policyValue‿householdValue:
  envelopes.Build ⟨budget,policyValue,householdValue,actual,plan,"JPY",start,finish,observation⟩
}
AssertOwnershipError ← {𝕊 expectedCode‿result:
  "error" lib.AssertEq result.state
  "" lib.AssertEq result.reason
  0 lib.AssertEq result.envelopes.count
  expectedCode lib.AssertEq (⊑result.diagnostics).code
}

# An Envelope index is appended only after exactly one Household mapping and a
# selected-domain Budget-role check. Every failure to append therefore emits a
# diagnostic first, so diagnostics-free ownershipMissing cannot be constructed.
missingMapping ← Build ⟨policy,Household ⟨⟨⟩,⟨⟩,⟨unassignedBudget⟩⟩⟩
AssertOwnershipError ⟨"envelope_account_mapping_invalid",missingMapping⟩

duplicateMapping ← Build ⟨policy,Household ⟨⟨"food","food"⟩,⟨foodBudget,foodBudget⟩,⟨unassignedBudget⟩⟩⟩
AssertOwnershipError ⟨"envelope_account_mapping_invalid",duplicateMapping⟩

invalidAllocationRole ← Build ⟨policy,Household ⟨⟨"food"⟩,⟨foodExpense⟩,⟨unassignedBudget⟩⟩⟩
AssertOwnershipError ⟨"envelope_account_mapping_invalid",invalidAllocationRole⟩

missingUnassigned ← Build ⟨policy,Household ⟨⟨"food"⟩,⟨foodBudget⟩,⟨⟩⟩⟩
AssertOwnershipError ⟨"unassigned_scope_invalid",missingUnassigned⟩

missingFundingPolicy ← {
  state⇐"ok",source_name⇐"budget.toml",
  backing_pools⇐{asset_account_keys⇐⟨⟨"assets:missing"⟩⟩},
  envelopes⇐policy.envelopes
}
missingFunding ← Build ⟨missingFundingPolicy,Household ⟨⟨"food"⟩,⟨foodBudget⟩,⟨unassignedBudget⟩⟩⟩
AssertOwnershipError ⟨"budget_policy_asset_account_unknown",missingFunding⟩

•Out "test_accounting_envelope_backing_ownership_law: ok"
