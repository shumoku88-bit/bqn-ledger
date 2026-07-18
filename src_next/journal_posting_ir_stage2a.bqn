# journal_posting_ir_stage2a.bqn
# Test-only success-path adapter from admitted Minimal Journal Stage 1
# Transaction IR to the current normalized Posting IR row shape.
#
# This module performs no I/O and is not connected to production routing.

proj ← •Import "projection.bqn"

layers ← ⟨"actual", "plan", "budget", "forecast"⟩

RoleForPosting ← {𝕊 posting‿resolved:
  i ← ⊑ resolved.accounts ⊐ ⟨posting.account_key⟩
  i ⊑ resolved.roles
}

KindForTransaction ← {𝕊 transaction‿resolved:
  isIncome ← ∨´ 0 ∾ { (𝕩.delta < 0) ∧ (RoleForPosting ⟨𝕩, resolved⟩) ≡ "income" }¨ transaction.postings
  isExpense ← ∨´ 0 ∾ { (0 < 𝕩.delta) ∧ (RoleForPosting ⟨𝕩, resolved⟩) ≡ "expense" }¨ transaction.postings
  kind ← isExpense ⊑ (isIncome ⊑ "transfer"‿"income")‿"expense"
  (transaction.layer_name ≡ "budget") ⊑ kind‿"budget"
}

Build ← {𝕊 transactions‿resolved‿cycleStart:
  rows ← ∾ {𝕊 transactionIndex:
    transaction ← transactionIndex ⊑ transactions
    layerIndex ← ⊑ layers ⊐ ⟨transaction.layer_name⟩
    kind ← KindForTransaction ⟨transaction, resolved⟩

    {𝕊 posting:
      accountIndex ← ⊑ resolved.accounts ⊐ ⟨posting.account_key⟩
      {
        source_file⇐"profile.journal",
        source_row⇐transactionIndex,
        source_id⇐transaction.source_event_id,
        tx_id⇐transaction.source_event_id,
        posting_id⇐posting.posting_id,
        date⇐transaction.date,
        day_index⇐proj.ResolveDayFromCycle ⟨transaction.date, cycleStart⟩,
        account_key⇐accountIndex ⊑ resolved.account_keys,
        account_key_index⇐accountIndex,
        layer_name⇐transaction.layer_name,
        layer_index⇐layerIndex,
        side⇐posting.side,
        delta⇐posting.delta,
        kind⇐kind,
        status⇐"ok",
        message⇐""
      }
    }¨ transaction.postings
  }¨ ↕ ≠ transactions

  {state⇐"ok", posting_rows⇐rows, diagnostics⇐⟨⟩}
}

{Build⇐Build}
