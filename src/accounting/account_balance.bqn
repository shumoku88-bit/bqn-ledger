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
      selectedMask ← (domainIndex=facts.postings.domain_index) ∧ (layerIndex=facts.postings.layer_index) ∧ facts.postings.date_ordinal≤observationOrdinal
      selectedIndices ← selectedMask/facts.postings.index
      selectedScales ← selectedMask/facts.postings.scale
      {𝕊: amountScale↩⌈´selectedScales}⍟(0<≠selectedScales) @
      normalized ← {𝕊 postingIndex:
        scale.Normalize ⟨postingIndex⊑facts.postings.coefficient,postingIndex⊑facts.postings.scale,amountScale⟩
      }¨selectedIndices
      normalizationOk ← ∧´1∾{𝕩.state≡"ok"}¨normalized
      diagnostics ∾↩ AddIf ⟨¬normalizationOk,Diagnostic ⟨"coefficient_normalization_failed","selected Postings cannot normalize exactly"⟩⟩
      {𝕊:
        normalizedCoefficients ← {𝕩.coefficient}¨normalized
        selectedAccountIndices ← selectedMask/facts.postings.account_index
        domainAccountIndices ← (domainCode⊸≡¨facts.accounts.currency)/facts.accounts.index
        rows ← empty
        {𝕊 accountIndex:
          accountMask ← accountIndex=selectedAccountIndices
          sum ← scale.Sum (accountMask/normalizedCoefficients)
          diagnostics ∾↩ AddIf ⟨sum.state≢"ok",Diagnostic ⟨"coefficient_sum_failed","Account closing exceeds exact range"⟩⟩
          {𝕊:
            contributorIndices ← accountMask/selectedIndices
            rows∾↩⟨{
              account_index⇐accountIndex,account_key⇐accountIndex⊑facts.accounts.key,
              role⇐accountIndex⊑facts.accounts.role,type⇐accountIndex⊑facts.accounts.type,
              closing⇐sum.coefficient,
              contributors⇐{reference.Posting ⟨facts,𝕩⟩}¨contributorIndices
            }⟩
          }⍟(sum.state≡"ok") @
        }¨domainAccountIndices
        {𝕊:
          total ← scale.Sum {𝕩.closing}¨rows
          diagnostics ∾↩ AddIf ⟨total.state≢"ok",Diagnostic ⟨"coefficient_sum_failed","Account closing total exceeds exact range"⟩⟩
          {𝕊:
            balanced↩total.coefficient=0
            accounts↩{
              count⇐≠rows,index⇐↕≠rows,
              account_index⇐{𝕩.account_index}¨rows,account_key⇐{𝕩.account_key}¨rows,
              role⇐{𝕩.role}¨rows,type⇐{𝕩.type}¨rows,
              closing⇐{𝕩.closing}¨rows,contributors⇐{𝕩.contributors}¨rows
            }
          }⍟(total.state≡"ok") @
        }⍟(0=≠diagnostics) @
      }⍟normalizationOk @
    }⍟layerKnown @
  }⍟(0=≠diagnostics) @

  {𝕊: accounts↩EmptyAccounts @ ⋄ amountScale↩0 ⋄ balanced↩0}⍟(0<≠diagnostics) @
  {state⇐(0=≠diagnostics)⊑"error"‿"ok",domain⇐domainCode,observation_ordinal⇐observationOrdinal,scale⇐amountScale,accounts⇐accounts,balanced⇐balanced,diagnostics⇐diagnostics}
}

{Build⇐Build}
