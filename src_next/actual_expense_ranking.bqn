# actual_expense_ranking.bqn
# Pure selected-period Actual expense ranking over checked posting facts.
#
# This consumer deliberately does not depend on Cube or TBDS. It owns one real
# query: select debit-side Actual expense facts in the requested period, build
# semantic AccountKey keys, group exact values, and rank the sparse result.
#
# Input rows must already belong to one selected arithmetic domain and one exact
# calculation scale. Mixed domains or scales fail closed before numeric output.

sparse ← •Import "exact_sparse_grouping.bqn"

empty ← ⟨⟩

Diagnostic ← {𝕊 codeText‿messageText:
  {severity⇐"error", stage⇐"actual_expense_ranking", code⇐codeText, message⇐messageText}
}

Failure ← {𝕊 currency‿scale‿code‿message:
  {
    state                       ⇐ "error",
    selected_currency           ⇐ currency,
    calculation_scale           ⇐ scale,
    selected_rows               ⇐ empty,
    selected_count              ⇐ 0,
    grouped_keys                ⇐ empty,
    grouped_values              ⇐ empty,
    grouped_count               ⇐ 0,
    contributor_indices         ⇐ empty,
    contributor_posting_ids     ⇐ empty,
    ranking_order               ⇐ empty,
    ranked_keys                 ⇐ empty,
    ranked_values               ⇐ empty,
    ranked_contributor_indices  ⇐ empty,
    ranked_contributor_posting_ids ⇐ empty,
    selected_total              ⇐ 0,
    grouped_total               ⇐ 0,
    conserved                   ⇐ 0,
    diagnostics                 ⇐ ⟨Diagnostic ⟨code, message⟩⟩,
    message                     ⇐ message
  }
}

Build ← {𝕊 rows‿dayCount‿selectedCurrency‿calculationScale:
  domains ← {𝕩.domain}¨ rows
  scales ← {𝕩.calculation_scale}¨ rows
  domainMismatch ← ∨´ 0 ∾ ¬ selectedCurrency⊸≡¨ domains
  scaleMismatch ← ∨´ 0 ∾ scales ≠ calculationScale

  result ← Failure ⟨selectedCurrency, calculationScale, "domain_mismatch", "posting facts must belong to the selected arithmetic domain"⟩

  {𝕊:
    result ↩ Failure ⟨selectedCurrency, calculationScale, "calculation_scale_mismatch", "posting facts must share the selected exact calculation scale"⟩
  }⍟((¬domainMismatch) ∧ scaleMismatch) @

  {𝕊:
    days ← {𝕩.day_index}¨ rows
    selectedMask ←
      ("ok"⊸≡¨ {𝕩.status}¨ rows) ∧
      ("actual"⊸≡¨ {𝕩.layer_name}¨ rows) ∧
      (days ≥ 0) ∧ (days < dayCount) ∧
      ("expense"⊸≡¨ {𝕩.kind}¨ rows) ∧
      ("debit"⊸≡¨ {𝕩.side}¨ rows)

    selectedRows ← selectedMask / rows
    keys ← {𝕩.account_key}¨ selectedRows
    values ← {𝕩.delta}¨ selectedRows
    postingIds ← {𝕩.posting_id}¨ selectedRows
    grouped ← sparse.Group ⟨keys, values⟩

    result ↩ Failure ⟨selectedCurrency, calculationScale, "grouping_failed", grouped.message⟩

    {𝕊:
      contributors ← sparse.ContributorIndices ⟨keys, grouped.keys⟩
      contributorPostingIds ← {𝕩 ⊏ postingIds}¨ contributors

      # Stable two-stage ordering: semantic key ascending, then amount descending.
      # Equal amounts therefore retain AccountKey ascending order.
      keyOrder ← ⍋ grouped.keys
      keySortedValues ← keyOrder ⊏ grouped.values
      amountOrder ← ⍋ (- keySortedValues)
      rankingOrder ← amountOrder ⊏ keyOrder

      rankedKeys ← rankingOrder ⊏ grouped.keys
      rankedValues ← rankingOrder ⊏ grouped.values
      rankedContributors ← rankingOrder ⊏ contributors
      rankedContributorPostingIds ← rankingOrder ⊏ contributorPostingIds

      result ↩ {
        state                       ⇐ "ok",
        selected_currency           ⇐ selectedCurrency,
        calculation_scale           ⇐ calculationScale,
        selected_rows               ⇐ selectedRows,
        selected_count              ⇐ ≠ selectedRows,
        grouped_keys                ⇐ grouped.keys,
        grouped_values              ⇐ grouped.values,
        grouped_count               ⇐ grouped.grouped_count,
        contributor_indices         ⇐ contributors,
        contributor_posting_ids     ⇐ contributorPostingIds,
        ranking_order               ⇐ rankingOrder,
        ranked_keys                 ⇐ rankedKeys,
        ranked_values               ⇐ rankedValues,
        ranked_contributor_indices  ⇐ rankedContributors,
        ranked_contributor_posting_ids ⇐ rankedContributorPostingIds,
        selected_total              ⇐ grouped.input_total,
        grouped_total               ⇐ grouped.grouped_total,
        conserved                   ⇐ grouped.conserved,
        diagnostics                 ⇐ empty,
        message                     ⇐ ""
      }
    }⍟(grouped.state ≡ "ok") @
  }⍟((¬domainMismatch) ∧ (¬scaleMismatch)) @

  result
}

{Build⇐Build}
