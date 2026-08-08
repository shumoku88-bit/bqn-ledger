# Pure resolution of admitted report.toml query policy.
#
# `latest` is supplied by the application boundary. `beginning` is derived from
# admitted Actual transaction dates through the resolved end date. No clock,
# source path, renderer, or manifest shape lives here.

dates ← •Import "../ledger/date_ordinal.bqn"
empty ← ⟨⟩

Diagnostic ← {𝕊 code‿message:{severity⇐"error",stage⇐"application_report_policy_resolution",code⇐code,message⇐message}}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}

ResolveEnd ← {𝕊 reference‿latest:
  result ← reference
  {𝕊:result↩latest}⍟(reference≡"latest") @
  result
}
BeginningThrough ← {𝕊 finish‿journalDates:
  finishOrdinal ← dates.Ordinal finish
  eligible ← (dates.Ordinal¨journalDates)≤finishOrdinal
  result ← finish
  {𝕊:result↩dates.FromOrdinal ⌊´dates.Ordinal¨eligible/journalDates}⍟(∨´0∾eligible) @
  result
}
ResolveStart ← {𝕊 reference‿finish‿journalDates:
  result ← reference
  {𝕊:result↩BeginningThrough ⟨finish,journalDates⟩}⍟(reference≡"beginning") @
  result
}

Resolve ← {𝕊 policy‿latest‿journalDates:
  diagnostics ← empty
  diagnostics∾↩AddIf ⟨policy.state≢"ok",Diagnostic ⟨"report_policy_not_ok","Report policy must be admitted before resolution"⟩⟩
  diagnostics∾↩AddIf ⟨¬dates.IsValid latest,Diagnostic ⟨"report_latest_invalid","latest Report date must be strict Gregorian text"⟩⟩
  diagnostics∾↩∾{𝕊 value:AddIf ⟨¬dates.IsValid value,Diagnostic ⟨"report_journal_date_invalid","Actual journal dates must be strict Gregorian text"⟩⟩}¨journalDates

  trialAsOf ← "" ⋄ balanceAsOf ← ""
  profitFrom ← "" ⋄ profitThrough ← ""
  dailyFrom ← "" ⋄ dailyThrough ← ""
  monthlyFrom ← "" ⋄ monthlyThrough ← ""
  recentThrough ← "" ⋄ recentCount ← 0

  CheckRange ← {𝕊 name‿start‿finish:
    diagnostics∾↩AddIf ⟨(dates.Ordinal start)>dates.Ordinal finish,Diagnostic ⟨"report_range_invalid",name∾" start must not be after its through date"⟩⟩
  }
  {𝕊:
    trialAsOf↩ResolveEnd ⟨policy.reports.trial_balance.as_of,latest⟩
    balanceAsOf↩ResolveEnd ⟨policy.reports.balance_sheet.as_of,latest⟩

    profitThrough↩ResolveEnd ⟨policy.reports.profit_and_loss.through,latest⟩
    profitFrom↩ResolveStart ⟨policy.reports.profit_and_loss.from,profitThrough,journalDates⟩
    CheckRange ⟨"profit-and-loss",profitFrom,profitThrough⟩

    dailyThrough↩ResolveEnd ⟨policy.reports.daily_flow.through,latest⟩
    dailyFrom↩ResolveStart ⟨policy.reports.daily_flow.from,dailyThrough,journalDates⟩
    CheckRange ⟨"daily-flow",dailyFrom,dailyThrough⟩

    monthlyThrough↩ResolveEnd ⟨policy.reports.monthly_accounts.through,latest⟩
    monthlyFrom↩ResolveStart ⟨policy.reports.monthly_accounts.from,monthlyThrough,journalDates⟩
    CheckRange ⟨"monthly-accounts",monthlyFrom,monthlyThrough⟩

    recentThrough↩ResolveEnd ⟨policy.reports.recent_transactions.through,latest⟩
    recentCount↩policy.reports.recent_transactions.count
  }⍟(0=≠diagnostics) @

  {
    state⇐(0=≠diagnostics)⊑"error"‿"ok",
    trial_balance⇐{as_of⇐trialAsOf},
    balance_sheet⇐{as_of⇐balanceAsOf},
    profit_and_loss⇐{from⇐profitFrom,through⇐profitThrough},
    daily_flow⇐{from⇐dailyFrom,through⇐dailyThrough,max_date_columns⇐policy.presentation.daily_flow_max_date_columns},
    monthly_accounts⇐{from⇐monthlyFrom,through⇐monthlyThrough},
    recent_transactions⇐{through⇐recentThrough,count⇐recentCount},
    presentation⇐policy.presentation,
    diagnostics⇐diagnostics
  }
}

{Resolve⇐Resolve}
