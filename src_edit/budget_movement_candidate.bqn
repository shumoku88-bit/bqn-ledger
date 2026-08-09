# Pure canonical Budget movement candidate preparation.
#
# Input intent is one scalar namespace: date, description, from_account,
# to_account, positive exact amount text, Commodity, and source-ordered metadata.
# Output payload is one canonical Journal block. Complete-source re-admission
# preserves transaction and Posting source order; no legacy row shape exists here.

canonical ← •Import "../src/application/canonical_household_sources.bqn"
rootAdmission ← •Import "../src/ledger/canonical_journal_root_admission.bqn"
budgetAdmission ← •Import "../src/ledger/budget_journal_admission.bqn"
decimal ← •Import "../src/ledger/exact_decimal.bqn"

lf ← @+10
empty ← ⟨⟩
Unique ← {𝕊 xs: ((xs⊐xs)=↕≠xs)/xs}
ResultError ← {𝕊 messageText:{state⇐"error",message⇐messageText,payload⇐"",candidate_ordinal⇐¯1}}

Prepare ← {𝕊 raw‿accounts‿registry‿intent:
  result ← ResultError "invalid canonical Budget movement intent"
  failed ← 0
  Reject ← {𝕊 messageText: {𝕊:failed↩1 ⋄ result↩ResultError messageText}⍟(¬failed) @ }
  RejectIf ← {𝕊 condition‿messageText: {𝕊:Reject messageText}⍟condition @ }

  fromMask ← intent.from_account⊸≡¨accounts.key
  toMask ← intent.to_account⊸≡¨accounts.key
  RejectIf ⟨1≠+´fromMask,"from Budget Account must resolve exactly once"⟩
  RejectIf ⟨1≠+´toMask,"to Budget Account must resolve exactly once"⟩
  RejectIf ⟨intent.from_account≡intent.to_account,"Budget movement from/to Accounts must differ"⟩
  {𝕊:
    fromIndex ← ⊑fromMask/↕accounts.count
    toIndex ← ⊑toMask/↕accounts.count
    fromCurrency ← fromIndex⊑accounts.currency
    toCurrency ← toIndex⊑accounts.currency
    RejectIf ⟨(fromIndex⊑accounts.role)≢"budget","Budget movement from Account is not type Budget"⟩
    RejectIf ⟨(toIndex⊑accounts.role)≢"budget","Budget movement to Account is not type Budget"⟩
    RejectIf ⟨(0<≠fromCurrency) ∧ intent.currency≢fromCurrency,"Budget movement from Account Commodity mismatch"⟩
    RejectIf ⟨(0<≠toCurrency) ∧ intent.currency≢toCurrency,"Budget movement to Account Commodity mismatch"⟩
  }⍟(¬failed) @

  parsedAmount ← decimal.Parse intent.amount
  RejectIf ⟨(parsedAmount.state≢"ok") ∨ parsedAmount.coefficient≤0,"Budget movement amount must be an exact positive decimal"⟩
  metadataKeys ← {𝕩.key}¨intent.metadata
  RejectIf ⟨(≠metadataKeys)≠≠Unique metadataKeys,"Budget movement metadata keys must be unique"⟩

  existingRoot ← rootAdmission.Admit ⟨raw,canonical.accounts⟩
  RejectIf ⟨existingRoot.state≢"ok","canonical budget.journal root include topology rejected"⟩
  existing ← budgetAdmission.Admit ⟨raw,accounts,registry⟩
  RejectIf ⟨existing.state≢"ok","existing canonical budget.journal rejected"⟩

  {𝕊:
    metadataLines ← {"    ; "∾𝕩.key∾": "∾𝕩.value}¨intent.metadata
    blockLines ← ⟨intent.date∾" "∾intent.description⟩∾metadataLines∾⟨
      "    "∾intent.from_account∾"    -"∾intent.amount∾" "∾intent.currency,
      "    "∾intent.to_account∾"    "∾intent.amount∾" "∾intent.currency
    ⟩
    block ← ⊑blockLines
    {𝕊 line:block∾↩lf∾line}¨1↓blockLines

    rawCount ← ≠raw
    endsOne ← (0<rawCount) ∧ lf=¯1⊑raw
    endsTwo ← (1<rawCount) ∧ (lf=¯1⊑raw) ∧ lf=¯2⊑raw
    payload ← block
    {𝕊:payload↩lf∾block}⍟(¬endsTwo) @
    candidateBase ← raw
    {𝕊:candidateBase↩raw∾lf}⍟(¬endsOne) @
    proposedRaw ← candidateBase∾payload∾lf

    proposedRoot ← rootAdmission.Admit ⟨proposedRaw,canonical.accounts⟩
    RejectIf ⟨proposedRoot.state≢"ok","proposed budget.journal root include topology rejected"⟩
    proposed ← budgetAdmission.Admit ⟨proposedRaw,accounts,registry⟩
    {𝕊:
      diagnostic ← ⊑proposed.diagnostics
      Reject ("proposed canonical Budget movement rejected: "∾diagnostic.code∾" at line "∾•Fmt diagnostic.line)
    }⍟(proposed.state≢"ok") @

    {𝕊:
      ordinal ← ≠existing.transactions
      RejectIf ⟨(ordinal+1)≠≠proposed.transactions,"proposed budget.journal must contain exactly one new Budget movement"⟩
      {𝕊:
        candidate ← ordinal⊑proposed.transactions
        candidateAccounts ← {𝕩.account_key}¨candidate.postings
        candidateAmounts ← {𝕩.amount_text}¨candidate.postings
        candidateCommodities ← {𝕩.commodity}¨candidate.postings
        candidateMetadata ← {𝕩.key∾"="∾𝕩.value}¨candidate.metadata
        intentMetadata ← {𝕩.key∾"="∾𝕩.value}¨intent.metadata
        exact ← (candidate.date≡intent.date) ∧ (candidate.description≡intent.description) ∧ (candidateAccounts≡intent.from_account‿intent.to_account) ∧ (candidateAmounts≡("-"∾intent.amount)‿intent.amount) ∧ (candidateCommodities≡intent.currency‿intent.currency) ∧ candidateMetadata≡intentMetadata
        RejectIf ⟨¬exact,"parsed Budget candidate does not exactly match rendered movement intent"⟩
        {𝕊:result↩{state⇐"ok",message⇐"",payload⇐payload,candidate_ordinal⇐ordinal}}⍟(¬failed) @
      }⍟(¬failed) @
    }⍟(¬failed) @
  }⍟(¬failed) @
  result
}

{Prepare⇐Prepare}
