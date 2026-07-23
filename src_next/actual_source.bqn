# actual_source.bqn
# Explicit actual-source routing and shared evidence helpers.
# ACTUAL_SOURCE selects exactly one source; there is no fallback or source merge.

config ← •Import "config.bqn"
loader ← •Import "loader.bqn"
parser ← •Import "journal_profile_stage1.bqn"
proj ← •Import "projection.bqn"
cube ← •Import "cube.bqn"

ModeAndFile ← {𝕊 base:
  route ← config.LoadActualSource base
  mode ← route.mode
  file ← (mode≡"journal")⊑⟨"journal.tsv",route.file⟩
  valid ← ∨´ mode⊸≡¨⟨"tsv","journal"⟩
  {𝕊: •Out "CONFIG ERROR: ACTUAL_SOURCE must be tsv or journal" ⋄ •Exit 1}⍟(¬valid) @
  {mode⇐mode,file⇐file}
}

LoadTransactions ← {𝕊 base:
  selected ← ModeAndFile base
  transactions ← ⟨⟩
  {𝕊:
    raw ← loader.ReadRaw (base∾"/"∾selected.file)
    parsed ← parser.ParseWithProfile ⟨raw,"historical_external_plan"⟩
    {𝕊: •Out "ERROR: native Journal source rejected" ⋄ •Exit 1}⍟(parsed.state≢"ok") @
    transactions ↩ parsed.transactions
  }⍟(selected.mode≡"journal") @
  transactions
}

LoadDates ← {𝕊 base:
  selected ← ModeAndFile base
  dates ← ⟨⟩
  {𝕊:
    lines ← loader.ReadLinesOptional (base∾"/"∾selected.file)
    dates ↩ {⊑ loader.SplitTsvKeepEmpty 𝕩}¨lines
  }⍟(selected.mode≡"tsv") @
  {𝕊: dates ↩ {𝕩.date}¨LoadTransactions base}⍟(selected.mode≡"journal") @
  dates
}

IncomeDates ← {𝕊 base‿incomeAccount:
  selected ← ModeAndFile base
  dates ← ⟨⟩
  {𝕊:
    lines ← loader.ReadLinesOptional (base∾"/"∾selected.file)
    IsIncome ← {𝕊 line: f←loader.SplitTsvKeepEmpty line ⋄ (5≤≠f)∧(2⊑f)≡incomeAccount}
    dates ↩ {⊑loader.SplitTsvKeepEmpty 𝕩}¨(IsIncome¨lines)/lines
  }⍟(selected.mode≡"tsv") @
  {𝕊:
    txs ← LoadTransactions base
    HasIncomeCredit ← {𝕊 tx: ∨´0∾{(𝕩.account_key≡incomeAccount)∧𝕩.delta<0}¨tx.postings}
    dates ↩ {𝕩.date}¨(HasIncomeCredit¨txs)/txs
  }⍟(selected.mode≡"journal") @
  dates
}

File ← {𝕊 ctx: ({𝕊:𝕩.actual_source_file}⎊{𝕊:𝕩⋄"journal.tsv"}) ctx}
Mode ← {𝕊 ctx: ({𝕊:𝕩.actual_source_mode}⎊{𝕊:𝕩⋄"tsv"}) ctx}
Transactions ← {𝕊 ctx: ({𝕊:𝕩.actual_transactions}⎊{𝕊:𝕩⋄⟨⟩}) ctx}

Rows ← {𝕊 ctx:
  file ← File ctx
  (({𝕩.source_file≡file}¨ctx.posting_rows) ∧ (cube.layer_actual={𝕩.layer_index}¨ctx.posting_rows)) / ctx.posting_rows
}

CompletionEvidence ← {𝕊 base:
  selected ← ModeAndFile base
  evidence ← ⟨⟩
  {𝕊:
    lines ← loader.ReadLinesOptional (base∾"/"∾selected.file)
    Parse ← {𝕊 line:
      f ← loader.SplitTsvKeepEmpty line
      meta ← 5↓f
      hits ← ({"plan_id="≡8↑𝕩}¨meta)/meta
      fallbackId ← ∾5↑f
      pid ← (0<≠hits)◶⟨{𝕊:fallbackId},{𝕊: val←8↓⊑hits ⋄ (0<≠val) ? val ; fallbackId}⟩ @
      amountText ← proj.FieldOrEmpty ⟨f,4⟩
      amount ← ({𝕊:•BQN 𝕩}⎊{𝕊:𝕩⋄0}) amountText
      currencyHits ← ({"currency="≡9↑𝕩}¨meta)/meta
      currency ← (1=≠currencyHits)◶⟨{𝕊:"JPY"},{𝕊:9↓⊑currencyHits}⟩ @
      {date⇐proj.FieldOrEmpty ⟨f,0⟩,plan_id⇐pid,amount⇐amount,from_account⇐proj.FieldOrEmpty ⟨f,2⟩,to_account⇐proj.FieldOrEmpty ⟨f,3⟩,currency⇐currency}
    }
    evidence ↩ Parse¨lines
  }⍟(selected.mode≡"tsv") @
  {𝕊:
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
    evidence ↩ Make¨LoadTransactions base
  }⍟(selected.mode≡"journal") @
  evidence
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

{ModeAndFile⇐ModeAndFile,LoadTransactions⇐LoadTransactions,LoadDates⇐LoadDates,IncomeDates⇐IncomeDates,File⇐File,Mode⇐Mode,Transactions⇐Transactions,Rows⇐Rows,CompletionEvidence⇐CompletionEvidence,PlanIdsInCycle⇐PlanIdsInCycle}
