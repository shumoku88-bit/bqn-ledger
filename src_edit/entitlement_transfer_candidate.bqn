# Pure canonical Entitlement transfer candidate preparation.
#
# Input intent: date, from, to, amount, currency, memo.
# Output payload: one canonical Entitlement Journal line. Complete-source re-admission
# preserves StockOrigin and Transfer source order and laws.

entitlementAdmission ← •Import "../src/ledger/entitlement_journal_admission.bqn"
decimal ← •Import "../src/ledger/exact_decimal.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"

lf ← @+10
ResultError ← {𝕊 messageText: {state⇐"error",message⇐messageText,payload⇐"",candidate_ordinal⇐¯1}}
Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}

Prepare ← {𝕊 raw‿envelopeHistory‿registry‿intent:
  result ← ResultError "invalid canonical Entitlement transfer intent"
  failed ← 0
  Reject ← {𝕊 messageText: {𝕊:failed↩1 ⋄ result↩ResultError messageText}⍟(¬failed) @}
  RejectIf ← {𝕊 condition‿messageText: {𝕊:Reject messageText}⍟condition @}

  RejectIf ⟨¬dates.IsValid intent.date,"transfer date must be a valid YYYY-MM-DD date"⟩
  RejectIf ⟨intent.from≡intent.to,"transfer from/to endpoints must differ"⟩
  knownIds ← envelopeHistory.registry.id
  fromValid ← (intent.from≡"unallocated") ∨ Contains ⟨intent.from,knownIds⟩
  toValid ← (intent.to≡"unallocated") ∨ Contains ⟨intent.to,knownIds⟩
  RejectIf ⟨¬fromValid,("transfer from endpoint is not a known Envelope identity: "∾intent.from)⟩
  RejectIf ⟨¬toValid,("transfer to endpoint is not a known Envelope identity: "∾intent.to)⟩

  parsedAmount ← decimal.Parse intent.amount
  RejectIf ⟨(parsedAmount.state≢"ok") ∨ parsedAmount.coefficient≤0,"transfer amount must be an exact positive decimal"⟩
  policy ← registry.Policy intent.currency
  RejectIf ⟨policy.state≢"ok",("transfer currency is unsupported: "∾intent.currency)⟩

  existing ← entitlementAdmission.Admit ⟨raw,envelopeHistory,registry⟩
  RejectIf ⟨existing.state≢"ok","existing canonical entitlement.journal rejected"⟩

  {𝕊:
    line ← intent.date ∾ " transfer " ∾ intent.from ∾ " -> " ∾ intent.to ∾ " " ∾ intent.amount ∾ " " ∾ intent.currency
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
      Reject ("proposed canonical Entitlement transfer rejected: "∾diagnostic.code∾" at line "∾•Fmt diagnostic.line)
    }⍟(proposed.state≢"ok") @

    {𝕊:
      ordinal ← existing.transfers.count
      RejectIf ⟨(ordinal+1)≠proposed.transfers.count,"proposed entitlement.journal must contain exactly one new transfer"⟩
      {𝕊:
        candidate ← {
          date⇐ordinal⊑proposed.transfers.date,
          from⇐ordinal⊑proposed.transfers.from,
          to⇐ordinal⊑proposed.transfers.to,
          amount_text⇐ordinal⊑proposed.transfers.amount_text,
          commodity⇐ordinal⊑proposed.transfers.commodity,
          memo⇐ordinal⊑proposed.transfers.memo
        }
        exact ← (candidate.date≡intent.date) ∧ (candidate.from≡intent.from) ∧ (candidate.to≡intent.to) ∧ (candidate.amount_text≡intent.amount) ∧ (candidate.commodity≡intent.currency) ∧ candidate.memo≡intent.memo
        RejectIf ⟨¬exact,"parsed Entitlement transfer candidate does not exactly match rendered intent"⟩
        {𝕊: result ↩ {state⇐"ok",message⇐"",payload⇐payload,candidate_ordinal⇐ordinal}}⍟(¬failed) @
      }⍟(¬failed) @
    }⍟(¬failed) @
  }⍟(¬failed) @
  result
}

{Prepare⇐Prepare}
