# Plan-owned cancellation/supersession admission over already admitted Plan Transactions.
# Journal structure owns lexical metadata and duplicate-key rejection. This owner
# assigns lifecycle meaning without changing the original Transaction or postings.

empty ← ⟨⟩

Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}
Diagnostic ← {𝕊 codeText‿messageText:
  {severity⇐"error",stage⇐"ledger_plan_retirement_admission",code⇐codeText,message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}

MetadataValues ← {𝕊 key‿transaction:
  metadata ← transaction.metadata
  matches ← key⊸≡¨{𝕩.key}¨metadata
  {𝕩.value}¨matches/metadata
}

EmptyRows ← {𝕊:
  {count⇐0,index⇐empty,kind⇐empty,plan_id⇐empty,retired_on⇐empty,successor_plan_id⇐empty}
}

LocalRetirement ← {𝕊 transaction:
  diagnostics ← empty
  cancelValues ← MetadataValues ⟨"cancelled-on",transaction⟩
  supersededOnValues ← MetadataValues ⟨"superseded-on",transaction⟩
  supersededByValues ← MetadataValues ⟨"superseded-by",transaction⟩
  hasCancel ← 1=≠cancelValues
  hasSupersededOn ← 1=≠supersededOnValues
  hasSupersededBy ← 1=≠supersededByValues
  hasSupersession ← hasSupersededOn ∨ hasSupersededBy

  diagnostics ∾↩ AddIf ⟨hasCancel ∧ hasSupersession,
    Diagnostic ⟨"plan_retirement_conflict","cancelled-on cannot coexist with supersession metadata"⟩⟩
  diagnostics ∾↩ AddIf ⟨hasSupersededOn ∧ ¬hasSupersededBy,
    Diagnostic ⟨"plan_superseded_by_missing","superseded-on requires superseded-by"⟩⟩
  diagnostics ∾↩ AddIf ⟨hasSupersededBy ∧ ¬hasSupersededOn,
    Diagnostic ⟨"plan_superseded_on_missing","superseded-by requires superseded-on"⟩⟩

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
  {𝕊 _:
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

Admit ← {𝕊 transactions:
  diagnostics ← empty
  local ← LocalRetirement¨transactions
  diagnostics ∾↩ ∾{𝕩.diagnostics}¨local
  rowsList ← ({𝕩.row≢@}¨local)/{𝕩.row}¨local
  planIds ← {𝕩.plan_id}¨transactions

  {𝕊 row:
    {𝕊:
      diagnostics ∾↩ AddIf ⟨row.successor_plan_id≡row.plan_id,
        Diagnostic ⟨"plan_supersession_self","a Plan cannot supersede itself"⟩⟩
      diagnostics ∾↩ AddIf ⟨¬Contains ⟨row.successor_plan_id,planIds⟩,
        Diagnostic ⟨"plan_supersession_target_unknown","superseded-by must name another admitted Plan"⟩⟩
    }⍟(row.kind≡"superseded") @
  }¨rowsList

  supersededRows ← ("superseded"⊸≡¨{𝕩.kind}¨rowsList)/rowsList
  oldIds ← {𝕩.plan_id}¨supersededRows
  successorIds ← {𝕩.successor_plan_id}¨supersededRows
  cycleStarts ← {𝕩/oldIds} HasSupersessionCycle¨ ⟨oldIds⟩‿⟨successorIds⟩
  # The rank-polymorphic expression above is intentionally replaced below by a
  # direct per-start characterization to keep the graph walk obvious.
  cycleFlags ← {HasSupersessionCycle ⟨𝕩,oldIds,successorIds⟩}¨oldIds
  diagnostics ∾↩ ∾{
    AddIf ⟨𝕨,Diagnostic ⟨"plan_supersession_cycle","supersession graph cannot contain a cycle"⟩⟩
  }¨○<oldIds⊸∾ cycleFlags

  rows ← EmptyRows @
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

{Admit⇐Admit}
