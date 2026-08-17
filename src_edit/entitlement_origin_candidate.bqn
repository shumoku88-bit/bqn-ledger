# Pure canonical Entitlement StockOrigin candidate preparation.
#
# Input intent: date, currency, memo.
# Output payload: one canonical Entitlement Journal origin line.

entitlementAdmission ← •Import "../src/ledger/entitlement_journal_admission.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"

lf ← @+10
ResultError ← {𝕊 messageText: {state⇐"error",message⇐messageText,payload⇐"",candidate_ordinal⇐¯1}}

Prepare ← {𝕊 raw‿envelopeHistory‿registry‿intent:
  result ← ResultError "invalid canonical Entitlement origin intent"
  failed ← 0
  Reject ← {𝕊 messageText: {𝕊:failed↩1 ⋄ result↩ResultError messageText}⍟(¬failed) @}
  RejectIf ← {𝕊 condition‿messageText: {𝕊:Reject messageText}⍟condition @}

  RejectIf ⟨¬dates.IsValid intent.date,"StockOrigin date must be a valid YYYY-MM-DD date"⟩
  policy ← registry.Policy intent.currency
  RejectIf ⟨policy.state≢"ok",("StockOrigin currency is unsupported: "∾intent.currency)⟩

  existing ← entitlementAdmission.Admit ⟨raw,envelopeHistory,registry⟩
  RejectIf ⟨existing.state≢"ok","existing canonical entitlement.journal rejected"⟩

  {𝕊:
    line ← intent.date ∾ " origin " ∾ intent.currency
    {𝕊: line ∾↩ " ; " ∾ intent.memo}⍟(0<≠intent.memo) @

    rawCount ← ≠raw
    endsOne ← (0<rawCount) ∧ lf=¯1⊑raw
    payload ← line
    candidateBase ← raw
    {𝕊: candidateBase ↩ raw∾lf}⍟((0<rawCount) ∧ ¬endsOne) @
    proposedRaw ← candidateBase ∾ payload ∾ lf

    proposed ← entitlementAdmission.Admit ⟨proposedRaw,envelopeHistory,registry⟩
    {𝕊:
      diagnostic ← ⊑proposed.diagnostics
      Reject ("proposed canonical Entitlement StockOrigin rejected: "∾diagnostic.code∾" at line "∾•Fmt diagnostic.line)
    }⍟(proposed.state≢"ok") @

    {𝕊:
      ordinal ← existing.origins.count
      RejectIf ⟨(ordinal+1)≠proposed.origins.count,"proposed entitlement.journal must contain exactly one new StockOrigin"⟩
      {𝕊:
        candidate ← {
          date⇐ordinal⊑proposed.origins.date,
          commodity⇐ordinal⊑proposed.origins.commodity,
          memo⇐ordinal⊑proposed.origins.memo
        }
        exact ← (candidate.date≡intent.date) ∧ (candidate.commodity≡intent.currency) ∧ candidate.memo≡intent.memo
        RejectIf ⟨¬exact,"parsed Entitlement StockOrigin candidate does not exactly match rendered intent"⟩
        {𝕊: result ↩ {state⇐"ok",message⇐"",payload⇐payload,candidate_ordinal⇐ordinal}}⍟(¬failed) @
      }⍟(¬failed) @
    }⍟(¬failed) @
  }⍟(¬failed) @
  result
}

{Prepare⇐Prepare}
