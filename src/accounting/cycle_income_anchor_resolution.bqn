# Pure incomeAnchor resolution from admitted Actual/Plan Facts and explicit as-of.
# Source-qualified contributors remain separate; no cross-source amount is added.

result ← •Import "cycle_result.bqn"
reference ← •Import "../ledger/fact_reference.bqn"
dates ← •Import "../ledger/date_ordinal.bqn"
empty ← ⟨⟩

Contains ← {∨´ 𝕨⊸≡¨𝕩}
Deduplicate ← {((𝕩⊐𝕩)=↕≠𝕩)/𝕩}
IndexOf ← {⊑(𝕨⊸≡¨𝕩)⊐1}
References ← {𝕊 facts‿indices: {reference.Transaction ⟨facts,𝕩⟩}¨Deduplicate indices}

Resolve ← {𝕊 admittedCycle‿asOfText‿actualFacts‿planFacts:
  resolved ← result.Error ⟨"incomeAnchor",asOfText,"cycle_admission_not_ok","cycle definition must be admitted"⟩
  {𝕊:
    def ← admittedCycle.definition
    resolved ↩ result.Error ⟨def.mode,asOfText,"cycle_mode_mismatch","incomeAnchor resolver requires incomeAnchor mode"⟩
    {𝕊:
      resolved ↩ result.Error ⟨def.mode,asOfText,"observation_invalid","incomeAnchor requires strict explicit as-of text"⟩
      {𝕊:
        resolved ↩ result.Error ⟨def.mode,asOfText,"actual_facts_invalid","Actual facts must be admitted from actual.journal"⟩
        {𝕊:
          resolved ↩ result.Error ⟨def.mode,asOfText,"plan_facts_invalid","Plan facts must be admitted from plan.journal"⟩
          {𝕊:
            resolved ↩ result.Error ⟨def.mode,asOfText,"income_anchor_offset_unsupported","incomeAnchor resolver supports only admitted offset 0"⟩
            {𝕊:
              incomeAccount ← def.income_account
              actualKnown ← incomeAccount Contains actualFacts.accounts.key
              planKnown ← incomeAccount Contains planFacts.accounts.key
              resolved ↩ result.Error ⟨def.mode,asOfText,"income_account_facts_mismatch","income Account must occur in Actual and Plan Account facts"⟩
              {𝕊:
                actualAccIdx ← incomeAccount IndexOf actualFacts.accounts.key
                planAccIdx ← incomeAccount IndexOf planFacts.accounts.key
                currency ← actualAccIdx ⊑ actualFacts.accounts.currency

                accCompat ← ((actualAccIdx⊑actualFacts.accounts.role)≡"income") ∧ ((planAccIdx⊑planFacts.accounts.role)≡"income") ∧ (planAccIdx⊑planFacts.accounts.currency)≡currency
                actualDomainKnown ← currency Contains actualFacts.domains.code
                planDomainKnown ← currency Contains planFacts.domains.code
                planDomainAcceptable ← planDomainKnown ∨ planFacts.transactions.count=0
                layerKnown ← ("actual" Contains actualFacts.layers.name) ∧ "plan" Contains planFacts.layers.name
                evidenceCompat ← accCompat ∧ actualDomainKnown ∧ planDomainAcceptable ∧ layerKnown
                resolved ↩ result.Error ⟨def.mode,asOfText,"income_account_facts_mismatch","income Account role, currency, domain, and layer evidence must agree"⟩
                {𝕊:
                  actualDomainIdx ← currency IndexOf actualFacts.domains.code
                  planDomainIdx ← ¯1
                  {𝕊: planDomainIdx ↩ currency IndexOf planFacts.domains.code}⍟planDomainKnown @
                  actualLayerIdx ← "actual" IndexOf actualFacts.layers.name
                  planLayerIdx ← "plan" IndexOf planFacts.layers.name
                  asOfOrd ← dates.Ordinal asOfText

                  obsMask ← (actualDomainIdx=actualFacts.transactions.domain_index) ∧ (actualLayerIdx=actualFacts.transactions.layer_index) ∧ actualFacts.transactions.date_ordinal≤asOfOrd
                  obsIndices ← obsMask / actualFacts.transactions.index
                  resolved ↩ result.Unavailable ⟨def.mode,asOfText,"actual_observation_missing"⟩
                  {𝕊:
                    actualFrontier ← ⌈´ obsMask / actualFacts.transactions.date_ordinal
                    actualIncMask ← (actualDomainIdx=actualFacts.postings.domain_index) ∧ (actualLayerIdx=actualFacts.postings.layer_index)
                    actualIncMask ∧↩ (actualAccIdx=actualFacts.postings.account_index) ∧ ("credit"⊸≡¨actualFacts.postings.side) ∧ (actualFacts.postings.coefficient<0) ∧ (actualFacts.postings.date_ordinal≤asOfOrd)
                    actualIncDates ← actualIncMask / actualFacts.postings.date_ordinal
                    resolved ↩ result.Unavailable ⟨def.mode,asOfText,"actual_income_anchor_missing"⟩
                    {𝕊:
                      startOrd ← ⌈´ actualIncDates
                      startPostingIdxs ← (actualIncMask ∧ actualFacts.postings.date_ordinal=startOrd) / actualFacts.postings.index
                      startTxIdxs ← {𝕩⊑actualFacts.postings.transaction_index}¨ startPostingIdxs

                      planIncMask ← (planDomainIdx=planFacts.postings.domain_index) ∧ (planLayerIdx=planFacts.postings.layer_index)
                      planIncMask ∧↩ (planAccIdx=planFacts.postings.account_index) ∧ ("credit"⊸≡¨planFacts.postings.side) ∧ (planFacts.postings.coefficient<0) ∧ (planFacts.postings.date_ordinal>actualFrontier)
                      planIncDates ← planIncMask / planFacts.postings.date_ordinal
                      resolved ↩ result.Unavailable ⟨def.mode,asOfText,"planned_income_anchor_missing"⟩
                      {𝕊:
                        endOrd ← ⌊´ planIncDates
                        endPostingIdxs ← (planIncMask ∧ planFacts.postings.date_ordinal=endOrd) / planFacts.postings.index
                        endTxIdxs ← {𝕩⊑planFacts.postings.transaction_index}¨ endPostingIdxs

                        resolved ↩ result.Success ⟨
                          def.mode,asOfText,
                          (⊑startTxIdxs) ⊑ actualFacts.transactions.date_text,
                          (⊑endTxIdxs) ⊑ planFacts.transactions.date_text,
                          References ⟨actualFacts,startTxIdxs⟩,
                          References ⟨planFacts,endTxIdxs⟩
                        ⟩
                      }⍟(0<≠planIncDates) @
                    }⍟(0<≠actualIncDates) @
                  }⍟(0<≠obsIndices) @
                }⍟evidenceCompat @
              }⍟(actualKnown ∧ planKnown) @
            }⍟(def.offset=0) @
          }⍟(reference.SourceIs ⟨planFacts,"plan.journal"⟩) @
        }⍟(reference.SourceIs ⟨actualFacts,"actual.journal"⟩) @
      }⍟(dates.IsValid asOfText) @
    }⍟(def.mode≡"incomeAnchor") @
  }⍟(admittedCycle.state≡"ok") @
  resolved
}

{Resolve⇐Resolve}
