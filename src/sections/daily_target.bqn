# Retained Daily Target evidence-bearing Card/Projection and human/compact renderers.

amount ← •Import "../ledger/amount_text.bqn"
text ← •Import "../report/text.bqn"
empty ← ⟨⟩
lf ← @+10

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
FormatHuman ← {𝕊 input:
  result ← input ⋄ style ← "minus"
  {𝕊: result↩0⊑input ⋄ style↩(1⊑input).negative_style}⍟((0<≡input) ∧ (2=≠input)) @
  Fmt ← {𝕊 coeff‿scale: text.FormatAmount ⟨coeff,scale,style⟩}
  calculation ← result.calculation
  assetRows ← {𝕊 row:⟨row.asset_id,Fmt ⟨row.coefficient,row.scale⟩⟩}¨result.asset_evidence
  obligationRows ← {𝕊 row:
    reservation ← row.reservation_state
    {𝕊:reservation↩reservation∾":"∾row.reservation_ref}⍟(0<≠row.reservation_ref) @
    ⟨
      row.obligation_id,Fmt ⟨row.coefficient,row.scale⟩,
      Fmt ⟨row.excluded_coefficient,row.scale⟩,
      Fmt ⟨row.deduction_coefficient,row.scale⟩,reservation
    ⟩
  }¨result.obligation_evidence
  calculationRows ← ⟨
    ⟨"Eligible assets",Fmt ⟨calculation.eligible_assets,result.scale⟩⟩,
    ⟨"Gross obligations",Fmt ⟨calculation.gross_obligations,result.scale⟩⟩,
    ⟨"Already excluded",Fmt ⟨calculation.already_excluded,result.scale⟩⟩,
    ⟨"Obligation deduction",Fmt ⟨calculation.obligation_deduction,result.scale⟩⟩,
    ⟨"Capacity balance",Fmt ⟨calculation.capacity_balance,result.scale⟩⟩,
    ⟨"Daily target",Fmt ⟨calculation.daily_target,result.scale⟩⟩,
    ⟨"Daily shortfall",Fmt ⟨calculation.daily_shortfall,result.scale⟩⟩
  ⟩

  headingText ← ∾{𝕩∾lf}¨⟨
    "== Daily Target ==",
    ("Observation: "∾result.observation),
    ("Target date: "∾result.target_date∾" ("∾(•Fmt calculation.remaining_days)∾" days)"),
    ""
  ⟩
  assetBlock ← "Eligible asset evidence"∾lf∾text.RenderTable ⟨⟨"Asset","Amount"⟩,assetRows,⟨1⟩⟩
  obligationBody ← (0<≠obligationRows)⊑⟨"  (none)"∾lf,text.RenderTable ⟨⟨"Obligation","Gross","Already excluded","Deduction","Reservation"⟩,obligationRows,⟨1,2,3⟩⟩⟩
  obligationBlock ← lf∾"Open obligation evidence"∾lf∾obligationBody
  calculationBlock ← lf∾"Calculation"∾lf∾text.RenderTable ⟨⟨"Coordinate","Amount"⟩,calculationRows,⟨1⟩⟩
  statusText ← ∾{𝕩∾lf}¨⟨("Status: "∾result.state),""⟩
  ∾⟨headingText,assetBlock,obligationBlock,calculationBlock,statusText⟩
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
  "--- Ledger Daily Target ---"∾lf∾∾{𝕊 field:"ledger_daily_target_"∾(0⊑field)∾": "∾(1⊑field)∾lf}¨fields
}

{Build⇐Build,FormatHuman⇐FormatHuman,FormatCompact⇐FormatCompact}
