# journal_posting_identity_provenance_stage2b.bqn
# Pure, test-only identity/provenance carrier for admitted Stage 1 transactions
# and their corresponding Stage 2A current 16-field Posting IR rows.
#
# This module performs no I/O, does not reproduce Stage 2A semantics, and is
# not connected to production routing.

empty ← ⟨⟩
validIdentityKinds ← ⟨<"durable", <"physical_fallback"⟩

Diagnostic ← {𝕊 codeText‿messageText:
  {severity⇐"error", stage⇐"journal_posting_identity_provenance_stage2b", code⇐codeText, message⇐messageText}
}

AddIf ← {𝕊 diagnostics‿invalid‿codeText‿messageText:
  diagnostics ∾ invalid / ⟨Diagnostic ⟨codeText, messageText⟩⟩
}

IsOneOf ← {𝕊 text‿boxedValues:
  ∨´ 0 ∾ {text ≡ >𝕩}¨ boxedValues
}

Build ← {𝕊 transactions‿postingRows:
  diagnostics ← empty
  provenanceRows ← empty
  flattenedPostingIds ← empty
  flattenedSourceIds ← empty
  flattenedTxIds ← empty

  {𝕊 transaction:
    eventId ← transaction.source_event_id
    identityKind ← transaction.identity_kind
    txId ← (0 < ≠ transaction.txn_id) ⊑ eventId‿transaction.txn_id
    startLine ← transaction.source_start_line
    endLine ← transaction.source_end_line
    postings ← transaction.postings
    indices ← {𝕩.posting_index}¨ postings
    expectedIndices ← ↕ ≠ postings

    diagnostics ↩ AddIf ⟨diagnostics, 0 = ≠ eventId, "event_identity_missing", "source_event_id must be nonempty"⟩
    diagnostics ↩ AddIf ⟨diagnostics, ¬ IsOneOf ⟨identityKind, validIdentityKinds⟩, "identity_kind_unknown", "identity_kind must be durable or physical_fallback"⟩
    diagnostics ↩ AddIf ⟨diagnostics, (startLine < 1) ∨ endLine < startLine, "source_span_invalid", "source span must be one-based with end at or after start"⟩
    diagnostics ↩ AddIf ⟨diagnostics, (≠ indices) ≠ ≠ ⍷ indices, "posting_index_duplicate", "posting indices must be unique within an event"⟩
    diagnostics ↩ AddIf ⟨diagnostics, indices ≢ expectedIndices, "posting_index_non_contiguous", "posting indices must be zero-based, contiguous, and in emitted order"⟩

    {𝕊 posting:
      expectedPostingId ← eventId ∾ ":" ∾ •Fmt posting.posting_index
      diagnostics ↩ AddIf ⟨diagnostics, posting.posting_id ≢ expectedPostingId, "posting_id_invalid", "posting_id must encode source_event_id and posting_index"⟩
      flattenedPostingIds ∾↩ ⟨<posting.posting_id⟩
      flattenedSourceIds ∾↩ ⟨<eventId⟩
      flattenedTxIds ∾↩ ⟨<txId⟩
      provenanceRows ∾↩ ⟨{
        source_event_id⇐eventId,
        identity_kind⇐identityKind,
        source_start_line⇐startLine,
        source_end_line⇐endLine,
        posting_index⇐posting.posting_index,
        posting_id⇐posting.posting_id
      }⟩
    }¨ postings
  }¨ transactions

  diagnostics ↩ AddIf ⟨diagnostics, (≠ flattenedPostingIds) ≠ ≠ ⍷ flattenedPostingIds, "posting_id_duplicate", "posting_id values must be unique across the result"⟩
  diagnostics ↩ AddIf ⟨diagnostics, (≠ provenanceRows) ≠ ≠ postingRows, "posting_count_mismatch", "flattened transaction posting count must equal Posting IR row count"⟩

  {𝕊:
    aligned ← ∧´ {𝕊 i:
      row ← i ⊑ postingRows
      rowOk ← (> i ⊑ flattenedPostingIds) ≡ row.posting_id
      rowOk ↩ rowOk ∧ ((> i ⊑ flattenedSourceIds) ≡ row.source_id)
      rowOk ↩ rowOk ∧ ((> i ⊑ flattenedTxIds) ≡ row.tx_id)
      rowOk
    }¨ ↕ ≠ postingRows
    diagnostics ↩ AddIf ⟨diagnostics, ¬ aligned, "posting_id_alignment_mismatch", "Posting IR rows must preserve flattened posting ID, source identity, and business transaction linkage order"⟩
  }⍟((≠ provenanceRows) = ≠ postingRows) @

  failed ← 0 < ≠ diagnostics
  {
    state⇐failed ⊑ "ok"‿"error",
    posting_rows⇐failed ⊑ postingRows‿empty,
    provenance_rows⇐failed ⊑ provenanceRows‿empty,
    diagnostics⇐diagnostics
  }
}

{Build⇐Build}
