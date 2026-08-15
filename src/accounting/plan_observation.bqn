# Role-neutral Plan lifecycle/completion observation over admitted Plan/Actual facts.
# Open/completed/retired identity is decided only from stable PlanId relations and
# observation day. Accounting role, posting shape, and Envelope meaning live later.

dates ← •Import "../ledger/date_ordinal.bqn"
reference ← •Import "../ledger/fact_reference.bqn"
empty ← ⟨⟩
Diagnostic ← {𝕊 code‿message:{severity⇐"error",stage⇐"accounting_plan_observation",code⇐code,message⇐message}}
AddIf ← {𝕊 bad‿d:bad/⟨d⟩}
EmptyCompleted ← {𝕊:{count⇐0,index⇐empty,plan_transaction_index⇐empty,actual_transaction_index⇐empty,plan_id⇐empty,plan_reference⇐empty,actual_reference⇐empty}}
EmptyResult ← {𝕊 state‿observation‿ds:{state⇐state,observation_ordinal⇐observation,open_transaction_indices⇐empty,retired_plan_ids⇐empty,completed⇐EmptyCompleted @,diagnostics⇐ds}}
ActualIndex ← {𝕊 xs:value←¯1 ⋄ {𝕊:value↩⊑xs}⍟(1=≠xs) @ ⋄ value}
VisibleAt ← {𝕊 i‿facts‿day:value←0 ⋄ {𝕊:value↩(i⊑facts.transactions.date_ordinal)≤day}⍟(i≥0) @ ⋄ value}

Build ← {𝕊 planFacts‿retirements‿actualFacts‿observation:
  ds←empty
  ds∾↩AddIf ⟨¬reference.SourceIs ⟨planFacts,"plan.journal"⟩,Diagnostic ⟨"plan_facts_invalid","Plan facts must come from plan.journal"⟩⟩
  ds∾↩AddIf ⟨¬reference.SourceIs ⟨actualFacts,"actual.journal"⟩,Diagnostic ⟨"actual_facts_invalid","Actual facts must come from actual.journal"⟩⟩
  planIds←planFacts.transactions.plan_id ⋄ retirementCoords←planIds⊐retirements.plan_id
  ds∾↩AddIf ⟨¬∧´1∾retirementCoords<planFacts.transactions.count,Diagnostic ⟨"plan_retirement_reference_unknown","Plan retirement must name an admitted PlanId"⟩⟩
  validDates←dates.IsValid¨retirements.retired_on ⋄ ds∾↩AddIf ⟨¬∧´1∾validDates,Diagnostic ⟨"plan_retirement_date_invalid","Plan retirement dates must be strict Gregorian text"⟩⟩
  linkedMask←0<≠¨actualFacts.transactions.plan_id ⋄ linkedActual←linkedMask/actualFacts.transactions.index ⋄ linkedIds←linkedMask/actualFacts.transactions.plan_id ⋄ actualCoords←planIds⊐linkedIds
  ds∾↩AddIf ⟨¬∧´1∾actualCoords<planFacts.transactions.count,Diagnostic ⟨"completion_plan_unknown","Actual plan_id must name an admitted Plan"⟩⟩
  result←EmptyResult ⟨"error",observation,ds⟩
  {𝕊:
    completionCells←{𝕊 id:(id⊸≡¨linkedIds)/linkedActual}¨planIds
    ds∾↩AddIf ⟨∨´0∾1<≠¨completionCells,Diagnostic ⟨"plan_completion_multiple_actuals","one PlanId cannot be completed by multiple Actual transactions"⟩⟩
    {𝕊:
      actualByPlan←ActualIndex¨completionCells ⋄ completedMask←{VisibleAt ⟨𝕩,actualFacts,observation⟩}¨actualByPlan
      retirementOrdinals←dates.Ordinal¨retirements.retired_on ⋄ effectiveRows←retirementOrdinals≤observation
      IsRetired←{𝕊 planIndex:∨´0∾(planIndex=retirementCoords)∧effectiveRows}
      retiredMask←IsRetired¨planFacts.transactions.index ⋄ openMask←(¬completedMask)∧¬retiredMask
      completedPlan←completedMask/planFacts.transactions.index ⋄ completedActual←completedMask/actualByPlan
      completed←{count⇐≠completedPlan,index⇐↕≠completedPlan,plan_transaction_index⇐completedPlan,actual_transaction_index⇐completedActual,plan_id⇐completedPlan⊏planIds,plan_reference⇐{reference.Transaction ⟨planFacts,𝕩⟩}¨completedPlan,actual_reference⇐{reference.Transaction ⟨actualFacts,𝕩⟩}¨completedActual}
      result↩{state⇐"ok",observation_ordinal⇐observation,open_transaction_indices⇐openMask/planFacts.transactions.index,retired_plan_ids⇐retiredMask/planIds,completed⇐completed,diagnostics⇐empty}
    }⍟(0=≠ds) @
  }⍟(0=≠ds) @
  result
}
{Build⇐Build}
