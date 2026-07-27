# actual_source.bqn
# Canonical native Journal resolver and shared actual-evidence helpers.
# Actual transactions have exactly one source: configured ACTUAL_JOURNAL_FILE.

config ← •Import "config.bqn"
loader ← •Import "loader.bqn"
admission ← •Import "../src/ledger/journal_complete_admission.bqn"
facts ← •Import "../src/ledger/facts.bqn"
transaction_rows ← •Import "../src/ledger/transaction_rows.bqn"
ak ← •Import "account_key.bqn"
dt ← •Import "date.bqn"
setup ← •Import "currency_setup.bqn"
AdmissionAccounts ← {𝕊 resolved: {key⇐resolved.accounts,currency⇐resolved.currencies} }
FactAccounts ← {𝕊 resolved:
  {
    key⇐resolved.accounts,currency⇐resolved.currencies,role⇐resolved.roles,type⇐resolved.types,
    budget⇐resolved.budgets,budget_group⇐resolved.budget_groups,
    spend_class⇐resolved.spend_classes,kind⇐resolved.kinds,
    envelope_role⇐resolved.envelope_roles,metadata⇐resolved.raw_metadata,
    source_row⇐↕resolved.count
  }
}

Resolve ← {𝕊 base: config.LoadActualJournal base}

ResolveRelativePath ← {𝕊 base:
  selected ← Resolve base
  relPath ← selected.file
  directExists ← 0 = ⊑ •SH ⟨"test", "-f", base ∾ "/" ∾ relPath⟩
  dataSubdirExists ← 0 = ⊑ •SH ⟨"test", "-f", base ∾ "/data/" ∾ relPath⟩
  {𝕊: relPath ↩ "data/" ∾ selected.file}⍟((¬directExists) ∧ dataSubdirExists) @
  relPath
}

LoadFacts ← {𝕊 base:
  relPath ← ResolveRelativePath base
  raw ← loader.ReadRaw (base∾"/"∾relPath)
  resolved ← ak.Resolve loader.ReadLines (base∾"/accounts.tsv")
  admitted ← admission.Admit ⟨raw,AdmissionAccounts resolved,setup.registry_value⟩
  {𝕊: •Out "ERROR: native Journal source rejected" ⋄ •Exit 1}⍟(admitted.state≢"ok") @
  result ← facts.Project ⟨admitted,FactAccounts resolved⟩
  {𝕊: •Out "ERROR: native Journal facts rejected" ⋄ •Exit 1}⍟(result.state≢"ok") @
  result
}

LoadTransactionRows ← {𝕊 base:
  view ← transaction_rows.Build LoadFacts base
  {𝕊: •Out "ERROR: native Journal transaction view rejected" ⋄ •Exit 1}⍟(view.state≢"ok") @
  view.rows
}

LoadCycleEvidence ← {𝕊 base:
  relPath ← ResolveRelativePath base
  raw ← loader.ReadRaw (base∾"/"∾relPath)
  result ← {state⇐"error",complete⇐0,transactions⇐⟨⟩,declared_accounts⇐⟨⟩}
  accountsPath ← base∾"/accounts.tsv"
  accountsExist ← 0 = ⊑ •SH ⟨"test", "-f", accountsPath⟩
  {𝕊:
    resolved ← ak.Resolve loader.ReadLines accountsPath
    admitted ← admission.Admit ⟨raw,AdmissionAccounts resolved,setup.registry_value⟩
    {𝕊: result↩{state⇐"ok",complete⇐1,transactions⇐admitted.transactions,declared_accounts⇐admitted.declared_accounts}}⍟(admitted.state≡"ok") @
  }⍟accountsExist @
  {𝕊: •Out "ERROR: native Journal source rejected" ⋄ •Exit 1}⍟(result.state≢"ok") @
  result
}

DatesFromTransactions ← {𝕊 transactions: {𝕩.date}¨transactions}

