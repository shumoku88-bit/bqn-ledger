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

Build ← {𝕊 budget‿policy‿household‿actual‿plan‿domain‿start‿finish‿observation:
  core.Build ⟨budget,policy,household,HistoryFor actual,actual,plan,EmptyRetirements @,domain,start,finish,observation⟩
}

{Build⇐Build,HistoryFor⇐HistoryFor}
