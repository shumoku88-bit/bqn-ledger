# actual_source.bqn
# Canonical native Journal resolver and shared actual-evidence helpers.
# Actual transactions have exactly one source: configured ACTUAL_JOURNAL_FILE.

config ← •Import "config.bqn"
loader ← •Import "loader.bqn"
parser ← •Import "journal_profile_stage1.bqn"
admission ← •Import "journal_complete_source_admission.bqn"
ak ← •Import "account_key.bqn"
dt ← •Import "date.bqn"
cube ← •Import "cube.bqn"

Resolve ← {𝕊 base: config.LoadActualJournal base}

ResolveRelativePath ← {𝕊 base:
  selected ← Resolve base
  relPath ← selected.file
  directExists ← 0 = ⊑ •SH ⟨"test", "-f", base ∾ "/" ∾ relPath⟩
  dataSubdirExists ← 0 = ⊑ •SH ⟨"test", "-f", base ∾ "/data/" ∾ relPath⟩
  {𝕊: relPath ↩ "data/" ∾ selected.file}⍟((¬directExists) ∧ dataSubdirExists) @
  relPath
}

LoadTransactions ← {𝕊 base:
  relPath ← ResolveRelativePath base
  raw ← loader.ReadRaw (base∾"/"∾relPath)
  parsed ← parser.ParseWithProfile ⟨raw,"historical_external_plan"⟩
  {𝕊: •Out "ERROR: native Journal source rejected" ⋄ •Exit 1}⍟(parsed.state≢"ok") @
  parsed.transactions
}

LoadCompleteTransactions ← {𝕊 base:
  relPath ← ResolveRelativePath base
  raw ← loader.ReadRaw (base∾"/"∾relPath)
  resolved ← ak.Resolve loader.ReadLines (base∾"/accounts.tsv")
  admitted ← admission.Admit ⟨raw, resolved⟩
  {𝕊: •Out "ERROR: native Journal source rejected" ⋄ •Exit 1}⍟(admitted.state≢"ok") @
  admitted.transactions
}

LoadCycleTransactions ← {𝕊 base:
  relPath ← ResolveRelativePath base
  raw ← loader.ReadRaw (base∾"/"∾relPath)
  result ← {state⇐"error", complete⇐0, transactions⇐⟨⟩}
  accountsPath ← base∾"/accounts.tsv"
  accountsExist ← 0 = ⊑ •SH ⟨"test", "-f", accountsPath⟩
  {𝕊:
    resolved ← ak.Resolve loader.ReadLines accountsPath
    admitted ← admission.Admit ⟨raw, resolved⟩
    {𝕊: result ↩ {state⇐"ok", complete⇐1, transactions⇐admitted.transactions}}⍟(admitted.state≡"ok") @
  }⍟accountsExist @
  {𝕊:
    parsed ← parser.ParseWithProfile ⟨raw,"historical_external_plan"⟩
    {𝕊: result ↩ {state⇐"ok", complete⇐0, transactions⇐parsed.transactions}}⍟(parsed.state≡"ok") @
  }⍟(result.state≢"ok") @
  {𝕊: •Out "ERROR: native Journal source rejected" ⋄ •Exit 1}⍟(result.state≢"ok") @
  result
}

LoadDates ← {𝕊 base: {𝕩.date}¨(LoadCycleTransactions base).transactions}

IncomeDates ← {𝕊 base‿incomeAccount:
  loaded ← LoadCycleTransactions base
  matches ← ⟨⟩
  {𝕊:
    HasIncomeCredit ← {𝕊 tx: ∨´0∾{(𝕩.account_key≡incomeAccount)∧𝕩.normalized_coefficient<0}¨tx.postings}
    matches ↩ (HasIncomeCredit¨loaded.transactions)/loaded.transactions
  }⍟loaded.complete @
  {𝕊:
    HasIncomeCredit ← {𝕊 tx: ∨´0∾{(𝕩.account_key≡incomeAccount)∧𝕩.delta<0}¨tx.postings}
    matches ↩ (HasIncomeCredit¨loaded.transactions)/loaded.transactions
  }⍟(¬loaded.complete) @
  {𝕩.date}¨matches
}

File ← {𝕊 ctx: 𝕩.actual_source_file}
Transactions ← {𝕊 ctx: 𝕩.actual_transactions}

Rows ← {𝕊 ctx:
  (cube.layer_actual={𝕩.layer_index}¨ctx.posting_rows) / ctx.posting_rows
}

CompletionEvidence ← {𝕊 base:
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
  Make¨LoadTransactions base
}

PlanIdsInCycle ← {𝕊 base‿cy:
  evidence ← CompletionEvidence base
  InCycle ← {𝕊 ev:
    ok ← dt.IsValidDateText ev.date
    inside ← 0
    {𝕊: dn←dt.DaysFromEpoch ev.date ⋄ inside↩(dn≥dt.DaysFromEpoch cy.start)∧dn<dt.DaysFromEpoch cy.end_exclusive}⍟ok @
    inside
  }
  {𝕩.plan_id}¨(InCycle¨evidence)/evidence
}

{Resolve⇐Resolve,ResolveRelativePath⇐ResolveRelativePath,LoadTransactions⇐LoadTransactions,LoadCompleteTransactions⇐LoadCompleteTransactions,LoadDates⇐LoadDates,IncomeDates⇐IncomeDates,File⇐File,Transactions⇐Transactions,Rows⇐Rows,CompletionEvidence⇐CompletionEvidence,PlanIdsInCycle⇐PlanIdsInCycle}
