# Read-only Plan projection for editor/list consumers.
#
# Canonical Plan and Actual Facts remain the source owners. This projection narrows
# one Plan transaction to the historical editor row shape only when it has exactly
# one debit and one credit. Multi-posting Plan transactions remain valid canonical
# source evidence and are rejected only at this narrower editor boundary.
# One editor observation admits Accounts once, then interprets both Plan and Actual
# against that same Account Registry.

io ← •Import "source_io.bqn"
registryBuilder ← •Import "../ledger/currency_registry.bqn"
accountSource ← •Import "account_source_adapter.bqn"
planSource ← •Import "plan_source_adapter.bqn"
actualSource ← •Import "actual_source_adapter.bqn"
transactionRows ← •Import "../ledger/transaction_rows.bqn"
amountText ← •Import "../ledger/amount_text.bqn"
empty ← ⟨⟩

Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}
Diagnostic ← {𝕊 codeText‿messageText:
  {severity⇐"error",stage⇐"application_editor_plan_rows",code⇐codeText,message⇐messageText}
}
Failure ← {𝕊 diagnostics:{state⇐"error",rows⇐empty,diagnostics⇐diagnostics}}

Build ← {𝕊 planFacts‿actualFacts:
  planView ← transactionRows.Build planFacts
  completedPlanIds ← (0<≠¨actualFacts.transactions.plan_id)/actualFacts.transactions.plan_id
  Project ← {𝕊 tx:
    debits ← ({𝕩.side≡"debit"}¨tx.postings)/tx.postings
    credits ← ({𝕩.side≡"credit"}¨tx.postings)/tx.postings
    binary ← (1=≠debits) ∧ 1=≠credits
    binary◶⟨
      {𝕊:{
        rows⇐empty,
        diagnostics⇐⟨Diagnostic ⟨
          "editor_plan_nonbinary",
          "Plan editor row requires exactly one debit and one credit Posting"
        ⟩⟩
      }},
      {𝕊:
        debit ← ⊑debits ⋄ credit ← ⊑credits ⋄ coefficient ← debit.coefficient
        {rows⇐⟨{
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
        }⟩,diagnostics⇐empty}
      }
    ⟩ @
  }
  projected ← Project¨planView.rows
  diagnostics ← planView.diagnostics∾actualFacts.diagnostics∾∾{𝕩.diagnostics}¨projected
  rows ← ∾{𝕩.rows}¨projected
  ok ← 0=≠diagnostics
  {state⇐ok⊑"error"‿"ok",rows⇐ok/rows,diagnostics⇐diagnostics}
}

Load ← {𝕊 base:
  registryResult ← registryBuilder.Build io.ReadLines "config/currencies.tsv"
  (registryResult.state≡"ok")◶⟨
    {𝕊:Failure ⟨Diagnostic ⟨registryResult.code,registryResult.message⟩⟩},
    {𝕊:
      accounts ← accountSource.Load base
      (accounts.state≡"ok")◶⟨
        {𝕊:Failure accounts.diagnostics},
        {𝕊:
          plan ← planSource.LoadFromAccounts ⟨base,accounts.accounts,registryResult.registry⟩
          actual ← actualSource.LoadFromAccounts ⟨base,accounts.accounts,registryResult.registry⟩
          diagnostics ← plan.diagnostics∾actual.diagnostics
          ((plan.state≡"ok") ∧ actual.state≡"ok")◶⟨
            {𝕊:Failure diagnostics},
            {𝕊:Build ⟨plan.facts,actual.facts⟩}
          ⟩ @
        }
      ⟩ @
    }
  ⟩ @
}

{Load⇐Load}
