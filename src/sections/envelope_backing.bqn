# Retained Envelope & Backing Statement and human/compact/JSON renderers.

amount ← •Import "../ledger/amount_text.bqn"
dates ← •Import "../ledger/date_ordinal.bqn"
text ← •Import "../report/text.bqn"
json ← •Import "../report/json_text.bqn"
empty ← ⟨⟩

Diagnostic ← {𝕊 code‿message:
  {severity⇐"error",stage⇐"section_envelope_backing",code⇐code,message⇐message}
}
EmptyRows ← {𝕊:
  {
    count⇐0,index⇐empty,account_key⇐empty,category⇐empty,
    entitlement⇐empty,actual_consumption⇐empty,actual_refunds⇐empty,
    ledger_remaining⇐empty,open_plan_reserve⇐empty,post_plan_headroom⇐empty,
    entitlement_contributors⇐empty,consumption_contributors⇐empty,
    refund_contributors⇐empty,plan_contributors⇐empty
  }
}
EmptyTotals ← {𝕊:
  {
    entitlement⇐empty,actual_consumption⇐empty,actual_refunds⇐empty,
    ledger_remaining⇐empty,open_plan_reserve⇐empty,post_plan_headroom⇐empty,
    funding_balance⇐empty,signed_envelope_total⇐empty,backing_required⇐empty,
    backing_surplus⇐empty,ledger_unassigned⇐empty,reconciliation_delta⇐empty
  }
}
EmptyResult ← {𝕊 state‿reason‿diagnostics:
  {
    state⇐state,reason⇐reason,domain⇐"",start⇐"",end_exclusive⇐"",observation⇐"",
    scale⇐0,status⇐"",envelopes⇐EmptyRows @,totals⇐EmptyTotals @,
    funding_account_indices⇐empty,funding_contributors⇐empty,
    unassigned_contributors⇐empty,diagnostics⇐diagnostics
  }
}

Build ← {𝕊 statement‿startText‿endText‿observationText:
  result ← EmptyResult ⟨statement.state,statement.reason,statement.diagnostics⟩
  {𝕊:
    valid ← (dates.IsValid startText) ∧ (dates.IsValid endText) ∧ dates.IsValid observationText
    matches ← 0
    {𝕊:
      startMatches ← (dates.Ordinal startText)=statement.start_ordinal
      endMatches ← (dates.Ordinal endText)=statement.end_exclusive_ordinal
      observationMatches ← (dates.Ordinal observationText)=statement.observation_ordinal
      matches↩startMatches ∧ endMatches ∧ observationMatches
    }⍟valid @
    diagnostics ← empty
    diagnostics ∾↩ (¬valid)/⟨Diagnostic ⟨"statement_date_invalid","section dates must be strict Gregorian text"⟩⟩
    diagnostics ∾↩ (valid∧¬matches)/⟨Diagnostic ⟨"statement_date_mismatch","section dates must match accounting coordinates"⟩⟩
    {𝕊:
      source ← statement.envelopes
      result↩{
        state⇐"ok",reason⇐"",domain⇐statement.domain,start⇐startText,end_exclusive⇐endText,
        observation⇐observationText,scale⇐statement.scale,status⇐statement.status,
        envelopes⇐{
          count⇐source.count,index⇐source.index,account_key⇐source.account_key,category⇐source.category,
          entitlement⇐source.entitlement,actual_consumption⇐source.actual_consumption,
          actual_refunds⇐source.actual_refunds,ledger_remaining⇐source.ledger_remaining,
          open_plan_reserve⇐source.open_plan_reserve,post_plan_headroom⇐source.post_plan_headroom,
          entitlement_contributors⇐source.entitlement_contributors,
          consumption_contributors⇐source.consumption_contributors,
          refund_contributors⇐source.refund_contributors,plan_contributors⇐source.plan_contributors
        },
        totals⇐statement.totals,funding_account_indices⇐statement.funding_account_indices,
        funding_contributors⇐statement.funding_contributors,
        unassigned_contributors⇐statement.unassigned_contributors,diagnostics⇐empty
      }
    }⍟(0=≠diagnostics) @
    {𝕊:result↩EmptyResult ⟨"error","",diagnostics⟩}⍟(0<≠diagnostics) @
  }⍟(statement.state≡"ok") @
  result
}

AmountText ← {𝕊 value‿scaleValue: amount.Format ⟨value,scaleValue⟩}
FormatHuman ← {𝕊 result:
  rows ← {𝕊 i:
    ⟨i⊑result.envelopes.category⟩∾{AmountText ⟨𝕩,result.scale⟩}¨⟨
      i⊑result.envelopes.entitlement,i⊑result.envelopes.actual_consumption,
      i⊑result.envelopes.actual_refunds,i⊑result.envelopes.ledger_remaining,
      i⊑result.envelopes.open_plan_reserve,i⊑result.envelopes.post_plan_headroom
    ⟩
  }¨result.envelopes.index
  out ← "== Envelope & Backing =="∾(@+10)
  out ∾↩ "Horizon: "∾result.start∾".."∾result.end_exclusive∾(@+10)
  out ∾↩ "Observed through: "∾result.observation∾(@+10)∾(@+10)
  out ∾↩ text.RenderTable ⟨⟨"Envelope","Entitlement","Consumption","Refunds","Remaining","Plan reserve","Headroom"⟩,rows,⟨1,2,3,4,5,6⟩⟩
  out ∾↩ (@+10)∾"Backing evidence"∾(@+10)
  backingRows ← ⟨
    ⟨"Funding balance",AmountText ⟨result.totals.funding_balance,result.scale⟩⟩,
    ⟨"Signed envelope total",AmountText ⟨result.totals.signed_envelope_total,result.scale⟩⟩,
    ⟨"Positive backing required",AmountText ⟨result.totals.backing_required,result.scale⟩⟩,
    ⟨"Backing surplus",AmountText ⟨result.totals.backing_surplus,result.scale⟩⟩,
    ⟨"Budget unassigned",AmountText ⟨result.totals.ledger_unassigned,result.scale⟩⟩,
    ⟨"Reconciliation delta",AmountText ⟨result.totals.reconciliation_delta,result.scale⟩⟩
  ⟩
  out ∾↩ text.RenderTable ⟨⟨"Coordinate","Amount"⟩,backingRows,⟨1⟩⟩
  out ∾↩ "Status: "∾result.status∾(@+10)∾(@+10)
  out
}

