# Pure Plan-specific admission over already validated canonical Journal accounting.
#
# Journal admission owns dates, descriptions, exact amounts, commodities, Account
# resolution, balancing, elision, Posting order, and source coordinates. This owner
# adds only Plan meaning: every transaction has one valid unique plan-id, Plan is
# the source layer, and plan-id supplies its durable relation identity. Whole
# multi-Posting transactions are retained unchanged in shape. Narrow Plan-owned
# cancellation/supersession metadata is projected separately from the original
# transaction so a changed household commitment does not rewrite historical Plan
# date, amount, description, or postings.

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
Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}

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

MetadataValues ← {𝕊 key‿transaction:
  metadata ← transaction.metadata
  matches ← key⊸≡¨{𝕩.key}¨metadata
  {𝕩.value}¨matches/metadata
}

EmptyRetirementRows ← {𝕊:
  {count⇐0,index⇐empty,kind⇐empty,plan_id⇐empty,retired_on⇐empty,successor_plan_id⇐empty}
}

LocalRetirement ← {𝕊 transaction:
  diagnostics ← empty
  cancelValues ← MetadataValues ⟨"cancelled-on",transaction⟩
  supersededOnValues ← MetadataValues ⟨"superseded-on",transaction⟩
  supersededByValues ← MetadataValues ⟨"superseded-by",transaction⟩
  diagnostics ∾↩ AddIf ⟨1<≠cancelValues,
    Diagnostic ⟨"plan_retirement_metadata_duplicate",transaction.source_start_line,"cancelled-on may occur at most once per Plan"⟩⟩
  diagnostics ∾↩ AddIf ⟨1<≠supersededOnValues,
    Diagnostic ⟨"plan_retirement_metadata_duplicate",transaction.source_start_line,"superseded-on may occur at most once per Plan"⟩⟩
  diagnostics ∾↩ AddIf ⟨1<≠supersededByValues,
    Diagnostic ⟨"plan_retirement_metadata_duplicate",transaction.source_start_line,"superseded-by may occur at most once per Plan"⟩⟩
  hasCancel ← 1=≠cancelValues
  hasSupersededOn ← 1=≠supersededOnValues
  hasSupersededBy ← 1=≠supersededByValues
  hasSupersession ← hasSupersededOn ∨ hasSupersededBy

  diagnostics ∾↩ AddIf ⟨hasCancel ∧ hasSupersession,
    Diagnostic ⟨"plan_retirement_conflict",transaction.source_start_line,"cancelled-on cannot coexist with supersession metadata"⟩⟩
  diagnostics ∾↩ AddIf ⟨hasSupersededOn ∧ ¬hasSupersededBy,
    Diagnostic ⟨"plan_superseded_by_missing",transaction.source_start_line,"superseded-on requires superseded-by"⟩⟩
  diagnostics ∾↩ AddIf ⟨hasSupersededBy ∧ ¬hasSupersededOn,
    Diagnostic ⟨"plan_superseded_on_missing",transaction.source_start_line,"superseded-by requires superseded-on"⟩⟩

  row ← @
  {𝕊:
    row↩{kind⇐"cancelled",plan_id⇐transaction.plan_id,retired_on⇐⊑cancelValues,successor_plan_id⇐""}
  }⍟(hasCancel ∧ 0=≠diagnostics) @
  {𝕊:
    row↩{kind⇐"superseded",plan_id⇐transaction.plan_id,retired_on⇐⊑supersededOnValues,successor_plan_id⇐⊑supersededByValues}
  }⍟(hasSupersededOn ∧ hasSupersededBy ∧ 0=≠diagnostics) @
  {diagnostics⇐diagnostics,row⇐row}
}

HasSupersessionCycle ← {𝕊 start‿oldIds‿successorIds:
  current ← start
  seen ← ⟨start⟩
  cycle ← 0
  {𝕊 ignored:
    matches ← current⊸≡¨oldIds
    canAdvance ← (¬cycle) ∧ (0<≠current) ∧ 1=+´matches
    {𝕊:
      successor ← ⊑matches/successorIds
      cycle ↩ Contains ⟨successor,seen⟩
      {𝕊: seen ∾↩ ⟨successor⟩ ⋄ current ↩ successor}⍟(¬cycle) @
    }⍟canAdvance @
  }¨↕≠oldIds
  cycle
}

