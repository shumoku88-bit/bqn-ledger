# Retained Daily Target evidence-bearing Card/Projection and human/compact renderers.

amount ← •Import "../ledger/amount_text.bqn"
text ← •Import "../report/text.bqn"
empty ← ⟨⟩

EmptyCalculation ← {𝕊:
  {
    eligible_assets⇐empty,gross_obligations⇐empty,already_excluded⇐empty,
    obligation_deduction⇐empty,capacity_balance⇐empty,remaining_days⇐empty,
    daily_target⇐empty,daily_shortfall⇐empty
  }
}
EmptyResult ← {𝕊 state‿reason‿diagnostics:
  {
    state⇐state,reason⇐reason,domain⇐"",observation⇐"",target_date⇐"",scale⇐0,
    asset_evidence⇐empty,obligation_evidence⇐empty,
    calculation⇐EmptyCalculation @,diagnostics⇐diagnostics
  }
}

Build ← {𝕊 dailyTarget:
  result ← EmptyResult ⟨dailyTarget.state,dailyTarget.reason,dailyTarget.diagnostics⟩
  calculable ← ∨´dailyTarget.state⊸≡¨⟨"ok","deficit"⟩
  {𝕊:
    result↩{
      state⇐dailyTarget.state,reason⇐"",domain⇐dailyTarget.domain,
      observation⇐dailyTarget.observation,target_date⇐dailyTarget.target_date,scale⇐dailyTarget.scale,
      asset_evidence⇐dailyTarget.asset_evidence,obligation_evidence⇐dailyTarget.obligation_evidence,
      calculation⇐dailyTarget.calculation,diagnostics⇐empty
    }
  }⍟calculable @
  result
}

AmountText ← {𝕊 coefficient‿scaleValue: amount.Format ⟨coefficient,scaleValue⟩}
FormatHuman ← {𝕊 result:
  calculation ← result.calculation
  out ← "== Daily Target =="∾(@+10)
  out ∾↩ "Observation: "∾result.observation∾(@+10)
  out ∾↩ "Target date: "∾result.target_date∾" ("∾(•Fmt calculation.remaining_days)∾" days)"∾(@+10)∾(@+10)
  assetRows ← {𝕊 row:⟨row.asset_id,AmountText ⟨row.coefficient,row.scale⟩⟩}¨result.asset_evidence
  out ∾↩ "Eligible asset evidence"∾(@+10)
  out ∾↩ text.RenderTable ⟨⟨"Asset","Amount"⟩,assetRows,⟨1⟩⟩
  obligationRows ← {𝕊 row:
    reservation ← row.reservation_state
    {𝕊:reservation↩reservation∾":"∾row.reservation_ref}⍟(0<≠row.reservation_ref) @
    ⟨
      row.obligation_id,AmountText ⟨row.coefficient,row.scale⟩,
      AmountText ⟨row.excluded_coefficient,row.scale⟩,
      AmountText ⟨row.deduction_coefficient,row.scale⟩,reservation
    ⟩
  }¨result.obligation_evidence
  out ∾↩ (@+10)∾"Open obligation evidence"∾(@+10)
  {𝕊:out∾↩text.RenderTable ⟨⟨"Obligation","Gross","Already excluded","Deduction","Reservation"⟩,obligationRows,⟨1,2,3⟩⟩}⍟(0<≠obligationRows) @
  {𝕊:out∾↩"  (none)"∾(@+10)}⍟(0=≠obligationRows) @
  calculationRows ← ⟨
    ⟨"Eligible assets",AmountText ⟨calculation.eligible_assets,result.scale⟩⟩,
    ⟨"Gross obligations",AmountText ⟨calculation.gross_obligations,result.scale⟩⟩,
    ⟨"Already excluded",AmountText ⟨calculation.already_excluded,result.scale⟩⟩,
    ⟨"Obligation deduction",AmountText ⟨calculation.obligation_deduction,result.scale⟩⟩,
    ⟨"Capacity balance",AmountText ⟨calculation.capacity_balance,result.scale⟩⟩,
    ⟨"Daily target",AmountText ⟨calculation.daily_target,result.scale⟩⟩,
    ⟨"Daily shortfall",AmountText ⟨calculation.daily_shortfall,result.scale⟩⟩
  ⟩
  out ∾↩ (@+10)∾"Calculation"∾(@+10)
  out ∾↩ text.RenderTable ⟨⟨"Coordinate","Amount"⟩,calculationRows,⟨1⟩⟩
  out ∾↩ "Status: "∾result.state∾(@+10)∾(@+10)
  out
}

FormatCompact ← {𝕊 result:
  calculation ← result.calculation
  fields ← ⟨
    ⟨"status",result.state⟩,
    ⟨"eligible_assets",AmountText ⟨calculation.eligible_assets,result.scale⟩⟩,
    ⟨"gross_obligations",AmountText ⟨calculation.gross_obligations,result.scale⟩⟩,
    ⟨"already_excluded",AmountText ⟨calculation.already_excluded,result.scale⟩⟩,
    ⟨"obligation_deduction",AmountText ⟨calculation.obligation_deduction,result.scale⟩⟩,
    ⟨"capacity_balance",AmountText ⟨calculation.capacity_balance,result.scale⟩⟩,
    ⟨"remaining_days",•Fmt calculation.remaining_days⟩,
    ⟨"amount",AmountText ⟨calculation.daily_target,result.scale⟩⟩,
    ⟨"shortfall",AmountText ⟨calculation.daily_shortfall,result.scale⟩⟩
  ⟩
  "--- Ledger Daily Target ---"∾(@+10)∾∾{𝕊 field:"ledger_daily_target_"∾(0⊑field)∾": "∾(1⊑field)∾(@+10)}¨fields
}

{Build⇐Build,FormatHuman⇐FormatHuman,FormatCompact⇐FormatCompact}
