# Role-neutral Plan lifecycle/completion observation over admitted Plan/Actual facts.
#
# This owner decides only whether one stable PlanId is open or completed at an
# observation day, and whether admitted Plan retirement has taken effect. It does
# not classify accounting roles, compare posting shapes, sum amounts, or assign
# Envelope meaning.

dates ← •Import "../ledger/date_ordinal.bqn"
reference ← •Import "../ledger/fact_reference.bqn"
empty ← ⟨⟩

Diagnostic ← {𝕊 code‿message:{severity⇐"error",stage⇐"accounting_plan_observation",code⇐code,message⇐message}}
AddIf ← {𝕊 invalid‿diagnostic:invalid/⟨diagnostic⟩}
EmptyCompleted ← {𝕊:{count⇐0,index⇐empty,plan_transaction_index⇐empty,actual_transaction_index⇐empty,plan_id⇐empty,plan_reference⇐empty,actual_reference⇐empty}}
EmptyResult ← {𝕊 stateValue‿observationValue‿diagnosticsValue:{state⇐stateValue,observation_ordinal⇐observationValue,open_transaction_indices⇐empty,retired_plan_ids⇐empty,completed⇐EmptyCompleted @,diagnostics⇐diagnosticsValue}}
ActualIndex ← {𝕊 indices:value←¯1 ⋄ {𝕊:value↩⊑indices}⍟(1=≠indices) @ ⋄ value}
VisibleAt ← {𝕊 actualIndex‿actualFacts‿observation:visible←0 ⋄ {𝕊:visible↩(actualIndex⊑actualFacts.transactions.date_ordinal)≤observation}⍟(actualIndex≥0) @ ⋄ visible}

Build ← {𝕊 planFacts‿retirements‿actualFacts‿observation:
  diagnostics ← empty
  diagnostics∾↩AddIf ⟨¬reference.SourceIs ⟨planFacts,"plan.journal"⟩,Diagnostic ⟨"plan_facts_invalid","Plan facts must be admitted from plan.journal"⟩⟩
  diagnostics∾↩AddIf ⟨¬reference.SourceIs ⟨actualFacts,"actual.journal"⟩,Diagnostic ⟨"actual_facts_invalid","Actual facts must be admitted from actual.journal"⟩⟩
  planIds ← planFacts.transactions.plan_id
  retirementCoordinates ← planIds⊐retirements.plan_id
  retirementKnown ← retirementCoordinates<planFacts.transactions.count
  diagnostics∾↩AddIf ⟨¬∧´1∾retirementKnown,Diagnostic ⟨"plan_retirement_reference_unknown","Plan retirement must name an admitted PlanId"⟩⟩
  retirementDatesValid ← dates.IsValid¨retirements.retired_on
  diagnostics∾↩AddIf ⟨¬∧´1∾retirementDatesValid,Diagnostic ⟨"plan_retirement_date_invalid","Plan retirement dates must be strict Gregorian text"⟩⟩
  linkedActualMask ← 0<≠¨actualFacts.transactions.plan_id
  linkedActualIndices ← linkedActualMask/actualFacts.transactions.index
  linkedPlanIds ← linkedActualMask/actualFacts.transactions.plan_id
  actualPlanCoordinates ← planIds⊐linkedPlanIds
  diagnostics∾↩AddIf ⟨¬∧´1∾actualPlanCoordinates<planFacts.transactions.count,Diagnostic ⟨"completion_plan_unknown","Actual plan_id must name an admitted Plan"⟩⟩
  result ← EmptyResult ⟨"error",observation,diagnostics⟩
  {𝕊:
    completionCells ← {𝕊 planId:(planId⊸≡¨linkedPlanIds)/linkedActualIndices}¨planIds
    diagnostics∾↩AddIf ⟨∨´0∾1<≠¨completionCells,Diagnostic ⟨"plan_completion_multiple_actuals","one PlanId cannot be completed by multiple Actual transactions"⟩⟩
    {𝕊:
      actualByPlan ← ActualIndex¨completionCells
      visibleCompletionMask ← {VisibleAt ⟨𝕩,actualFacts,observation⟩}¨actualByPlan
      retirementOrdinals ← dates.Ordinal¨retirements.retired_on
      effectiveRetirementMask ← retirementOrdinals≤observation
      effectiveRetirementCoordinates ← effectiveRetirementMask/retirementCoordinates
      retiredPlanMask ← planFacts.transactions.index∊effectiveRetirementCoordinates
      openMask ← ¬visibleCompletionMask ∧ ¬retiredPlanMask
      completedPlanIndices ← visibleCompletionMask/planFacts.transactions.index
      completedActualIndices ← visibleCompletionMask/actualByPlan
      completed ← {
        count⇐≠completedPlanIndices,index⇐↕≠completedPlanIndices,
        plan_transaction_index⇐completedPlanIndices,actual_transaction_index⇐completedActualIndices,
        plan_id⇐completedPlanIndices⊏planIds,
        plan_reference⇐{reference.Transaction ⟨planFacts,𝕩⟩}¨completedPlanIndices,
        actual_reference⇐{reference.Transaction ⟨actualFacts,𝕩⟩}¨completedActualIndices
      }
      result↩{
        state⇐"ok",observation_ordinal⇐observation,
        open_transaction_indices⇐openMask/planFacts.transactions.index,
        retired_plan_ids⇐effectiveRetirementMask/retirements.plan_id,
        completed⇐completed,diagnostics⇐empty
      }
    }⍟(0=≠diagnostics) @
  }⍟(0=≠diagnostics) @
  result
}

{Build⇐Build}
