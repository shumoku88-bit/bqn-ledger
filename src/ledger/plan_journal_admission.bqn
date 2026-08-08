# Pure Plan-specific admission over already validated canonical Journal accounting.
#
# Journal admission owns dates, descriptions, exact amounts, commodities, Account
# resolution, balancing, elision, Posting order, and source coordinates. This owner
# adds only Plan meaning: every transaction has one valid unique plan-id, Plan is
# the source layer, and plan-id supplies its durable relation identity. Whole
# multi-Posting transactions are retained unchanged in shape.

journal ← •Import "journal_complete_admission.bqn"

space ← @+32
tab ← @+9
lf ← @+10
cr ← @+13
empty ← ⟨⟩
sourceName ← "plan.journal"

Diagnostic ← {𝕊 codeText‿lineNumber‿messageText:
  {severity⇐"error",stage⇐"ledger_plan_journal_admission",code⇐codeText,line⇐lineNumber,message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}
IsWhitespace ← {𝕊 c: (c=space) ∨ (c=tab) ∨ (c=lf) ∨ c=cr }
PlanIdValid ← {𝕊 value: (0<≠value) ∧ ¬∨´0∾IsWhitespace¨value }

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
  transactionId ← sourceName∾":plan_id:"∾transaction.plan_id
  {
    source_event_id⇐transactionId,
    identity_kind⇐"durable_relation",
    source_start_line⇐transaction.source_start_line,
    source_end_line⇐transaction.source_end_line,
    date⇐transaction.date,
    status_marker⇐transaction.status_marker,
    description⇐transaction.description,
    layer_name⇐"plan",
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
    sourceTransactions ← accounting.transactions
    domains↩accounting.declared_domains
    planIds ← {𝕩.plan_id}¨sourceTransactions
    {𝕊 i:
      transaction ← i⊑sourceTransactions
      planId ← i⊑planIds
      diagnostics∾↩AddIf ⟨0=≠planId,Diagnostic ⟨"plan_id_missing",transaction.source_start_line,"Plan transaction requires plan-id metadata"⟩⟩
      diagnostics∾↩AddIf ⟨(0<≠planId) ∧ ¬PlanIdValid planId,Diagnostic ⟨"plan_id_invalid",transaction.source_start_line,"plan-id must be nonempty and contain no whitespace"⟩⟩
    }¨↕≠sourceTransactions
    diagnostics∾↩AddIf ⟨(≠planIds)≠≠⍷planIds,Diagnostic ⟨"plan_id_duplicate",0,"one plan-id may identify only one Plan transaction"⟩⟩
    {𝕊: transactions↩MapTransaction¨sourceTransactions}⍟(0=≠diagnostics) @
  }⍟(accounting.state≡"ok") @
  {𝕊: transactions↩empty ⋄ domains↩empty}⍟(0<≠diagnostics) @
  {
    state⇐(0=≠diagnostics)⊑"error"‿"ok",
    source_name⇐sourceName,
    declared_domains⇐domains,
    declared_layers⇐⟨"plan"⟩,
    transactions⇐transactions,
    diagnostics⇐diagnostics
  }
}

{Admit⇐Admit}