FormatCompact ← {𝕊 result:
  out ← "--- Ledger Envelope & Backing ---"∾(@+10)
  {𝕊 i:
    out∾↩"ledger_envelope_item: "∾(i⊑result.envelopes.category)
    out∾↩" entitlement="∾(AmountText ⟨i⊑result.envelopes.entitlement,result.scale⟩)
    out∾↩" consumption="∾(AmountText ⟨i⊑result.envelopes.actual_consumption,result.scale⟩)
    out∾↩" refunds="∾(AmountText ⟨i⊑result.envelopes.actual_refunds,result.scale⟩)
    out∾↩" remaining="∾(AmountText ⟨i⊑result.envelopes.ledger_remaining,result.scale⟩)
    out∾↩" reserve="∾(AmountText ⟨i⊑result.envelopes.open_plan_reserve,result.scale⟩)
    out∾↩" headroom="∾(AmountText ⟨i⊑result.envelopes.post_plan_headroom,result.scale⟩)∾(@+10)
  }¨result.envelopes.index
  pairs ← ⟨
    ⟨"funding_balance",result.totals.funding_balance⟩,⟨"signed_total",result.totals.signed_envelope_total⟩,
    ⟨"backing_required",result.totals.backing_required⟩,⟨"backing_surplus",result.totals.backing_surplus⟩,
    ⟨"ledger_unassigned",result.totals.ledger_unassigned⟩,⟨"reconciliation_delta",result.totals.reconciliation_delta⟩
  ⟩
  {𝕊 pair: out∾↩"ledger_envelope_"∾(0⊑pair)∾": "∾(AmountText ⟨1⊑pair,result.scale⟩)∾(@+10)}¨pairs
  out∾"ledger_envelope_status: "∾result.status∾(@+10)
}

EnvelopeJson ← {𝕊 result‿i:
  json.Object ⟨
    json.Pair ⟨"category",json.String i⊑result.envelopes.category⟩,
    json.Pair ⟨"account",json.String i⊑result.envelopes.account_key⟩,
    json.Pair ⟨"entitlement",json.ExactNumber ⟨i⊑result.envelopes.entitlement,result.scale⟩⟩,
    json.Pair ⟨"actual_consumption",json.ExactNumber ⟨i⊑result.envelopes.actual_consumption,result.scale⟩⟩,
    json.Pair ⟨"actual_refunds",json.ExactNumber ⟨i⊑result.envelopes.actual_refunds,result.scale⟩⟩,
    json.Pair ⟨"ledger_remaining",json.ExactNumber ⟨i⊑result.envelopes.ledger_remaining,result.scale⟩⟩,
    json.Pair ⟨"open_plan_reserve",json.ExactNumber ⟨i⊑result.envelopes.open_plan_reserve,result.scale⟩⟩,
    json.Pair ⟨"post_plan_headroom",json.ExactNumber ⟨i⊑result.envelopes.post_plan_headroom,result.scale⟩⟩
  ⟩
}
FormatJson ← {𝕊 result:
  totals ← result.totals
  (json.Object ⟨
    json.Pair ⟨"currency",json.String result.domain⟩,
    json.Pair ⟨"start",json.String result.start⟩,
    json.Pair ⟨"end_exclusive",json.String result.end_exclusive⟩,
    json.Pair ⟨"observation",json.String result.observation⟩,
    json.Pair ⟨"envelopes",json.Array {EnvelopeJson ⟨result,𝕩⟩}¨result.envelopes.index⟩,
    json.Pair ⟨"funding_balance",json.ExactNumber ⟨totals.funding_balance,result.scale⟩⟩,
    json.Pair ⟨"signed_envelope_total",json.ExactNumber ⟨totals.signed_envelope_total,result.scale⟩⟩,
    json.Pair ⟨"backing_required",json.ExactNumber ⟨totals.backing_required,result.scale⟩⟩,
    json.Pair ⟨"backing_surplus",json.ExactNumber ⟨totals.backing_surplus,result.scale⟩⟩,
    json.Pair ⟨"ledger_unassigned",json.ExactNumber ⟨totals.ledger_unassigned,result.scale⟩⟩,
    json.Pair ⟨"reconciliation_delta",json.ExactNumber ⟨totals.reconciliation_delta,result.scale⟩⟩,
    json.Pair ⟨"status",json.String result.status⟩
  ⟩)∾(@+10)
}

{Build⇐Build,FormatHuman⇐FormatHuman,FormatCompact⇐FormatCompact,FormatJson⇐FormatJson}
