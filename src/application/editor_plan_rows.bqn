# Read-only Plan projection for editor/list consumers.
#
# Canonical Plan and Actual Facts remain the source owners. This projection narrows
# one Plan transaction to the historical editor row shape only when it has exactly
# one debit and one credit. Multi-posting Plan transactions remain valid canonical
# source evidence and are rejected only at this narrower editor boundary.

io ← •Import "source_io.bqn"
registryBuilder ← •Import "../ledger/currency_registry.bqn"
planSource ← •Import "plan_source_adapter.bqn"
actualSource ← •Import "actual_source_adapter.bqn"
transactionRows ← •Import "../ledger/transaction_rows.bqn"
amountText ← •Import "../ledger/amount_text.bqn"
empty ← ⟨⟩

Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}
Diagnostic ← {𝕊 codeText‿messageText:
  {severity⇐"error",stage⇐"application_editor_plan_rows",code⇐codeText,message⇐messageText}
}

Build ← {𝕊 planFacts‿actualFacts:
  diagnostics ← empty
  planView ← transactionRows.Build planFacts
  actualView ← transactionRows.Build actualFacts
  diagnostics ∾↩ planView.diagnostics∾actualView.diagnostics
  rows ← empty
  {𝕊:
    completedPlanIds ← (0<≠¨actualFacts.transactions.plan_id)/actualFacts.transactions.plan_id
    {𝕊 tx:
      debits ← ({𝕩.side≡"debit"}¨tx.postings)/tx.postings
      credits ← ({𝕩.side≡"credit"}¨tx.postings)/tx.postings
      binary ← (1=≠debits) ∧ 1=≠credits
      diagnostics ∾↩ (¬binary)/⟨Diagnostic ⟨
        "editor_plan_nonbinary",
        "Plan editor row requires exactly one debit and one credit Posting"
      ⟩⟩
      {𝕊:
        debit ← ⊑debits ⋄ credit ← ⊑credits
        coefficient ← debit.coefficient
        rows∾↩⟨{
          index⇐≠rows,
          date⇐tx.date_text,
          description⇐tx.description,
          from_account⇐credit.account_key,
          to_account⇐debit.account_key,
          amount⇐amountText.Format ⟨coefficient,tx.calculation_scale⟩,
          coefficient⇐coefficient,
          scale⇐tx.calculation_scale,
          currency⇐tx.domain,
          plan_id⇐tx.plan_id,
          closed⇐Contains ⟨tx.plan_id,completedPlanIds⟩,
          metadata⇐tx.metadata,
          source_start_line⇐tx.source_start_line
        }⟩
      }⍟binary @
    }¨planView.rows
  }⍟((planView.state≡"ok") ∧ actualView.state≡"ok") @
  ok ← 0=≠diagnostics
  {state⇐ok⊑"error"‿"ok",rows⇐ok/rows,diagnostics⇐diagnostics}
}

Load ← {𝕊 base:
  registryResult ← registryBuilder.Build io.ReadLines "config/currencies.tsv"
  result ← {state⇐"error",rows⇐empty,diagnostics⇐⟨Diagnostic ⟨registryResult.code,registryResult.message⟩⟩}
  {𝕊:
    plan ← planSource.Load ⟨base,registryResult.registry⟩
    actual ← actualSource.Load ⟨base,registryResult.registry⟩
    diagnostics ← plan.diagnostics∾actual.diagnostics
    result↩{state⇐"error",rows⇐empty,diagnostics⇐diagnostics}
    {𝕊:result↩Build ⟨plan.facts,actual.facts⟩}⍟((plan.state≡"ok") ∧ actual.state≡"ok") @
  }⍟(registryResult.state≡"ok") @
  result
}

{Build⇐Build,Load⇐Load}
