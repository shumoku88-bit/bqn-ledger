# Source-ordered typed transaction rows derived only from canonical facts.
# This is a narrow join capability for editor/recent consumers, not a source loader
# or report ViewModel.

empty ← ⟨⟩

Build ← {𝕊 factSet:
  rows ← empty
  {𝕊:
    postingGroups ← factSet.postings.transaction_index⊔factSet.postings.index

    MakePosting ← {𝕊 pi:
      ai ← pi⊑factSet.postings.account_index
      {
        posting_index⇐pi,
        posting_id⇐pi⊑factSet.postings.posting_id,
        transaction_posting_index⇐pi⊑factSet.postings.transaction_posting_index,
        account_index⇐ai,
        account_key⇐ai⊑factSet.accounts.key,
        side⇐pi⊑factSet.postings.side,
        coefficient⇐pi⊑factSet.postings.coefficient,
        scale⇐pi⊑factSet.postings.scale,
        source_coefficient⇐pi⊑factSet.postings.source_coefficient,
        source_scale⇐pi⊑factSet.postings.source_scale,
        amount_text⇐pi⊑factSet.postings.amount_text,
        source_line⇐pi⊑factSet.postings.source_line
      }
    }

    MakeRow ← {𝕊 ti:
      postings ← MakePosting¨ti⊑postingGroups
      li ← ti⊑factSet.transactions.layer_index
      di ← ti⊑factSet.transactions.domain_index
      {
        transaction_index⇐ti,
        transaction_id⇐ti⊑factSet.transactions.transaction_id,
        identity_kind⇐ti⊑factSet.transactions.identity_kind,
        date_text⇐ti⊑factSet.transactions.date_text,
        date_ordinal⇐ti⊑factSet.transactions.date_ordinal,
        status_marker⇐ti⊑factSet.transactions.status_marker,
        description⇐ti⊑factSet.transactions.description,
        layer⇐li⊑factSet.layers.name,
        domain⇐di⊑factSet.domains.code,
        calculation_scale⇐ti⊑factSet.transactions.calculation_scale,
        plan_id⇐ti⊑factSet.transactions.plan_id,
        metadata⇐ti⊑factSet.transactions.metadata,
        source_start_line⇐ti⊑factSet.transactions.source_start_line,
        source_end_line⇐ti⊑factSet.transactions.source_end_line,
        postings⇐postings
      }
    }

    rows↩MakeRow¨factSet.transactions.index
  }⍟(factSet.state≡"ok") @
  {state⇐factSet.state,rows⇐rows,diagnostics⇐factSet.diagnostics}
}

{Build⇐Build}