AdmitRetirements ← {𝕊 transactions:
  diagnostics ← empty
  local ← LocalRetirement¨transactions
  diagnostics ∾↩ ∾{𝕩.diagnostics}¨local
  rowsList ← ({𝕩.row≢@}¨local)/{𝕩.row}¨local
  planIds ← {𝕩.plan_id}¨transactions

  {𝕊 row:
    {𝕊:
      diagnostics ∾↩ AddIf ⟨row.successor_plan_id≡row.plan_id,
        Diagnostic ⟨"plan_supersession_self",0,"a Plan cannot supersede itself"⟩⟩
      diagnostics ∾↩ AddIf ⟨¬Contains ⟨row.successor_plan_id,planIds⟩,
        Diagnostic ⟨"plan_supersession_target_unknown",0,"superseded-by must name another admitted Plan"⟩⟩
    }⍟(row.kind≡"superseded") @
  }¨rowsList

  supersededRows ← ("superseded"⊸≡¨{𝕩.kind}¨rowsList)/rowsList
  oldIds ← {𝕩.plan_id}¨supersededRows
  successorIds ← {𝕩.successor_plan_id}¨supersededRows
  cycleFlags ← {HasSupersessionCycle ⟨𝕩,oldIds,successorIds⟩}¨oldIds
  {𝕊 i:
    diagnostics ∾↩ AddIf ⟨i⊑cycleFlags,
      Diagnostic ⟨"plan_supersession_cycle",0,"supersession graph cannot contain a cycle"⟩⟩
  }¨↕≠oldIds

  rows ← EmptyRetirementRows @
  {𝕊:
    rows↩{
      count⇐≠rowsList,index⇐↕≠rowsList,
      kind⇐{𝕩.kind}¨rowsList,
      plan_id⇐{𝕩.plan_id}¨rowsList,
      retired_on⇐{𝕩.retired_on}¨rowsList,
      successor_plan_id⇐{𝕩.successor_plan_id}¨rowsList
    }
  }⍟(0=≠diagnostics) @
  {state⇐(0=≠diagnostics)⊑"error"‿"ok",rows⇐rows,diagnostics⇐diagnostics}
}

Admit ← {𝕊 raw‿accounts‿registry:
  accounting ← journal.Admit ⟨raw,accounts,registry⟩
  diagnostics ← accounting.diagnostics
  transactions ← empty
  retirements ← EmptyRetirementRows @
  domains ← empty
  {𝕊:
    sourceTransactions ← accounting.transactions
    domains↩accounting.declared_domains
    planIds ← {𝕩.plan_id}¨sourceTransactions
    transactionDiagnostics ← {𝕊 i:
      transaction ← i⊑sourceTransactions
      planId ← i⊑planIds
      missingDiagnostic ← AddIf ⟨0=≠planId,Diagnostic ⟨"plan_id_missing",transaction.source_start_line,"Plan transaction requires plan-id metadata"⟩⟩
      invalidDiagnostic ← AddIf ⟨(0<≠planId) ∧ ¬PlanIdValid planId,Diagnostic ⟨"plan_id_invalid",transaction.source_start_line,"plan-id must be nonempty and contain no whitespace"⟩⟩
      missingDiagnostic∾invalidDiagnostic
    }¨↕≠sourceTransactions
    diagnostics∾↩∾transactionDiagnostics
    diagnostics∾↩AddIf ⟨(≠planIds)≠≠⍷planIds,Diagnostic ⟨"plan_id_duplicate",0,"one plan-id may identify only one Plan transaction"⟩⟩
    {𝕊:
      mappedTransactions ← MapTransaction¨sourceTransactions
      retirementAdmission ← AdmitRetirements mappedTransactions
      diagnostics∾↩retirementAdmission.diagnostics
      {𝕊: transactions↩mappedTransactions ⋄ retirements↩retirementAdmission.rows}⍟(0=≠diagnostics) @
    }⍟(0=≠diagnostics) @
  }⍟(accounting.state≡"ok") @
  {𝕊: transactions↩empty ⋄ retirements↩EmptyRetirementRows @ ⋄ domains↩empty}⍟(0<≠diagnostics) @
  {
    state⇐(0=≠diagnostics)⊑"error"‿"ok",
    source_name⇐sourceName,
    declared_domains⇐domains,
    declared_layers⇐⟨"plan"⟩,
    transactions⇐transactions,
    retirements⇐retirements,
    diagnostics⇐diagnostics
  }
}

{Admit⇐Admit,AdmitRetirements⇐AdmitRetirements}
