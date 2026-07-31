# Pure Actual Account closing balances through one explicit observation.

scale ← •Import "../ledger/exact_scale.bqn"
reference ← •Import "fact_reference.bqn"
empty ← ⟨⟩

Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}
IndexOf ← {𝕊 item‿items: ⊑(item⊸≡¨items)⊐1}
Diagnostic ← {𝕊 codeText‿messageText:
  {severity⇐"error",stage⇐"accounting_account_balance",code⇐codeText,message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}
EmptyAccounts ← {𝕊:
  {count⇐0,index⇐empty,account_index⇐empty,account_key⇐empty,role⇐empty,type⇐empty,closing⇐empty,contributors⇐empty}
}

Build ← {𝕊 facts‿domainCode‿observationOrdinal:
  diagnostics ← empty
  diagnostics ∾↩ AddIf ⟨¬reference.SourceIs ⟨facts,"actual.journal"⟩,Diagnostic ⟨"actual_facts_invalid","Actual facts must be admitted from actual.journal"⟩⟩
  diagnostics ∾↩ AddIf ⟨¬Contains ⟨domainCode,facts.domains.code⟩,Diagnostic ⟨"domain_unknown","selected domain must occur in Actual Domain facts"⟩⟩
  observationInvalid ← (observationOrdinal<0) ∨ observationOrdinal≠⌊observationOrdinal
  diagnostics ∾↩ AddIf ⟨observationInvalid,Diagnostic ⟨"observation_invalid","observation ordinal must be a nonnegative integer"⟩⟩

  accounts ← EmptyAccounts @
  amountScale ← 0
  balanced ← 0
  {𝕊:
    domainIndex ← IndexOf ⟨domainCode,facts.domains.code⟩
    layerKnown ← Contains ⟨"actual",facts.layers.name⟩
    diagnostics ∾↩ AddIf ⟨¬layerKnown,Diagnostic ⟨"actual_layer_unknown","Actual layer must occur in Layer facts"⟩⟩
    {𝕊:
      layerIndex ← IndexOf ⟨"actual",facts.layers.name⟩
      postings ← facts.postings
      selectedMask ← (domainIndex=postings.domain_index) ∧ (layerIndex=postings.layer_index) ∧ postings.date_ordinal≤observationOrdinal
      selectedIndices ← selectedMask/postings.index
      selectedAccountIndices ← selectedMask/postings.account_index
      selectedCoefficients ← selectedMask/postings.coefficient
      selectedScales ← selectedMask/postings.scale
      amountScale↩⌈´0∾selectedScales
      normalized ← selectedCoefficients {scale.Normalize ⟨𝕨,𝕩,amountScale⟩}¨ selectedScales
      normalizationOk ← ∧´1∾{𝕩.state≡"ok"}¨normalized
      diagnostics ∾↩ AddIf ⟨¬normalizationOk,Diagnostic ⟨"coefficient_normalization_failed","selected Postings cannot normalize exactly"⟩⟩
      {𝕊:
        normalizedCoefficients ← {𝕩.coefficient}¨normalized
        accountIndices ← (domainCode⊸≡¨facts.accounts.currency)/facts.accounts.index
        accountCount ← ≠accountIndices

        # p: selected Posting cells in source order; a: domain Accounts in canonical Account order.
        # p→a Group preserves contributor order; the extra a coordinate retains trailing empty Accounts.
        accountCoordinates ← accountIndices⊐selectedAccountIndices
        matched ← accountCoordinates<accountCount
        groupCoordinates ← (matched/accountCoordinates)∾⟨accountCount⟩
        coefficientGroups ← groupCoordinates⊔matched/normalizedCoefficients
        postingGroups ← groupCoordinates⊔matched/selectedIndices
        sumResults ← scale.Sum¨coefficientGroups
        sumOk ← {𝕩.state≡"ok"}¨sumResults
        diagnostics ∾↩ ∾{𝕊 ok:
          AddIf ⟨¬ok,Diagnostic ⟨"coefficient_sum_failed","Account closing exceeds exact range"⟩⟩
        }¨sumOk
        {𝕊:
          closing ← {𝕩.coefficient}¨sumResults
          total ← scale.Sum closing
          diagnostics ∾↩ AddIf ⟨total.state≢"ok",Diagnostic ⟨"coefficient_sum_failed","Account closing total exceeds exact range"⟩⟩
          {𝕊:
            balanced↩total.coefficient=0
            accounts↩{
              count⇐accountCount,index⇐↕accountCount,
              account_index⇐accountIndices,account_key⇐accountIndices⊏facts.accounts.key,
              role⇐accountIndices⊏facts.accounts.role,type⇐accountIndices⊏facts.accounts.type,
              closing⇐closing,
              contributors⇐{𝕊 indices: {reference.Posting ⟨facts,𝕩⟩}¨indices}¨postingGroups
            }
          }⍟(total.state≡"ok") @
        }⍟(∧´1∾sumOk) @
      }⍟normalizationOk @
    }⍟layerKnown @
  }⍟(0=≠diagnostics) @

  {𝕊: accounts↩EmptyAccounts @ ⋄ amountScale↩0 ⋄ balanced↩0}⍟(0<≠diagnostics) @
  {state⇐(0=≠diagnostics)⊑"error"‿"ok",domain⇐domainCode,observation_ordinal⇐observationOrdinal,scale⇐amountScale,accounts⇐accounts,balanced⇐balanced,diagnostics⇐diagnostics}
}

{Build⇐Build}
