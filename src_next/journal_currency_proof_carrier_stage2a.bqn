# journal_currency_proof_carrier_stage2a.bqn
# Pure Stage 2A carrier for admitted complete-source Journal transactions.
#
# This module deliberately does not emit the current untyped `delta` Posting IR.
# Every money coefficient remains attached to its transaction domain and exact
# calculation scale. No I/O, aggregation, valuation, or consumer wiring occurs.

dt ← •Import "date.bqn"
proj ← •Import "projection.bqn"
decimal ← •Import "exact_decimal.bqn"
setup ← •Import "currency_setup.bqn"

layers ← ⟨"actual", "plan", "budget", "forecast"⟩
identityKinds ← ⟨"durable", "physical_fallback"⟩
empty ← ⟨⟩

Contains ← {𝕊 item‿items: ∨´ 0 ∾ item⊸≡¨ items }
Unique ← {𝕊 items:
  result ← empty
  {𝕊 item: {𝕊: result ∾↩ ⟨item⟩}⍟(¬ Contains ⟨item, result⟩) @}¨ items
  result
}

Diagnostic ← {𝕊 codeText‿transactionIndex‿postingIndex‿messageText:
  {
    severity⇐"error",
    stage⇐"journal_currency_proof_carrier_stage2a",
    code⇐codeText,
    transaction_index⇐transactionIndex,
    posting_index⇐postingIndex,
    message⇐messageText
  }
}
AddIf ← {𝕊 invalid‿diagnostic: invalid / ⟨diagnostic⟩ }

LookupAccount ← {𝕊 accountName‿resolved:
  mask ← accountName⊸≡¨ resolved.accounts
  count ← +´ mask
  index ← ≠ resolved.accounts
  {𝕊: index ↩ ⊑ mask / ↕ ≠ mask}⍟(1 = count) @
  {count⇐count, index⇐index}
}

ExpectedNormalized ← {𝕊 posting‿calculationScale:
  valid ← (0 ≤ posting.source_scale) ∧ (posting.source_scale ≤ calculationScale)
  coefficient ← 0
  {𝕊:
    zeroCount ← calculationScale - posting.source_scale
    magnitudeText ← (•Fmt | posting.source_coefficient) ∾ zeroCount ⥊ '0'
    magnitude ← decimal.Parse magnitudeText
    {𝕊: coefficient ↩ (1 - 2 × (posting.source_coefficient < 0)) × magnitude.coefficient}⍟(magnitude.state ≡ "ok") @
    valid ↩ valid ∧ (magnitude.state ≡ "ok")
  }⍟valid @
  {valid⇐valid, coefficient⇐coefficient}
}

RoleForPosting ← {𝕊 posting‿resolved:
  lookup ← LookupAccount ⟨posting.account_key, resolved⟩
  role ← ""
  {𝕊: role ↩ lookup.index ⊑ resolved.roles}⍟(1 = lookup.count) @
  role
}

KindForTransaction ← {𝕊 transaction‿resolved:
  isIncome ← ∨´ 0 ∾ { (𝕩.normalized_coefficient < 0) ∧ (RoleForPosting ⟨𝕩, resolved⟩) ≡ "income" }¨ transaction.postings
  isExpense ← ∨´ 0 ∾ { (0 < 𝕩.normalized_coefficient) ∧ (RoleForPosting ⟨𝕩, resolved⟩) ≡ "expense" }¨ transaction.postings
  kind ← isExpense ⊑ (isIncome ⊑ "transfer"‿"income")‿"expense"
  (transaction.layer_name ≡ "budget") ⊑ kind‿"budget"
}

