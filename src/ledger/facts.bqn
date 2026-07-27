# Canonical readonly Transaction/Posting facts projected from complete admission.
# Input is the production complete-admission result, never a context, source path,
# historical transaction carrier, Plan/Budget row, Cube, or report ViewModel.

dates ← •Import "date_ordinal.bqn"
empty ← ⟨⟩

Contains ← {𝕊 item‿items: ∨´ 0 ∾ item⊸≡¨ items }
Unique ← {𝕊 items:
  result ← empty
  {𝕊 item: {𝕊: result ∾↩ ⟨item⟩}⍟(¬Contains ⟨item,result⟩) @}¨ items
  result
}
IndexOf ← {𝕊 item‿items: ⊑ (item⊸≡¨ items) ⊐ 1 }
Diagnostic ← {𝕊 codeText‿messageText:
  {severity⇐"error",stage⇐"ledger_facts",code⇐codeText,message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid / ⟨diagnostic⟩ }
Sum0 ← { +´ 0 ∾ 𝕩 }

EmptyTransactionFacts ← {𝕊:
  {
    count⇐0,index⇐empty,transaction_id⇐empty,identity_kind⇐empty,
    source_start_line⇐empty,source_end_line⇐empty,date_text⇐empty,date_ordinal⇐empty,
    description⇐empty,layer_index⇐empty,domain_index⇐empty,calculation_scale⇐empty,
    txn_id⇐empty,plan_id⇐empty,allocation_id⇐empty,execution_envelope⇐empty,
    actual_event_id⇐empty
  }
}
EmptyPostingFacts ← {𝕊:
  {
    count⇐0,index⇐empty,posting_id⇐empty,transaction_index⇐empty,
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
  {𝕊:
    transactions ↩ admitted.transactions
    declaredDomains ↩ admitted.declared_domains
    diagnostics ∾↩ AddIf ⟨0 = ≠declaredDomains, Diagnostic ⟨"domain_missing","complete admission must retain at least one explicit domain"⟩⟩
  }⍟(admitted.state ≡ "ok") @

  layerNames ← Unique {𝕩.layer_name}¨ transactions
  accountKeys ← admittedAccounts.key
  accountCurrencies ← admittedAccounts.currency
  accountRoles ← admittedAccounts.role
  accountColumnsAligned ← ((≠accountKeys) = ≠accountCurrencies) ∧ (≠accountKeys) = ≠accountRoles
  diagnostics ∾↩ AddIf ⟨(≠accountKeys) ≠ ≠accountCurrencies, Diagnostic ⟨"account_columns_misaligned","account key and currency columns must align"⟩⟩
  diagnostics ∾↩ AddIf ⟨(≠accountKeys) ≠ ≠accountRoles, Diagnostic ⟨"account_columns_misaligned","account key and role columns must align"⟩⟩
  diagnostics ∾↩ AddIf ⟨(≠accountKeys) ≠ ≠Unique accountKeys, Diagnostic ⟨"account_key_duplicate","account keys must be unique"⟩⟩

  {𝕊 transaction:
    diagnostics ∾↩ AddIf ⟨¬dates.IsValid transaction.date, Diagnostic ⟨"transaction_date_invalid","admitted transaction date must be strict ISO Gregorian text"⟩⟩
    diagnostics ∾↩ AddIf ⟨¬Contains ⟨transaction.domain,declaredDomains⟩, Diagnostic ⟨"transaction_domain_undeclared","transaction domain must occur in the admitted domain table"⟩⟩
    diagnostics ∾↩ AddIf ⟨0 = ≠transaction.layer_name, Diagnostic ⟨"transaction_layer_missing","transaction layer must be explicit"⟩⟩
    diagnostics ∾↩ AddIf ⟨0 = ≠transaction.source_event_id, Diagnostic ⟨"transaction_identity_missing","transaction identity must be explicit after complete admission"⟩⟩
    {𝕊 posting:
      accountKnown ← Contains ⟨posting.account_key,accountKeys⟩
      diagnostics ∾↩ AddIf ⟨¬accountKnown, Diagnostic ⟨"posting_account_unknown","posting account must occur in the admitted account table"⟩⟩
      {𝕊:
        ai ← IndexOf ⟨posting.account_key,accountKeys⟩
        diagnostics ∾↩ AddIf ⟨(ai⊑accountCurrencies) ≢ transaction.domain, Diagnostic ⟨"posting_account_domain_mismatch","posting account currency must equal transaction domain"⟩⟩
      }⍟(accountKnown ∧ accountColumnsAligned) @
    }¨ transaction.postings
    coefficients ← {𝕩.normalized_coefficient}¨ transaction.postings
    diagnostics ∾↩ AddIf ⟨0 = ≠coefficients, Diagnostic ⟨"transaction_postings_missing","transaction must contain postings"⟩⟩
    diagnostics ∾↩ AddIf ⟨0 ≠ Sum0 coefficients, Diagnostic ⟨"transaction_unbalanced","normalized posting coefficients must sum to zero"⟩⟩
  }¨ transactions

  transactionIds ← {𝕩.source_event_id}¨ transactions
  diagnostics ∾↩ AddIf ⟨(≠transactionIds) ≠ ≠Unique transactionIds, Diagnostic ⟨"transaction_identity_duplicate","canonical transaction identities must be unique"⟩⟩

  transactionFacts ← EmptyTransactionFacts @
  postingFacts ← EmptyPostingFacts @
  {𝕊:
    transactionIndex ← ↕≠transactions
    transactionFacts ↩ {
      count⇐≠transactions,
      index⇐transactionIndex,
      transaction_id⇐{𝕩.source_event_id}¨ transactions,
      identity_kind⇐{𝕩.identity_kind}¨ transactions,
      source_start_line⇐{𝕩.source_start_line}¨ transactions,
      source_end_line⇐{𝕩.source_end_line}¨ transactions,
      date_text⇐{𝕩.date}¨ transactions,
      date_ordinal⇐{dates.Ordinal 𝕩.date}¨ transactions,
      description⇐{𝕩.description}¨ transactions,
      layer_index⇐{IndexOf ⟨𝕩.layer_name,layerNames⟩}¨ transactions,
      domain_index⇐{IndexOf ⟨𝕩.domain,declaredDomains⟩}¨ transactions,
      calculation_scale⇐{𝕩.calculation_scale}¨ transactions,
      txn_id⇐{𝕩.txn_id}¨ transactions,
      plan_id⇐{𝕩.plan_id}¨ transactions,
      allocation_id⇐{𝕩.allocation_id}¨ transactions,
      execution_envelope⇐{𝕩.execution_envelope}¨ transactions,
      actual_event_id⇐{𝕩.actual_event_id}¨ transactions
    }

    postingRows ← ∾ {𝕊 ti:
      transaction ← ti⊑transactions
      {𝕊 posting:
        {
          posting_id⇐posting.posting_id,
          transaction_index⇐ti,
          transaction_posting_index⇐posting.posting_index,
          date_ordinal⇐dates.Ordinal transaction.date,
          account_index⇐IndexOf ⟨posting.account_key,accountKeys⟩,
          layer_index⇐IndexOf ⟨transaction.layer_name,layerNames⟩,
          domain_index⇐IndexOf ⟨transaction.domain,declaredDomains⟩,
          coefficient⇐posting.normalized_coefficient,
          scale⇐transaction.calculation_scale,
          side⇐posting.side,
          source_line⇐posting.source_line,
          source_coefficient⇐posting.source_coefficient,
          source_scale⇐posting.source_scale,
          amount_text⇐posting.amount_text
        }
      }¨ transaction.postings
    }¨ transactionIndex
    postingFacts ↩ {
      count⇐≠postingRows,index⇐↕≠postingRows,
      posting_id⇐{𝕩.posting_id}¨ postingRows,
      transaction_index⇐{𝕩.transaction_index}¨ postingRows,
      transaction_posting_index⇐{𝕩.transaction_posting_index}¨ postingRows,
      date_ordinal⇐{𝕩.date_ordinal}¨ postingRows,
      account_index⇐{𝕩.account_index}¨ postingRows,
      layer_index⇐{𝕩.layer_index}¨ postingRows,
      domain_index⇐{𝕩.domain_index}¨ postingRows,
      coefficient⇐{𝕩.coefficient}¨ postingRows,
      scale⇐{𝕩.scale}¨ postingRows,
      side⇐{𝕩.side}¨ postingRows,
      source_line⇐{𝕩.source_line}¨ postingRows,
      source_coefficient⇐{𝕩.source_coefficient}¨ postingRows,
      source_scale⇐{𝕩.source_scale}¨ postingRows,
      amount_text⇐{𝕩.amount_text}¨ postingRows
    }
  }⍟(0 = ≠diagnostics) @

  {
    state⇐(0=≠diagnostics)⊑"error"‿"ok",
    transactions⇐transactionFacts,
    postings⇐postingFacts,
    domains⇐{count⇐≠declaredDomains,index⇐↕≠declaredDomains,code⇐declaredDomains},
    accounts⇐{count⇐≠accountKeys,index⇐↕≠accountKeys,key⇐accountKeys,currency⇐accountCurrencies,role⇐accountRoles},
    layers⇐{count⇐≠layerNames,index⇐↕≠layerNames,name⇐layerNames},
    diagnostics⇐diagnostics
  }
}

{Project⇐Project}
