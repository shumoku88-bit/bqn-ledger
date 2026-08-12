# Pure Daily Target selection admission from canonical Household policy + Plan.
# household.toml owns long-lived Asset selections. plan.journal owns current Plan
# selections and optional exact reservation evidence.
#
# Household selections and Plan selections are projected independently to one
# common scope-row relation. Plan-local diagnostics stay inside each transaction
# cell, then rows and diagnostics are flattened once in source order.

exact ← •Import "../ledger/exact_decimal.bqn"
reference ← •Import "../ledger/fact_reference.bqn"
empty ← ⟨⟩

MetaValues ← {𝕊 key‿metadata: {𝕩.value}¨({key≡𝕩.key}¨metadata)/metadata}
MetaOne ← {𝕊 key‿metadata:
  values ← MetaValues ⟨key,metadata⟩ ⋄ count ← ≠values
  value ← (0<count)◶⟨{𝕊:""},{𝕊:⊑values}⟩ @
  {count⇐count,value⇐value}
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
  sourceDiagnostics ← household.diagnostics
  sourceDiagnostics ∾↩ ((household.state≢"ok") ∨ household.source_name≢"household.toml")/⟨
    Diagnostic ⟨"household_policy_invalid","Daily Target requires admitted household.toml policy"⟩
  ⟩
  sourceDiagnostics ∾↩ (¬reference.SourceIs ⟨planFacts,"plan.journal"⟩)/⟨
    Diagnostic ⟨"plan_facts_invalid","Daily Target requires canonical Plan facts"⟩
  ⟩

  assetRows ← {𝕊 i:
    {
      kind⇐"asset",scope_id⇐i⊑household.daily_target.scope_id,
      account_key⇐i⊑household.daily_target.account_key,plan_id⇐"",
      excluded_coefficient⇐0,excluded_scale⇐0,currency⇐"",reservation_ref⇐"",
      source_row⇐0,source_ref⇐"household.toml:daily-target:"∾i⊑household.daily_target.scope_id
    }
  }¨household.daily_target.index

  ValidateReservation ← {𝕊 reservationId‿reservationAmount‿reservationCommodity:
    anyReservation ← (0<reservationId.count) ∨ (0<reservationAmount.count) ∨ 0<reservationCommodity.count
    complete ← (reservationId.count=reservationAmount.count) ∧ (reservationAmount.count=reservationCommodity.count)
    result ← {
      coefficient⇐0,scale⇐0,currency⇐"",reference⇐"",
      diagnostics⇐(anyReservation ∧ ¬complete)/⟨
        Diagnostic ⟨"daily_reservation_incomplete","Reservation requires id, amount, and commodity together"⟩
      ⟩
    }
    {𝕊:
      parsed ← exact.Parse reservationAmount.value ⋄ policy ← registry.Policy reservationCommodity.value
      valid ← (parsed.state≡"ok") ∧ (policy.state≡"ok")
      {𝕊:
        finite ← policy.max_fraction_digits≠¯1
        valid↩(¬finite) ∨ parsed.scale≤policy.max_fraction_digits
      }⍟valid @
      reservationDiagnostics ← (¬valid)/⟨
        Diagnostic ⟨"daily_reservation_amount_invalid","Reservation amount/commodity must be exact and admitted"⟩
      ⟩
      coefficient ← 0 ⋄ scale ← 0 ⋄ currency ← "" ⋄ reservationRef ← ""
      {𝕊:
        reservationDiagnostics∾↩(parsed.coefficient≤0)/⟨
          Diagnostic ⟨"daily_reservation_amount_nonpositive","Reservation amount must be positive"⟩
        ⟩
        {𝕊:
          coefficient↩parsed.coefficient ⋄ scale↩parsed.scale
          currency↩reservationCommodity.value ⋄ reservationRef↩reservationId.value
        }⍟(parsed.coefficient>0 ∧ 0<≠reservationId.value) @
      }⍟valid @
      reservationDiagnostics∾↩(0=≠reservationId.value)/⟨
        Diagnostic ⟨"daily_reservation_id_invalid","Reservation id must be nonempty"⟩
      ⟩
      result↩{
        coefficient⇐coefficient,scale⇐scale,currency⇐currency,reference⇐reservationRef,
        diagnostics⇐reservationDiagnostics
      }
    }⍟(anyReservation ∧ complete) @
    result
  }

  ProjectPlan ← {𝕊 i:
    metadata ← i⊑planFacts.transactions.metadata
    selection ← MetaOne ⟨"daily-target-id",metadata⟩
    reservationId ← MetaOne ⟨"reservation-id",metadata⟩
    reservationAmount ← MetaOne ⟨"reservation-amount",metadata⟩
    reservationCommodity ← MetaOne ⟨"reservation-commodity",metadata⟩
    duplicate ← (1<selection.count) ∨ (1<reservationId.count) ∨ (1<reservationAmount.count) ∨ 1<reservationCommodity.count
    anyReservation ← (0<reservationId.count) ∨ (0<reservationAmount.count) ∨ 0<reservationCommodity.count
    hasSelection ← 1=selection.count
    rowDiagnostics ← duplicate/⟨
      Diagnostic ⟨"daily_target_metadata_duplicate","Daily Target metadata keys must be unique per Plan"⟩
    ⟩
    rowDiagnostics∾↩((¬hasSelection) ∧ anyReservation)/⟨
      Diagnostic ⟨"daily_reservation_without_selection","Reservation metadata requires daily-target-id"⟩
    ⟩
    items ← empty
    {𝕊:
      selectionId ← selection.value
      rowDiagnostics∾↩(0=≠selectionId)/⟨
        Diagnostic ⟨"daily_target_id_empty","daily-target-id must be nonempty"⟩
      ⟩
      reservation ← ValidateReservation ⟨reservationId,reservationAmount,reservationCommodity⟩
      rowDiagnostics∾↩reservation.diagnostics
      {𝕊:
        items↩⟨{
          kind⇐"obligation",scope_id⇐selectionId,account_key⇐"",
          plan_id⇐i⊑planFacts.transactions.plan_id,
          excluded_coefficient⇐reservation.coefficient,excluded_scale⇐reservation.scale,
          currency⇐reservation.currency,reservation_ref⇐reservation.reference,
          source_row⇐i⊑planFacts.transactions.source_start_line,
          source_ref⇐i⊑planFacts.transactions.transaction_id
        }⟩
      }⍟(0<≠selectionId) @
    }⍟(hasSelection ∧ ¬duplicate) @
    {diagnostics⇐rowDiagnostics,items⇐items}
  }

  planResults ← ProjectPlan¨planFacts.transactions.index
  diagnostics ← sourceDiagnostics∾∾{𝕩.diagnostics}¨planResults
  rows ← assetRows∾∾{𝕩.items}¨planResults
  ids ← {𝕩.scope_id}¨rows
  diagnostics∾↩((≠ids)≠≠⍷ids)/⟨
    Diagnostic ⟨"daily_target_id_duplicate","Daily Target selection ids must be unique across Household and Plan"⟩
  ⟩
  ok ← 0=≠diagnostics
  admitted ← ok◶⟨
    {𝕊:EmptyRows @},
    {𝕊:{
      count⇐≠rows,index⇐↕≠rows,kind⇐{𝕩.kind}¨rows,scope_id⇐{𝕩.scope_id}¨rows,
      account_key⇐{𝕩.account_key}¨rows,plan_id⇐{𝕩.plan_id}¨rows,
      excluded_coefficient⇐{𝕩.excluded_coefficient}¨rows,excluded_scale⇐{𝕩.excluded_scale}¨rows,
      currency⇐{𝕩.currency}¨rows,reservation_ref⇐{𝕩.reservation_ref}¨rows,
      source_row⇐{𝕩.source_row}¨rows,source_ref⇐{𝕩.source_ref}¨rows
    }}
  ⟩ @
  {state⇐ok⊑"error"‿"ok",rows⇐admitted,diagnostics⇐diagnostics}
}

{Build⇐Build}