# Report consumers already receive the admitted/parsed Actual transactions on
# their context. Prefer that prepared evidence; the fallback preserves focused
# mock/compatibility contexts that only carry base.
DatesFromContext ← {𝕊 ctx:
  transactions ← ({𝕊: ctx.actual_transactions}⎊{𝕊: (LoadCycleEvidence ctx.base).transactions}) @
  DatesFromTransactions transactions
}

LoadDates ← {𝕊 base: DatesFromTransactions (LoadCycleEvidence base).transactions}

IncomeDatesFromCompleteTransactions ← {𝕊 incomeAccount‿transactions:
  HasIncomeCredit ← {𝕊 tx: ∨´0∾{(𝕩.account_key≡incomeAccount)∧𝕩.normalized_coefficient<0}¨tx.postings}
  {𝕩.date}¨(HasIncomeCredit¨transactions)/transactions
}

IncomeDatesFromCycleEvidence ← {𝕊 incomeAccount‿evidence:
  dates ← ⟨⟩
  {𝕊:
    dates ↩ IncomeDatesFromCompleteTransactions ⟨incomeAccount, evidence.transactions⟩
  }⍟evidence.complete @
  {𝕊:
    HasIncomeCredit ← {𝕊 tx: ∨´0∾{(𝕩.account_key≡incomeAccount)∧𝕩.delta<0}¨tx.postings}
    matches ← (HasIncomeCredit¨evidence.transactions)/evidence.transactions
    dates ↩ {𝕩.date}¨matches
  }⍟(¬evidence.complete) @
  dates
}

IncomeDates ← {𝕊 base‿incomeAccount:
  IncomeDatesFromCycleEvidence ⟨incomeAccount, LoadCycleEvidence base⟩
}

File ← {𝕊 ctx: 𝕩.actual_source_file}
Transactions ← {𝕊 ctx: 𝕩.actual_transactions}

CompletionEvidenceFromTransactions ← {𝕊 transactions:
  Make ← {𝕊 tx:
    debitPostings ← ({𝕩.delta>0}¨tx.postings)/tx.postings
    creditPostings ← ({𝕩.delta<0}¨tx.postings)/tx.postings
    positives ← {𝕩.delta}¨debitPostings
    fromAccount ← (1=≠creditPostings)◶⟨{𝕊:""},{𝕊:(⊑creditPostings).account_key}⟩ @
    toAccount ← (1=≠debitPostings)◶⟨{𝕊:""},{𝕊:(⊑debitPostings).account_key}⟩ @
    amount ← +´0∾positives
    fallbackId ← tx.date∾tx.description∾fromAccount∾toAccount∾•Fmt amount
    pid ← fallbackId
    {𝕊: pid↩tx.plan_id}⍟(0<≠tx.plan_id) @
    {date⇐tx.date,plan_id⇐pid,amount⇐amount,from_account⇐fromAccount,to_account⇐toAccount,currency⇐"JPY"}
  }
  Make¨transactions
}

CompletionEvidenceFromCompleteTransactions ← {𝕊 transactions:
  Make ← {𝕊 tx:
    debitPostings ← ({𝕩.side≡"debit"}¨tx.postings)/tx.postings
    creditPostings ← ({𝕩.side≡"credit"}¨tx.postings)/tx.postings
    amountCoefficient ← +´0∾{𝕩.normalized_coefficient}¨debitPostings
    amount ← amountCoefficient ÷ 10⋆tx.calculation_scale
    fromAccount ← (1=≠creditPostings)◶⟨{𝕊:""},{𝕊:(⊑creditPostings).account_key}⟩ @
    toAccount ← (1=≠debitPostings)◶⟨{𝕊:""},{𝕊:(⊑debitPostings).account_key}⟩ @
    fallbackId ← tx.date∾tx.description∾fromAccount∾toAccount∾•Fmt amount
    pid ← fallbackId
    {𝕊: pid↩tx.plan_id}⍟(0<≠tx.plan_id) @
    {date⇐tx.date,plan_id⇐pid,amount⇐amount,from_account⇐fromAccount,to_account⇐toAccount,currency⇐tx.domain}
  }
  Make¨transactions
}

