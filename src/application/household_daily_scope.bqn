# Pure Daily Target selection admission from canonical Household policy + Plan.
# household.toml owns long-lived Asset selections. plan.journal owns current Plan
# selections and optional exact reservation evidence.

exact ← •Import "../ledger/exact_decimal.bqn"
reference ← •Import "../ledger/fact_reference.bqn"
empty ← ⟨⟩

MetaValues ← {𝕊 key‿metadata: {𝕩.value}¨({key≡𝕩.key}¨metadata)/metadata}
MetaOne ← {𝕊 key‿metadata:
  values ← MetaValues ⟨key,metadata⟩
  value ← ""
  {𝕊:value↩⊑values}⍟(0<≠values) @
  {count⇐≠values,value⇐value}
}
Diagnostic ← {𝕊 code‿message:
  {severity⇐"error",stage⇐"application_household_daily_scope",code⇐code,message⇐message}
}
EmptyRows ← {𝕊:
  {count⇐0,index⇐empty,kind⇐empty,scope_id⇐empty,account_key⇐empty,plan_id⇐empty,
   excluded_coefficient⇐empty,excluded_scale⇐empty,currency⇐empty,reservation_ref⇐empty,
   source_row⇐empty,source_ref⇐empty}
}
Build ← {𝕊 household‿planFacts‿registry:
  diagnostics ← household.diagnostics
  diagnostics∾↩((household.state≢"ok") ∨ household.source_name≢"household.toml")/⟨
    Diagnostic ⟨"household_policy_invalid","Daily Target requires admitted household.toml policy"⟩
  ⟩
  diagnostics∾↩(¬reference.SourceIs ⟨planFacts,"plan.journal"⟩)/⟨
    Diagnostic ⟨"plan_facts_invalid","Daily Target requires canonical Plan facts"⟩
  ⟩
  rows ← empty
  {𝕊 i:
    rows∾↩⟨{
      kind⇐"asset",scope_id⇐i⊑household.daily_target.scope_id,
      account_key⇐i⊑household.daily_target.account_key,plan_id⇐"",
      excluded_coefficient⇐0,excluded_scale⇐0,currency⇐"",reservation_ref⇐"",
      source_row⇐0,source_ref⇐"household.toml:daily-target:"∾i⊑household.daily_target.scope_id
    }⟩
  }¨household.daily_target.index
  {𝕊 i:
    metadata ← i⊑planFacts.transactions.metadata
    selection ← MetaOne ⟨"daily-target-id",metadata⟩
    reservationId ← MetaOne ⟨"reservation-id",metadata⟩
    reservationAmount ← MetaOne ⟨"reservation-amount",metadata⟩
    reservationCommodity ← MetaOne ⟨"reservation-commodity",metadata⟩
    duplicate ← (1<selection.count) ∨ (1<reservationId.count) ∨ (1<reservationAmount.count) ∨ 1<reservationCommodity.count
    diagnostics∾↩duplicate/⟨Diagnostic ⟨"daily_target_metadata_duplicate","Daily Target metadata keys must be unique per Plan"⟩⟩
    anyReservation ← (0<reservationId.count) ∨ (0<reservationAmount.count) ∨ 0<reservationCommodity.count
    hasSelection ← 1=selection.count
    diagnostics∾↩((¬hasSelection) ∧ anyReservation)/⟨Diagnostic ⟨"daily_reservation_without_selection","Reservation metadata requires daily-target-id"⟩⟩
    {𝕊:
      selectionId ← selection.value
      diagnostics∾↩(0=≠selectionId)/⟨Diagnostic ⟨"daily_target_id_empty","daily-target-id must be nonempty"⟩⟩
      completeReservation ← (reservationId.count=reservationAmount.count) ∧ (reservationAmount.count=reservationCommodity.count)
      diagnostics∾↩(anyReservation ∧ ¬completeReservation)/⟨Diagnostic ⟨"daily_reservation_incomplete","Reservation requires id, amount, and commodity together"⟩⟩
      coefficient ← 0 ⋄ reservationScale ← 0 ⋄ currency ← "" ⋄ reservationRef ← ""
      {𝕊:
        parsed ← exact.Parse reservationAmount.value ⋄ policy ← registry.Policy reservationCommodity.value
        valid ← (parsed.state≡"ok") ∧ (policy.state≡"ok")
        {𝕊:
          finite ← policy.max_fraction_digits≠¯1
          valid↩(¬finite) ∨ parsed.scale≤policy.max_fraction_digits
        }⍟valid @
        diagnostics∾↩(¬valid)/⟨Diagnostic ⟨"daily_reservation_amount_invalid","Reservation amount/commodity must be exact and admitted"⟩⟩
        diagnostics∾↩(valid ∧ parsed.coefficient≤0)/⟨Diagnostic ⟨"daily_reservation_amount_nonpositive","Reservation amount must be positive"⟩⟩
        diagnostics∾↩(0=≠reservationId.value)/⟨Diagnostic ⟨"daily_reservation_id_invalid","Reservation id must be nonempty"⟩⟩
        {𝕊:
          coefficient↩parsed.coefficient ⋄ reservationScale↩parsed.scale
          currency↩reservationCommodity.value ⋄ reservationRef↩reservationId.value
        }⍟(valid ∧ parsed.coefficient>0 ∧ 0<≠reservationId.value) @
      }⍟(anyReservation ∧ completeReservation) @
      {𝕊:
        rows∾↩⟨{
          kind⇐"obligation",scope_id⇐selectionId,account_key⇐"",
          plan_id⇐i⊑planFacts.transactions.plan_id,
          excluded_coefficient⇐coefficient,excluded_scale⇐reservationScale,
          currency⇐currency,reservation_ref⇐reservationRef,source_row⇐i⊑planFacts.transactions.source_start_line,
          source_ref⇐i⊑planFacts.transactions.transaction_id
        }⟩
      }⍟(0<≠selectionId) @
    }⍟(hasSelection ∧ ¬duplicate) @
  }¨planFacts.transactions.index
  ids ← {𝕩.scope_id}¨rows
  diagnostics∾↩((≠ids)≠≠⍷ids)/⟨Diagnostic ⟨"daily_target_id_duplicate","Daily Target selection ids must be unique across Household and Plan"⟩⟩
  ok ← 0=≠diagnostics ⋄ admitted ← EmptyRows @
  {𝕊:
    admitted↩{
      count⇐≠rows,index⇐↕≠rows,kind⇐{𝕩.kind}¨rows,scope_id⇐{𝕩.scope_id}¨rows,
      account_key⇐{𝕩.account_key}¨rows,plan_id⇐{𝕩.plan_id}¨rows,
      excluded_coefficient⇐{𝕩.excluded_coefficient}¨rows,excluded_scale⇐{𝕩.excluded_scale}¨rows,
      currency⇐{𝕩.currency}¨rows,reservation_ref⇐{𝕩.reservation_ref}¨rows,
      source_row⇐{𝕩.source_row}¨rows,source_ref⇐{𝕩.source_ref}¨rows
    }
  }⍟ok @
  {state⇐ok⊑"error"‿"ok",rows⇐admitted,diagnostics⇐diagnostics}
}

{Build⇐Build}
