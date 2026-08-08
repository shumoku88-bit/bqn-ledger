# Strict editor Actual evidence from canonical accounts.journal + actual.journal.
# Completion evidence exists only for durable non-empty plan_id links.

sources ← •Import "report_source_adapter.bqn"
registryBuilder ← •Import "../ledger/currency_registry.bqn"
transactionRows ← •Import "../ledger/transaction_rows.bqn"
LoadTransactionRows ← {𝕊 base:
  registryResult ← registryBuilder.Build (•Import "source_io.bqn").ReadLines "config/currencies.tsv"
  {𝕊:•Out "ERROR: currency registry rejected" ⋄ •Exit 1}⍟(registryResult.state≢"ok") @
  admitted ← sources.CanonicalActual ⟨base,registryResult.registry⟩
  {𝕊:•Out "ERROR: canonical Actual source rejected" ⋄ •Exit 1}⍟(admitted.state≢"ok") @
  view ← transactionRows.Build admitted.facts
  {𝕊:•Out "ERROR: canonical Actual transaction view rejected" ⋄ •Exit 1}⍟(view.state≢"ok") @
  view.rows
}
CompletionEvidenceFromRows ← {𝕊 rows:
  linked ← ({0<≠𝕩.plan_id}¨rows)/rows
  Make ← {𝕊 tx:
    debits ← ({𝕩.side≡"debit"}¨tx.postings)/tx.postings
    credits ← ({𝕩.side≡"credit"}¨tx.postings)/tx.postings
    coefficient ← +´0∾{𝕩.coefficient}¨debits
    amount ← coefficient÷10⋆tx.calculation_scale
    fromAccount ← (1=≠credits)◶⟨{𝕊:""},{𝕊:(⊑credits).account_key}⟩ @
    toAccount ← (1=≠debits)◶⟨{𝕊:""},{𝕊:(⊑debits).account_key}⟩ @
    {
      date⇐tx.date_text,plan_id⇐tx.plan_id,amount⇐amount,
      from_account⇐fromAccount,to_account⇐toAccount,currency⇐tx.domain
    }
  }
  Make¨linked
}
CompletionEvidence ← {𝕊 base: CompletionEvidenceFromRows LoadTransactionRows base}

{
  LoadTransactionRows⇐LoadTransactionRows,
  CompletionEvidenceFromRows⇐CompletionEvidenceFromRows,
  CompletionEvidence⇐CompletionEvidence
}