CompletionEvidenceFromFactRows ← {𝕊 rows:
  Make ← {𝕊 tx:
    debitPostings ← ({𝕩.side≡"debit"}¨tx.postings)/tx.postings
    creditPostings ← ({𝕩.side≡"credit"}¨tx.postings)/tx.postings
    amountCoefficient ← +´0∾{𝕩.coefficient}¨debitPostings
    amount ← amountCoefficient ÷ 10⋆tx.calculation_scale
    fromAccount ← (1=≠creditPostings)◶⟨{𝕊:""},{𝕊:(⊑creditPostings).account_key}⟩ @
    toAccount ← (1=≠debitPostings)◶⟨{𝕊:""},{𝕊:(⊑debitPostings).account_key}⟩ @
    fallbackId ← tx.date_text∾tx.description∾fromAccount∾toAccount∾•Fmt amount
    pid ← fallbackId
    {𝕊: pid↩tx.plan_id}⍟(0<≠tx.plan_id) @
    {date⇐tx.date_text,plan_id⇐pid,amount⇐amount,from_account⇐fromAccount,to_account⇐toAccount,currency⇐tx.domain}
  }
  Make¨rows
}

CompletionEvidence ← {𝕊 base: CompletionEvidenceFromFactRows LoadTransactionRows base}

CompletionEvidenceFromContext ← {𝕊 ctx:
  complete ← ({𝕊: ctx.actual_transactions_complete}⎊{𝕊:0}) @
  transactionsPresent ← 1
  transactions ← ({𝕊: ctx.actual_transactions}⎊{𝕊: transactionsPresent↩0 ⋄ ⟨⟩}) @
  result ← ⟨⟩
  {𝕊: result↩CompletionEvidenceFromCompleteTransactions transactions}⍟(transactionsPresent ∧ complete) @
  {𝕊: result↩CompletionEvidenceFromTransactions transactions}⍟(transactionsPresent ∧ ¬complete) @
  {𝕊: result↩CompletionEvidence ctx.base}⍟(¬transactionsPresent) @
  result
}

PlanIdsInCycleFromEvidence ← {𝕊 evidence‿cy:
  InCycle ← {𝕊 ev:
    cyOk ← (cy.start ≢ "unavailable") ∧ (cy.end_exclusive ≢ "unavailable") ∧ (dt.IsValidDateText cy.start) ∧ (dt.IsValidDateText cy.end_exclusive)
    ok ← cyOk ∧ dt.IsValidDateText ev.date
    inside ← 0
    {𝕊: dn←dt.DaysFromEpoch ev.date ⋄ inside↩(dn≥dt.DaysFromEpoch cy.start)∧dn<dt.DaysFromEpoch cy.end_exclusive}⍟ok @
    inside
  }
  {𝕩.plan_id}¨(InCycle¨evidence)/evidence
}

PlanIdsInCycleFromContext ← {𝕊 ctx:
  PlanIdsInCycleFromEvidence ⟨CompletionEvidenceFromContext ctx, ctx.cy⟩
}

{
  Resolve⇐Resolve,
  ResolveRelativePath⇐ResolveRelativePath,
  LoadTransactionRows⇐LoadTransactionRows,
  LoadCycleEvidence⇐LoadCycleEvidence,
  DatesFromContext⇐DatesFromContext,
  LoadDates⇐LoadDates,
  IncomeDates⇐IncomeDates,
  IncomeDatesFromCycleEvidence⇐IncomeDatesFromCycleEvidence,
  File⇐File,
  Transactions⇐Transactions,
  CompletionEvidence⇐CompletionEvidence,
  CompletionEvidenceFromContext⇐CompletionEvidenceFromContext,
  PlanIdsInCycleFromContext⇐PlanIdsInCycleFromContext
}
