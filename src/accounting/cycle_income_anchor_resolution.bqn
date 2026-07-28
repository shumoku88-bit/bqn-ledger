# Pure incomeAnchor resolution from admitted Actual/Plan Facts and explicit as-of.
# Source-qualified contributors remain separate; no cross-source amount is added.

result ← •Import "cycle_result.bqn"
dates ← •Import "../ledger/date_ordinal.bqn"
empty ← ⟨⟩

Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}
Unique ← {𝕊 items:
  output ← empty
  {𝕊 item: {𝕊: output∾↩⟨item⟩}⍟(¬Contains ⟨item,output⟩) @}¨items
  output
}
IndexOf ← {𝕊 item‿items: ⊑(item⊸≡¨items)⊐1}
SourceOk ← {𝕊 facts‿sourceName:
  ok ← 0
  {𝕊: ok↩(⊑facts.sources.name)≡sourceName}⍟((facts.state≡"ok") ∧ facts.sources.count=1) @
  ok
}
Reference ← {𝕊 facts‿transactionIndex:
  {source⇐⊑facts.sources.name,transaction_id⇐transactionIndex⊑facts.transactions.transaction_id}
}
References ← {𝕊 facts‿indices: {Reference ⟨facts,𝕩⟩}¨Unique indices}

Resolve ← {𝕊 admittedCycle‿asOfText‿actualFacts‿planFacts:
  resolved ← result.Error ⟨"incomeAnchor",asOfText,"cycle_admission_not_ok","cycle definition must be admitted"⟩
  {𝕊:
    definition ← admittedCycle.definition
    resolved↩result.Error ⟨definition.mode,asOfText,"cycle_mode_mismatch","incomeAnchor resolver requires incomeAnchor mode"⟩
    {𝕊:
      resolved↩result.Error ⟨definition.mode,asOfText,"observation_invalid","incomeAnchor requires strict explicit as-of text"⟩
      {𝕊:
        resolved↩result.Error ⟨definition.mode,asOfText,"actual_facts_invalid","Actual facts must be admitted from actual.journal"⟩
        {𝕊:
          resolved↩result.Error ⟨definition.mode,asOfText,"plan_facts_invalid","Plan facts must be admitted from plan.tsv"⟩
          {𝕊:
            resolved↩result.Error ⟨definition.mode,asOfText,"income_anchor_offset_unsupported","incomeAnchor resolver supports only admitted offset 0"⟩
            {𝕊:
              incomeAccount ← definition.income_account
              actualKnown ← Contains ⟨incomeAccount,actualFacts.accounts.key⟩
              planKnown ← Contains ⟨incomeAccount,planFacts.accounts.key⟩
              resolved↩result.Error ⟨definition.mode,asOfText,"income_account_facts_mismatch","income Account must occur in Actual and Plan Account facts"⟩
              {𝕊:
                actualAccountIndex ← IndexOf ⟨incomeAccount,actualFacts.accounts.key⟩
                planAccountIndex ← IndexOf ⟨incomeAccount,planFacts.accounts.key⟩
                currency ← actualAccountIndex⊑actualFacts.accounts.currency
                accountCompatible ← (actualAccountIndex⊑actualFacts.accounts.role)≡"income"
                accountCompatible ∧↩ (planAccountIndex⊑planFacts.accounts.role)≡"income"
                accountCompatible ∧↩ (planAccountIndex⊑planFacts.accounts.currency)≡currency
                actualDomainKnown ← Contains ⟨currency,actualFacts.domains.code⟩
                planDomainKnown ← Contains ⟨currency,planFacts.domains.code⟩
                planDomainAcceptable ← planDomainKnown ∨ planFacts.transactions.count=0
                layerKnown ← (Contains ⟨"actual",actualFacts.layers.name⟩) ∧ Contains ⟨"plan",planFacts.layers.name⟩
                evidenceCompatible ← accountCompatible ∧ actualDomainKnown ∧ planDomainAcceptable ∧ layerKnown
                resolved↩result.Error ⟨definition.mode,asOfText,"income_account_facts_mismatch","income Account role, currency, domain, and layer evidence must agree"⟩
                {𝕊:
                  actualDomainIndex ← IndexOf ⟨currency,actualFacts.domains.code⟩
                  planDomainIndex ← ¯1
                  {𝕊: planDomainIndex↩IndexOf ⟨currency,planFacts.domains.code⟩}⍟planDomainKnown @
                  actualLayerIndex ← IndexOf ⟨"actual",actualFacts.layers.name⟩
                  planLayerIndex ← IndexOf ⟨"plan",planFacts.layers.name⟩
                  asOfOrdinal ← dates.Ordinal asOfText

                  observedMask ← (actualDomainIndex=actualFacts.transactions.domain_index) ∧ (actualLayerIndex=actualFacts.transactions.layer_index) ∧ actualFacts.transactions.date_ordinal≤asOfOrdinal
                  observedIndices ← observedMask/actualFacts.transactions.index
                  {𝕊: resolved↩result.Unavailable ⟨definition.mode,asOfText,"actual_observation_missing"⟩}⍟(0=≠observedIndices) @
                  {𝕊:
                    actualFrontier ← ⌈´observedMask/actualFacts.transactions.date_ordinal
                    actualIncomeMask ← (actualDomainIndex=actualFacts.postings.domain_index) ∧ (actualLayerIndex=actualFacts.postings.layer_index)
                    actualIncomeMask ∧↩ actualAccountIndex=actualFacts.postings.account_index
                    actualIncomeMask ∧↩ "credit"⊸≡¨actualFacts.postings.side
                    actualIncomeMask ∧↩ actualFacts.postings.coefficient<0
                    actualIncomeMask ∧↩ actualFacts.postings.date_ordinal≤asOfOrdinal
                    actualIncomeDates ← actualIncomeMask/actualFacts.postings.date_ordinal
                    {𝕊: resolved↩result.Unavailable ⟨definition.mode,asOfText,"actual_income_anchor_missing"⟩}⍟(0=≠actualIncomeDates) @
                    {𝕊:
                      startOrdinal ← ⌈´actualIncomeDates
                      startPostingIndices ← (actualIncomeMask ∧ actualFacts.postings.date_ordinal=startOrdinal)/actualFacts.postings.index
                      startTransactionIndices ← {𝕩⊑actualFacts.postings.transaction_index}¨startPostingIndices

                      planIncomeMask ← (planDomainIndex=planFacts.postings.domain_index) ∧ (planLayerIndex=planFacts.postings.layer_index)
                      planIncomeMask ∧↩ planAccountIndex=planFacts.postings.account_index
                      planIncomeMask ∧↩ "credit"⊸≡¨planFacts.postings.side
                      planIncomeMask ∧↩ planFacts.postings.coefficient<0
                      planIncomeMask ∧↩ planFacts.postings.date_ordinal>actualFrontier
                      planIncomeDates ← planIncomeMask/planFacts.postings.date_ordinal
                      {𝕊: resolved↩result.Unavailable ⟨definition.mode,asOfText,"planned_income_anchor_missing"⟩}⍟(0=≠planIncomeDates) @
                      {𝕊:
                        endOrdinal ← ⌊´planIncomeDates
                        endPostingIndices ← (planIncomeMask ∧ planFacts.postings.date_ordinal=endOrdinal)/planFacts.postings.index
                        endTransactionIndices ← {𝕩⊑planFacts.postings.transaction_index}¨endPostingIndices
                        resolved↩result.Success ⟨
                          definition.mode,asOfText,
                          (⊑startTransactionIndices)⊑actualFacts.transactions.date_text,
                          (⊑endTransactionIndices)⊑planFacts.transactions.date_text,
                          References ⟨actualFacts,startTransactionIndices⟩,
                          References ⟨planFacts,endTransactionIndices⟩
                        ⟩
                      }⍟(0<≠planIncomeDates) @
                    }⍟(0<≠actualIncomeDates) @
                  }⍟(0<≠observedIndices) @
                }⍟evidenceCompatible @
              }⍟(actualKnown ∧ planKnown) @
            }⍟(definition.offset=0) @
          }⍟(SourceOk ⟨planFacts,"plan.tsv"⟩) @
        }⍟(SourceOk ⟨actualFacts,"actual.journal"⟩) @
      }⍟(dates.IsValid asOfText) @
    }⍟(definition.mode≡"incomeAnchor") @
  }⍟(admittedCycle.state≡"ok") @
  resolved
}

{Resolve⇐Resolve}