BuildForSource ← {𝕊 transactions‿resolved‿cycleStart‿sourceFile:
  diagnostics ← empty
  rows ← empty
  transactionDomains ← empty

  {𝕊 transactionIndex:
    transaction ← transactionIndex ⊑ transactions
    policy ← setup.Policy transaction.domain
    layerIndex ← ⊑ layers ⊐ ⟨transaction.layer_name⟩
    txDiagnostics ← empty
    txDiagnostics ∾↩ AddIf ⟨policy.state ≢ "ok", Diagnostic ⟨"transaction_domain_unsupported", transactionIndex, ¯1, "transaction domain must be admitted by registry"⟩⟩
    txDiagnostics ∾↩ AddIf ⟨¬ Contains ⟨transaction.identity_kind, identityKinds⟩, Diagnostic ⟨"transaction_identity_kind_invalid", transactionIndex, ¯1, "transaction identity kind is unsupported"⟩⟩
    txDiagnostics ∾↩ AddIf ⟨0 = ≠ transaction.source_event_id, Diagnostic ⟨"transaction_source_id_missing", transactionIndex, ¯1, "transaction source identity must be present"⟩⟩
    txDiagnostics ∾↩ AddIf ⟨(transaction.source_start_line ≤ 0) ∨ (transaction.source_end_line < transaction.source_start_line), Diagnostic ⟨"transaction_source_range_invalid", transactionIndex, ¯1, "transaction source line range is invalid"⟩⟩
    txDiagnostics ∾↩ AddIf ⟨layerIndex = ≠ layers, Diagnostic ⟨"transaction_layer_invalid", transactionIndex, ¯1, "transaction layer is unsupported"⟩⟩
    txDiagnostics ∾↩ AddIf ⟨transaction.calculation_scale < 0, Diagnostic ⟨"transaction_scale_invalid", transactionIndex, ¯1, "transaction calculation scale must be nonnegative"⟩⟩
    txDiagnostics ∾↩ AddIf ⟨0 = ≠ transaction.postings, Diagnostic ⟨"transaction_postings_missing", transactionIndex, ¯1, "transaction must contain postings"⟩⟩
    diagnostics ∾↩ txDiagnostics

    transactionDomains ∾↩ ⟨transaction.domain⟩
    dayIndex ← 0
    {𝕊: dayIndex ↩ proj.ResolveDayFromCycle ⟨transaction.date, cycleStart⟩}⍟(dt.IsValidDateText cycleStart) @
    kind ← KindForTransaction ⟨transaction, resolved⟩
    txId ← (0 < ≠ transaction.txn_id) ⊑ transaction.source_event_id‿transaction.txn_id
    txRows ← empty
    normalizedTotal ← 0

    {𝕊 postingIndex:
      posting ← postingIndex ⊑ transaction.postings
      lookup ← LookupAccount ⟨posting.account_key, resolved⟩
      accountCurrency ← ""
      accountKey ← ""
      {𝕊:
        accountCurrency ↩ lookup.index ⊑ resolved.currencies
        accountKey ↩ lookup.index ⊑ resolved.account_keys
      }⍟(1 = lookup.count) @
      expected ← ExpectedNormalized ⟨posting, transaction.calculation_scale⟩
      postingDiagnostics ← empty
      postingDiagnostics ∾↩ AddIf ⟨0 = ≠ posting.posting_id, Diagnostic ⟨"posting_id_missing", transactionIndex, postingIndex, "posting identity must be present"⟩⟩
      postingDiagnostics ∾↩ AddIf ⟨posting.posting_index ≠ postingIndex, Diagnostic ⟨"posting_index_mismatch", transactionIndex, postingIndex, "posting index must match source order"⟩⟩
      postingDiagnostics ∾↩ AddIf ⟨posting.source_line ≤ 0, Diagnostic ⟨"posting_source_line_invalid", transactionIndex, postingIndex, "posting source line must be positive"⟩⟩
      postingDiagnostics ∾↩ AddIf ⟨(posting.source_line < transaction.source_start_line) ∨ (transaction.source_end_line < posting.source_line), Diagnostic ⟨"posting_source_range_mismatch", transactionIndex, postingIndex, "posting source line must remain within its transaction source range"⟩⟩
      postingDiagnostics ∾↩ AddIf ⟨posting.commodity ≢ transaction.domain, Diagnostic ⟨"posting_domain_mismatch", transactionIndex, postingIndex, "posting commodity differs from transaction domain"⟩⟩
      postingDiagnostics ∾↩ AddIf ⟨posting.account_currency ≢ transaction.domain, Diagnostic ⟨"posting_account_currency_mismatch", transactionIndex, postingIndex, "posting account currency differs from transaction domain"⟩⟩
      postingDiagnostics ∾↩ AddIf ⟨lookup.count ≠ 1, Diagnostic ⟨"posting_account_unresolved", transactionIndex, postingIndex, "posting account must resolve exactly once"⟩⟩
      postingDiagnostics ∾↩ AddIf ⟨(lookup.count = 1) ∧ (accountCurrency ≢ posting.account_currency), Diagnostic ⟨"posting_resolved_currency_mismatch", transactionIndex, postingIndex, "resolved account currency differs from admitted proof"⟩⟩
      postingDiagnostics ∾↩ AddIf ⟨¬ expected.valid, Diagnostic ⟨"posting_scale_invalid", transactionIndex, postingIndex, "posting source scale cannot normalize to transaction scale"⟩⟩
      postingDiagnostics ∾↩ AddIf ⟨expected.valid ∧ (expected.coefficient ≠ posting.normalized_coefficient), Diagnostic ⟨"posting_normalization_mismatch", transactionIndex, postingIndex, "normalized coefficient does not match exact source evidence"⟩⟩
      diagnostics ∾↩ postingDiagnostics
      normalizedTotal +↩ posting.normalized_coefficient

      {𝕊:
        txRows ∾↩ ⟨{
          source_file⇐sourceFile,
          source_row⇐transactionIndex,
          transaction_index⇐transactionIndex,
          source_start_line⇐transaction.source_start_line,
          source_end_line⇐transaction.source_end_line,
          source_id⇐transaction.source_event_id,
          identity_kind⇐transaction.identity_kind,
          tx_id⇐txId,
          posting_id⇐posting.posting_id,
          posting_index⇐postingIndex,
          source_line⇐posting.source_line,
          date⇐transaction.date,
          day_index⇐dayIndex,
          account_name⇐posting.account_key,
          account_key⇐accountKey,
          account_key_index⇐lookup.index,
          layer_name⇐transaction.layer_name,
          layer_index⇐layerIndex,
          side⇐posting.side,
          kind⇐kind,
          domain⇐transaction.domain,
          calculation_scale⇐transaction.calculation_scale,
          account_currency⇐posting.account_currency,
          commodity⇐posting.commodity,
          amount_text⇐posting.amount_text,
          source_coefficient⇐posting.source_coefficient,
          source_scale⇐posting.source_scale,
          normalized_coefficient⇐posting.normalized_coefficient,
          status⇐"ok",
          message⇐""
        }⟩
      }⍟((0 = ≠ txDiagnostics) ∧ (0 = ≠ postingDiagnostics)) @
    }¨ ↕ ≠ transaction.postings

    diagnostics ∾↩ AddIf ⟨0 ≠ normalizedTotal, Diagnostic ⟨"transaction_unbalanced", transactionIndex, ¯1, "normalized posting coefficients must balance within the transaction domain"⟩⟩
    {𝕊: rows ∾↩ txRows}⍟((0 = ≠ txDiagnostics) ∧ (0 = normalizedTotal)) @
  }¨ ↕ ≠ transactions

  durable ← ({𝕩.identity_kind ≡ "durable"}¨ transactions) / transactions
  durableIds ← {<𝕩.source_event_id}¨ durable
  postingIds ← ∾ { {<𝕩.posting_id}¨ 𝕩.postings }¨ transactions
  diagnostics ∾↩ AddIf ⟨(≠ durableIds) ≠ ≠ ⍷ durableIds, Diagnostic ⟨"event_id_duplicate", ¯1, ¯1, "durable source identities must be unique across the carrier input"⟩⟩
  diagnostics ∾↩ AddIf ⟨(≠ postingIds) ≠ ≠ ⍷ postingIds, Diagnostic ⟨"posting_id_duplicate", ¯1, ¯1, "posting identities must be unique across the carrier input"⟩⟩
  {𝕊: rows ↩ empty}⍟(0 < ≠ diagnostics) @

  {
    state⇐(0 = ≠ diagnostics) ⊑ "error"‿"ok",
    transaction_domains⇐transactionDomains,
    currency_proof_rows⇐rows,
    diagnostics⇐diagnostics
  }
}

Build ← {𝕊 transactions‿resolved‿cycleStart:
  BuildForSource ⟨transactions, resolved, cycleStart, "profile.journal"⟩
}

{Build⇐Build, BuildForSource⇐BuildForSource}
