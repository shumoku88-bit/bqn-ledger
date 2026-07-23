# actual_source.bqn
# Canonical native Journal resolver and shared actual-evidence helpers.
# Actual transactions have exactly one source: configured ACTUAL_JOURNAL_FILE.

config ← •Import "config.bqn"
loader ← •Import "loader.bqn"
parser ← •Import "journal_profile_stage1.bqn"
proj ← •Import "projection.bqn"
cube ← •Import "cube.bqn"

Resolve ← {𝕊 base: config.LoadActualJournal base}

LoadTransactions ← {𝕊 base:
  selected ← Resolve base
  raw ← loader.ReadRaw (base∾"/"∾selected.file)
  parsed ← parser.ParseWithProfile ⟨raw,"historical_external_plan"⟩
  {𝕊: •Out "ERROR: native Journal source rejected" ⋄ •Exit 1}⍟(parsed.state≢"ok") @
  parsed.transactions
}

LoadDates ← {𝕊 base: {𝕩.date}¨LoadTransactions base}

IncomeDates ← {𝕊 base‿incomeAccount:
  txs ← LoadTransactions base
  HasIncomeCredit ← {𝕊 tx: ∨´0∾{(𝕩.account_key≡incomeAccount)∧𝕩.delta<0}¨tx.postings}
  {𝕩.date}¨(HasIncomeCredit¨txs)/txs
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
    ok ← proj.IsValidDateText ev.date
    inside ← 0
    {𝕊: dn←proj.DaysFromEpoch ev.date ⋄ inside↩(dn≥proj.DaysFromEpoch cy.start)∧dn<proj.DaysFromEpoch cy.end_exclusive}⍟ok @
    inside
  }
  {𝕩.plan_id}¨(InCycle¨evidence)/evidence
}

{Resolve⇐Resolve,LoadTransactions⇐LoadTransactions,LoadDates⇐LoadDates,IncomeDates⇐IncomeDates,File⇐File,Transactions⇐Transactions,Rows⇐Rows,CompletionEvidence⇐CompletionEvidence,PlanIdsInCycle⇐PlanIdsInCycle}
