# Test-only adapter for focused Envelope/Backing fixtures.
# Historical routes are explicit fixture facts and Budget endpoint roles are
# projected into the new canonical opening/unassigned/allocation relation.

core ← •Import "../src/accounting/envelope_backing.bqn"
historyFixture ← •Import "envelope_history_test_fixture.bqn"
empty ← ⟨⟩

Has ← {𝕊 key‿keys:∨´0∾key⊸≡¨keys}
HistoryFor ← {𝕊 facts:
  keys ← facts.accounts.key
  history ← historyFixture.Managed ⟨⟨"food"⟩,⟨"expenses:food"⟩,⟨"food"⟩⟩
  {𝕊:history↩historyFixture.Initial ⟨⟨"food"⟩,⟨"expenses:food","expenses:transport"⟩,⟨"managed","unmanaged"⟩,⟨"food",""⟩⟩}⍟(Has ⟨"expenses:transport",keys⟩) @
  {𝕊:history↩historyFixture.Managed ⟨⟨"food","transport"⟩,⟨"expenses:food","expenses:transport"⟩,⟨"food","transport"⟩⟩}⍟(Has ⟨"budget:transport",keys⟩) @
  {𝕊:history↩historyFixture.Managed ⟨⟨"food","transport"⟩,⟨"expenses:food","expenses:groceries","expenses:transport"⟩,⟨"food","food","transport"⟩⟩}⍟(Has ⟨"expenses:groceries",keys⟩) @
  {𝕊:history↩historyFixture.Managed ⟨⟨"food"⟩,⟨"expenses:ils"⟩,⟨"food"⟩⟩}⍟(Has ⟨"expenses:ils",keys⟩) @
  history
}
EmptyRetirements ← {𝕊:{plan_id⇐empty,retired_on⇐empty}}

SourceKeys ← {𝕊 candidates‿keys: ({Has ⟨𝕩,candidates⟩}¨keys)/keys}

Build ← {𝕊 budgetMovements‿policy‿household‿actual‿plan‿domain‿start‿finish‿observation:
  accountKeys ← actual.accounts.key
  openingKeys ← SourceKeys ⟨⟨"budget:opening","budget:opening-ils","Budget:Opening"⟩,accountKeys⟩
  unassignedKeys ← SourceKeys ⟨⟨"budget:unassigned","budget:unassigned-ils","Budget:Unassigned"⟩,accountKeys⟩
  openingIndices ← actual.accounts.key⊐openingKeys
  unassignedIndices ← actual.accounts.key⊐unassignedKeys
  testHousehold ← {
    state⇐household.state,source_name⇐household.source_name,
    budget⇐{
      envelope_count⇐≠household.budget.envelope_id,
      envelope_id⇐household.budget.envelope_id,
      allocation_account_key⇐household.budget.allocation_account_key,
      allocation_account_index⇐household.budget.allocation_account_index,
      opening_account_keys⇐openingKeys,opening_account_indices⇐openingIndices,
      unassigned_account_keys⇐unassignedKeys,unassigned_account_indices⇐unassignedIndices
    }
  }
  core.Build ⟨budgetMovements,policy,testHousehold,HistoryFor actual,actual,plan,EmptyRetirements @,domain,start,finish,observation⟩
}

{Build⇐Build,HistoryFor⇐HistoryFor}