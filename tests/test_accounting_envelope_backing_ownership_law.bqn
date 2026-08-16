#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
snapshot ← •Import "legacy_snapshot_fixture.bqn"
canonicalBudget ← •Import "canonical_budget_test_facts.bqn"
canonicalPlan ← •Import "canonical_plan_test_facts.bqn"
budgetPolicyAdmission ← •Import "../src/ledger/budget_policy_admission.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
envelopes ← •Import "envelope_backing_test_adapter.bqn"

base ← "fixtures/ledger-facts-phase1-proof/"
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
accountLines ← loader.ReadLines base∾"accounts.tsv"
actual ← (snapshot.Build ⟨accountLines,•FChars "../"∾base∾"actual.journal",registry⟩).facts
lf ← @+10
Raw ← {𝕊 lines: ∾lines∾¨lf}
AccountIndex ← {𝕊 key‿accounts: ⊑accounts.key⊐⟨key⟩}

# Keep the fixture's real Plan universe so Actual completion references are valid;
# each law below then isolates only the ownership relation it intentionally breaks.
plan ← (canonicalPlan.Build ⟨•FChars "../"∾base∾"plan.journal",actual.accounts,registry⟩).facts
budget ← (canonicalBudget.Build ⟨Raw ⟨
  "2026-01-01 seed",
  "  budget:opening     -100 JPY",
  "  budget:unassigned   100 JPY","",
  "2026-01-01 allocate-food",
  "  budget:unassigned  -60 JPY",
  "  budget:food         60 JPY"
⟩,actual.accounts,registry⟩).movements
policy ← budgetPolicyAdmission.Admit ⟨•FChars "../"∾base∾"budget.toml",actual.accounts⟩
"ok" lib.AssertEq policy.state

foodBudget ← AccountIndex ⟨"budget:food",actual.accounts⟩
openingBudget ← AccountIndex ⟨"budget:opening",actual.accounts⟩
unassignedBudget ← AccountIndex ⟨"budget:unassigned",actual.accounts⟩
foodExpense ← AccountIndex ⟨"expenses:food",actual.accounts⟩
start ← dates.Ordinal "2026-01-01"
finish ← dates.Ordinal "2026-02-01"
observation ← dates.Ordinal "2026-01-12"

Household ← {𝕊 envelopeIds‿allocationIndices‿openingIndices‿unassignedIndices:
  {
    state⇐"ok",source_name⇐"household.toml",
    budget⇐{
      envelope_id⇐envelopeIds,
      allocation_account_key⇐allocationIndices⊏actual.accounts.key∾⟨""⟩,
      allocation_account_index⇐allocationIndices,
      opening_account_keys⇐openingIndices⊏actual.accounts.key∾⟨""⟩,
      opening_account_indices⇐openingIndices,
      unassigned_account_keys⇐unassignedIndices⊏actual.accounts.key∾⟨""⟩,
      unassigned_account_indices⇐unassignedIndices
    }
  }
}
Build ← {𝕊 policyValue‿householdValue:
  envelopes.Build ⟨budget,policyValue,householdValue,actual,plan,"JPY",start,finish,observation⟩
}
AssertOwnershipError ← {𝕊 label‿expectedCode‿result:
  •Out "ownership law: "∾label
  "error" lib.AssertEq result.state
  "" lib.AssertEq result.reason
  0 lib.AssertEq result.envelopes.count
  expectedCode lib.AssertEq (⊑result.diagnostics).code
}

# Every missing or ambiguous Envelope relation fails before numeric publication.
missingMapping ← Build ⟨policy,Household ⟨⟨⟩,⟨⟩,⟨openingBudget⟩,⟨unassignedBudget⟩⟩⟩
AssertOwnershipError ⟨"missing mapping","envelope_account_mapping_invalid",missingMapping⟩

duplicateMapping ← Build ⟨policy,Household ⟨⟨"food","food"⟩,⟨foodBudget,foodBudget⟩,⟨openingBudget⟩,⟨unassignedBudget⟩⟩⟩
AssertOwnershipError ⟨"duplicate mapping","envelope_account_mapping_invalid",duplicateMapping⟩

invalidAllocationRole ← Build ⟨policy,Household ⟨⟨"food"⟩,⟨foodExpense⟩,⟨openingBudget⟩,⟨unassignedBudget⟩⟩⟩
AssertOwnershipError ⟨"invalid allocation role","envelope_account_mapping_invalid",invalidAllocationRole⟩

missingUnassigned ← Build ⟨policy,Household ⟨⟨"food"⟩,⟨foodBudget⟩,⟨openingBudget⟩,⟨⟩⟩⟩
AssertOwnershipError ⟨"missing unassigned","unassigned_scope_invalid",missingUnassigned⟩

# Stable Household keys, not admission-time numeric caches, name current Accounts.
missingAllocationKeyHousehold ← {
  state⇐"ok",source_name⇐"household.toml",
  budget⇐{
    envelope_id⇐⟨"food"⟩,
    allocation_account_key⇐⟨"budget:missing"⟩,
    allocation_account_index⇐⟨foodBudget⟩,
    opening_account_keys⇐⟨"budget:opening"⟩,
    opening_account_indices⇐⟨openingBudget⟩,
    unassigned_account_keys⇐⟨"budget:unassigned"⟩,
    unassigned_account_indices⇐⟨unassignedBudget⟩
  }
}
missingAllocationKey ← Build ⟨policy,missingAllocationKeyHousehold⟩
AssertOwnershipError ⟨"missing allocation key","envelope_account_mapping_invalid",missingAllocationKey⟩

missingUnassignedKeyHousehold ← {
  state⇐"ok",source_name⇐"household.toml",
  budget⇐{
    envelope_id⇐⟨"food"⟩,
    allocation_account_key⇐⟨"budget:food"⟩,
    allocation_account_index⇐⟨foodBudget⟩,
    opening_account_keys⇐⟨"budget:opening"⟩,
    opening_account_indices⇐⟨openingBudget⟩,
    unassigned_account_keys⇐⟨"budget:missing"⟩,
    unassigned_account_indices⇐⟨unassignedBudget⟩
  }
}
missingUnassignedKey ← Build ⟨policy,missingUnassignedKeyHousehold⟩
AssertOwnershipError ⟨"missing unassigned key","unassigned_scope_invalid",missingUnassignedKey⟩

missingFundingPolicy ← {
  state⇐"ok",source_name⇐"budget.toml",
  backing_pools⇐{asset_account_keys⇐⟨⟨"assets:missing"⟩⟩},
  envelopes⇐policy.envelopes
}
missingFunding ← Build ⟨missingFundingPolicy,Household ⟨⟨"food"⟩,⟨foodBudget⟩,⟨openingBudget⟩,⟨unassignedBudget⟩⟩⟩
AssertOwnershipError ⟨"missing funding key","budget_policy_asset_account_unknown",missingFunding⟩

•Out "test_accounting_envelope_backing_ownership_law: ok"
