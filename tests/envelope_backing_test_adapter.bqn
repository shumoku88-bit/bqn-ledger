# Test-only adapter for legacy Envelope/Backing fixtures during native routing cutover.
# Historical routes are explicit fixture facts and never derive from budget.toml.

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
HasKey ← {𝕊 key‿keys:∨´0∾key⊸≡¨keys}
TestKind ← {𝕊 key:
  result ← "envelope"
  {𝕊:result↩"opening"}⍟(HasKey ⟨key,⟨"budget:opening","budget:opening-ils","Budget:Opening"⟩⟩) @
  {𝕊:result↩"unassigned"}⍟(HasKey ⟨key,⟨"budget:unassigned","budget:unassigned-ils","Budget:Unassigned"⟩⟩) @
  {𝕊:result↩"spent"}⍟(HasKey ⟨key,⟨"budget:spent","budget:spent-ils","Budget:Spent"⟩⟩) @
  result
}
TestRole ← {𝕊 key:
  result ← "dynamic"
  {𝕊:result↩"unassigned"}⍟(HasKey ⟨key,⟨"budget:unassigned","budget:unassigned-ils","Budget:Unassigned"⟩⟩) @
  {𝕊:result↩"execution"}⍟(HasKey ⟨key,⟨"budget:spent","budget:spent-ils","Budget:Spent"⟩⟩) @
  result
}

Build ← {𝕊 budgetMovements‿policy‿household‿actual‿plan‿domain‿start‿finish‿observation:
  accountKeys ← actual.accounts.key
  testHousehold ← {
    state⇐household.state,source_name⇐household.source_name,budget⇐household.budget,
    account_policy⇐{account_key⇐accountKeys,budget_kind⇐TestKind¨accountKeys,envelope_role⇐TestRole¨accountKeys}
  }
  core.Build ⟨budgetMovements,policy,testHousehold,HistoryFor actual,actual,plan,EmptyRetirements @,domain,start,finish,observation⟩
}

{Build⇐Build,HistoryFor⇐HistoryFor}
