# Pure Budget-specific admission over validated canonical Journal accounting.
#
# Journal admission owns syntax, dates, descriptions, exact amounts, commodities,
# Account resolution, balancing, elision, Posting order, and source coordinates.
# This owner adds only Household Budget movement meaning: every transaction is
# exactly two Budget postings, source order is from then to, and their exact
# resolved amounts are opposites. No legacy allocation row or writer policy is involved.

journal ← •Import "journal_complete_admission.bqn"
empty ← ⟨⟩
sourceName ← "budget.journal"

Diagnostic ← {𝕊 codeText‿lineNumber‿messageText:
  {severity⇐"error",stage⇐"ledger_budget_journal_admission",code⇐codeText,line⇐lineNumber,message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}
IndexOf ← {𝕊 item‿items: ⊑items⊐⟨item⟩}

MapPosting ← {𝕊 posting‿transactionId:
  {
    posting_id⇐transactionId∾":"∾•Fmt posting.posting_index,
    posting_index⇐posting.posting_index,
    side⇐posting.side,
    source_line⇐posting.source_line,
    account_key⇐posting.account_key,
    account_currency⇐posting.account_currency,
    commodity⇐posting.commodity,
    amount_text⇐posting.amount_text,
    source_coefficient⇐posting.source_coefficient,
    source_scale⇐posting.source_scale,
    normalized_coefficient⇐posting.normalized_coefficient
  }
}

MapTransaction ← {𝕊 transaction:
  transactionId ← sourceName∾":line:"∾•Fmt transaction.source_start_line
  {
    source_event_id⇐transactionId,
    identity_kind⇐"physical_fallback",
    source_start_line⇐transaction.source_start_line,
    source_end_line⇐transaction.source_end_line,
    date⇐transaction.date,
    status_marker⇐transaction.status_marker,
    description⇐transaction.description,
    layer_name⇐"budget",
    txn_id⇐transaction.txn_id,
    plan_id⇐transaction.plan_id,
    allocation_id⇐transaction.allocation_id,
    execution_envelope⇐transaction.execution_envelope,
    actual_event_id⇐transaction.actual_event_id,
    domain⇐transaction.domain,
    calculation_scale⇐transaction.calculation_scale,
    metadata⇐transaction.metadata,
    postings⇐{MapPosting ⟨𝕩,transactionId⟩}¨transaction.postings
  }
}

Admit ← {𝕊 raw‿accounts‿registry:
  accounting ← journal.Admit ⟨raw,accounts,registry⟩
  diagnostics ← accounting.diagnostics
  transactions ← empty
  domains ← empty
  {𝕊:
    domains↩accounting.declared_domains
    sourceTransactions ← accounting.transactions
    {𝕊 transaction:
      postings ← transaction.postings
      binary ← 2=≠postings
      diagnostics∾↩AddIf ⟨¬binary,Diagnostic ⟨"budget_movement_requires_binary_transaction",transaction.source_start_line,"Budget movement transaction requires exactly two postings"⟩⟩
      {𝕊:
        roles ← {𝕊 posting:
          i ← IndexOf ⟨posting.account_key,accounts.key⟩
          (i<accounts.count)⊑⟨"",i⊑accounts.role⟩
        }¨postings
        diagnostics∾↩AddIf ⟨¬∧´"budget"⊸≡¨roles,Diagnostic ⟨"budget_movement_posting_not_budget",transaction.source_start_line,"Budget movement postings must resolve to Budget Accounts"⟩⟩
        from‿to ← postings
        exactOpposites ← (from.commodity≡to.commodity) ∧ 0=from.normalized_coefficient+to.normalized_coefficient
        diagnostics∾↩AddIf ⟨¬exactOpposites,Diagnostic ⟨"budget_movement_postings_not_exact_opposites",transaction.source_start_line,"Budget movement postings must be exact opposites"⟩⟩
      }⍟binary @
    }¨sourceTransactions
    {𝕊:transactions↩MapTransaction¨sourceTransactions}⍟(0=≠diagnostics) @
  }⍟(accounting.state≡"ok") @
  {𝕊:transactions↩empty ⋄ domains↩empty}⍟(0<≠diagnostics) @
  {
    state⇐(0=≠diagnostics)⊑"error"‿"ok",
    source_name⇐sourceName,
    declared_domains⇐domains,
    declared_layers⇐⟨"budget"⟩,
    transactions⇐transactions,
    diagnostics⇐diagnostics
  }
}

{Admit⇐Admit}
