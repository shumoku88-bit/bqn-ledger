# Canonical readonly Transaction/Posting facts projected from canonical admission.
# Input is never a context, source path, raw Plan/Budget row, historical carrier,
# Cube, TBDS, or report ViewModel. Source-specific empty-domain policy belongs to
# admission; generic projection requires a domain only when transactions exist.

dates ← •Import "date_ordinal.bqn"
empty ← ⟨⟩

Diagnostic ← {𝕊 codeText‿messageText:
  {severity⇐"error",stage⇐"ledger_facts",code⇐codeText,message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid / ⟨diagnostic⟩ }
Sum0 ← { +´ 0 ∾ 𝕩 }

EmptyTransactionFacts ← {𝕊:
  {
    count⇐0,index⇐empty,source_index⇐empty,transaction_id⇐empty,identity_kind⇐empty,
    source_start_line⇐empty,source_end_line⇐empty,date_text⇐empty,date_ordinal⇐empty,
    description⇐empty,status_marker⇐empty,metadata⇐empty,
    layer_index⇐empty,domain_index⇐empty,calculation_scale⇐empty,
    txn_id⇐empty,plan_id⇐empty,allocation_id⇐empty,execution_envelope⇐empty,
    actual_event_id⇐empty
  }
}
EmptyPostingFacts ← {𝕊:
  {
    count⇐0,index⇐empty,source_index⇐empty,posting_id⇐empty,transaction_index⇐empty,
    transaction_posting_index⇐empty,date_ordinal⇐empty,account_index⇐empty,
    layer_index⇐empty,domain_index⇐empty,coefficient⇐empty,scale⇐empty,side⇐empty,
    source_line⇐empty,source_coefficient⇐empty,source_scale⇐empty,amount_text⇐empty
  }
}

Project ← {𝕊 admitted‿admittedAccounts:
  diagnostics ← empty
  diagnostics ∾↩ AddIf ⟨admitted.state ≢ "ok", Diagnostic ⟨"admission_not_ok","complete admission must be ok before fact projection"⟩⟩
  transactions ← empty
  declaredDomains ← empty
  declaredLayers ← empty
  sourceName ← ""
  {𝕊:
    transactions ↩ admitted.transactions
    declaredDomains ↩ admitted.declared_domains
    declaredLayers ↩ admitted.declared_layers
    sourceName ↩ admitted.source_name
    diagnostics ∾↩ AddIf ⟨0=≠sourceName, Diagnostic ⟨"source_name_missing","canonical admission must declare one source name"⟩⟩
    diagnostics ∾↩ AddIf ⟨(0<≠transactions) ∧ 0=≠declaredDomains, Diagnostic ⟨"domain_missing","transactions require an admitted domain"⟩⟩
    diagnostics ∾↩ AddIf ⟨0=≠declaredLayers, Diagnostic ⟨"layer_missing","canonical admission must declare its source layer"⟩⟩
    diagnostics ∾↩ AddIf ⟨(≠declaredLayers)≠≠⍷declaredLayers, Diagnostic ⟨"layer_duplicate","declared source layers must be unique"⟩⟩
  }⍟(admitted.state ≡ "ok") @

  accountKeys ← admittedAccounts.key
  accountCurrencies ← admittedAccounts.currency
  accountRoles ← admittedAccounts.role
  accountTypes ← admittedAccounts.type
  accountMetadata ← admittedAccounts.metadata
  accountSourceRows ← admittedAccounts.source_row
  accountColumnLengths ← ≠¨⟨accountCurrencies,accountRoles,accountTypes,accountMetadata,accountSourceRows⟩
  accountColumnsAligned ← ∧´(≠accountKeys)=accountColumnLengths
  diagnostics ∾↩ AddIf ⟨¬accountColumnsAligned, Diagnostic ⟨"account_columns_misaligned","all account columns must align with account keys"⟩⟩
  diagnostics ∾↩ AddIf ⟨(≠accountKeys) ≠ ≠⍷accountKeys, Diagnostic ⟨"account_key_duplicate","account keys must be unique"⟩⟩

  # Classify the semantic join axes once. These coordinates are used both by
  # projection-invariant diagnostics and by successful Fact publication.
  transactionIndex ← ↕≠transactions
  transactionDates ← {𝕩.date}¨transactions
  transactionDomains ← {𝕩.domain}¨transactions
  transactionLayers ← {𝕩.layer_name}¨transactions
  transactionIds ← {𝕩.source_event_id}¨transactions
  transactionPostingCells ← {𝕩.postings}¨transactions
  postingCounts ← ≠¨transactionPostingCells
  postingStarts ← ¯1↓+`0∾postingCounts

  domainCoordinates ← declaredDomains⊐transactionDomains
  layerCoordinates ← declaredLayers⊐transactionLayers
  domainKnown ← domainCoordinates<≠declaredDomains
  layerKnown ← layerCoordinates<≠declaredLayers
  dateValid ← dates.IsValid¨transactionDates
  layerMissing ← 0=≠¨transactionLayers
  identityMissing ← 0=≠¨transactionIds

  postings ← ∾transactionPostingCells
  postingTransactionIndex ← ∾{𝕊 ti: (ti⊑postingCounts)⥊ti}¨transactionIndex
  postingAccountKeys ← {𝕩.account_key}¨postings
  accountCoordinates ← accountKeys⊐postingAccountKeys
  accountKnown ← accountCoordinates<≠accountKeys
  accountDomainMismatch ← (≠postings)⥊0
  {𝕊:
    postingAccountCurrencies ← accountCoordinates⊏(accountCurrencies∾⟨""⟩)
    postingDomains ← postingTransactionIndex⊏transactionDomains
    accountConstrainsDomain ← 0<≠¨postingAccountCurrencies
    sameDomain ← postingAccountCurrencies≡¨postingDomains
    accountDomainMismatch ↩ accountKnown ∧ accountConstrainsDomain ∧ ¬sameDomain
  }⍟accountColumnsAligned @

  transactionCoefficients ← {{𝕩.normalized_coefficient}¨𝕩}¨transactionPostingCells
  transactionBalanced ← 0=Sum0¨transactionCoefficients

  {𝕊 ti:
    diagnostics ∾↩ AddIf ⟨¬ti⊑dateValid, Diagnostic ⟨"transaction_date_invalid","admitted transaction date must be strict ISO Gregorian text"⟩⟩
    diagnostics ∾↩ AddIf ⟨¬ti⊑domainKnown, Diagnostic ⟨"transaction_domain_undeclared","transaction domain must occur in the admitted domain table"⟩⟩
    diagnostics ∾↩ AddIf ⟨ti⊑layerMissing, Diagnostic ⟨"transaction_layer_missing","transaction layer must be explicit"⟩⟩
    diagnostics ∾↩ AddIf ⟨¬ti⊑layerKnown, Diagnostic ⟨"transaction_layer_undeclared","transaction layer must occur in declared source layers"⟩⟩
    diagnostics ∾↩ AddIf ⟨ti⊑identityMissing, Diagnostic ⟨"transaction_identity_missing","transaction identity must be explicit after complete admission"⟩⟩

    postingCount ← ti⊑postingCounts
    postingStart ← ti⊑postingStarts
    localKnown ← postingCount↑postingStart↓accountKnown
    localMismatch ← postingCount↑postingStart↓accountDomainMismatch
    {𝕊 pi:
      diagnostics ∾↩ AddIf ⟨¬pi⊑localKnown, Diagnostic ⟨"posting_account_unknown","posting account must occur in the admitted account table"⟩⟩
      diagnostics ∾↩ AddIf ⟨pi⊑localMismatch, Diagnostic ⟨"posting_account_domain_mismatch","Account default Commodity must match transaction domain when declared"⟩⟩
    }¨↕postingCount

    diagnostics ∾↩ AddIf ⟨0=postingCount, Diagnostic ⟨"transaction_postings_missing","transaction must contain postings"⟩⟩
    diagnostics ∾↩ AddIf ⟨¬ti⊑transactionBalanced, Diagnostic ⟨"transaction_unbalanced","normalized posting coefficients must sum to zero"⟩⟩
  }¨transactionIndex

  diagnostics ∾↩ AddIf ⟨(≠transactionIds) ≠ ≠⍷transactionIds, Diagnostic ⟨"transaction_identity_duplicate","canonical transaction identities must be unique"⟩⟩

  transactionFacts ← EmptyTransactionFacts @
  postingFacts ← EmptyPostingFacts @
  {𝕊:
    transactionDateOrdinals ← dates.Ordinal¨transactionDates
    transactionScales ← {𝕩.calculation_scale}¨transactions
    transactionFacts ↩ {
      count⇐≠transactions,
      index⇐transactionIndex,source_index⇐(≠transactions)⥊0,
      transaction_id⇐transactionIds,
      identity_kind⇐{𝕩.identity_kind}¨transactions,
      source_start_line⇐{𝕩.source_start_line}¨transactions,
      source_end_line⇐{𝕩.source_end_line}¨transactions,
      date_text⇐transactionDates,
      date_ordinal⇐transactionDateOrdinals,
      description⇐{𝕩.description}¨transactions,
      status_marker⇐{𝕩.status_marker}¨transactions,
      metadata⇐{𝕩.metadata}¨transactions,
      layer_index⇐layerCoordinates,
      domain_index⇐domainCoordinates,
      calculation_scale⇐transactionScales,
      txn_id⇐{𝕩.txn_id}¨transactions,
      plan_id⇐{𝕩.plan_id}¨transactions,
      allocation_id⇐{𝕩.allocation_id}¨transactions,
      execution_envelope⇐{𝕩.execution_envelope}¨transactions,
      actual_event_id⇐{𝕩.actual_event_id}¨transactions
    }

    postingFacts ↩ {
      count⇐≠postings,index⇐↕≠postings,
      source_index⇐(≠postings)⥊0,
      posting_id⇐{𝕩.posting_id}¨postings,
      transaction_index⇐postingTransactionIndex,
      transaction_posting_index⇐{𝕩.posting_index}¨postings,
      date_ordinal⇐postingTransactionIndex⊏transactionDateOrdinals,
      account_index⇐accountCoordinates,
      layer_index⇐postingTransactionIndex⊏layerCoordinates,
      domain_index⇐postingTransactionIndex⊏domainCoordinates,
      coefficient⇐{𝕩.normalized_coefficient}¨postings,
      scale⇐postingTransactionIndex⊏transactionScales,
      side⇐{𝕩.side}¨postings,
      source_line⇐{𝕩.source_line}¨postings,
      source_coefficient⇐{𝕩.source_coefficient}¨postings,
      source_scale⇐{𝕩.source_scale}¨postings,
      amount_text⇐{𝕩.amount_text}¨postings
    }
  }⍟(0 = ≠diagnostics) @

  {
    state⇐(0=≠diagnostics)⊑"error"‿"ok",
    transactions⇐transactionFacts,
    postings⇐postingFacts,
    sources⇐{count⇐(0<≠sourceName),index⇐(0<≠sourceName)/⟨0⟩,name⇐(0<≠sourceName)/⟨sourceName⟩},
    domains⇐{count⇐≠declaredDomains,index⇐↕≠declaredDomains,code⇐declaredDomains},
    accounts⇐{
      count⇐≠accountKeys,index⇐↕≠accountKeys,key⇐accountKeys,currency⇐accountCurrencies,
      role⇐accountRoles,type⇐accountTypes,metadata⇐accountMetadata,source_row⇐accountSourceRows
    },
    layers⇐{count⇐≠declaredLayers,index⇐↕≠declaredLayers,name⇐declaredLayers},
    diagnostics⇐diagnostics
  }
}

{Project⇐Project}
