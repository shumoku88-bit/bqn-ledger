# Pure resolution of admitted report.toml query policy.
#
# `latest` is supplied by the application boundary. `beginning` is derived from
# admitted Actual transaction dates through the resolved end date. No clock,
# source path, renderer, or manifest shape lives here.

dates ← •Import "../ledger/date_ordinal.bqn"
empty ← ⟨⟩

Diagnostic ← {𝕊 code‿message:{severity⇐"error",stage⇐"application_report_policy_resolution",code⇐code,message⇐message}}
AddIf ← {𝕊 invalid‿diagnostic:invalid/⟨diagnostic⟩}

ResolveEnd ← {𝕊 reference‿latest:
  (reference≡"latest")◶⟨{𝕊:reference},{𝕊:latest}⟩ @
}
BeginningThrough ← {𝕊 finish‿journalDates:
  finishOrdinal ← dates.Ordinal finish
  ordinals ← dates.Ordinal¨journalDates
  eligible ← ordinals≤finishOrdinal
  (∨´0∾eligible)◶⟨
    {𝕊:finish},
    {𝕊:dates.FromOrdinal ⌊´eligible/ordinals}
  ⟩ @
}
ResolveStart ← {𝕊 reference‿finish‿journalDates:
  (reference≡"beginning")◶⟨
    {𝕊:reference},
    {𝕊:BeginningThrough ⟨finish,journalDates⟩}
  ⟩ @
}

InputDiagnostics ← {𝕊 policy‿latest‿journalDates:
  policyDiagnostics ← AddIf ⟨policy.state≢"ok",Diagnostic ⟨"report_policy_not_ok","Report policy must be admitted before resolution"⟩⟩
  latestDiagnostics ← AddIf ⟨¬dates.IsValid latest,Diagnostic ⟨"report_latest_invalid","latest Report date must be strict Gregorian text"⟩⟩
  journalCells ← {𝕊 value:AddIf ⟨¬dates.IsValid value,Diagnostic ⟨"report_journal_date_invalid","Actual journal dates must be strict Gregorian text"⟩⟩}¨journalDates
  journalDiagnostics ← ∾⟨empty⟩∾journalCells
  policyDiagnostics∾latestDiagnostics∾journalDiagnostics
}
RangeDiagnostics ← {𝕊 rows:
  cells ← {𝕊 row:
    name‿start‿finish ← row
    AddIf ⟨(dates.Ordinal start)>dates.Ordinal finish,Diagnostic ⟨"report_range_invalid",name∾" start must not be after its through date"⟩⟩
  }¨rows
  ∾⟨empty⟩∾cells
}
FailureResult ← {𝕊 policy‿diagnosticsValue:
  {
    state⇐"error",
    trial_balance⇐{as_of⇐""},
    balance_sheet⇐{as_of⇐""},
    profit_and_loss⇐{from⇐"",through⇐""},
    daily_flow⇐{from⇐"",through⇐"",max_date_columns⇐policy.presentation.daily_flow_max_date_columns},
    monthly_accounts⇐{from⇐"",through⇐""},
    recent_transactions⇐{through⇐"",count⇐0},
    presentation⇐policy.presentation,
    diagnostics⇐diagnosticsValue
  }
}
ResolveValid ← {𝕊 policy‿latest‿journalDates:
  trialAsOf ← ResolveEnd ⟨policy.reports.trial_balance.as_of,latest⟩
  balanceAsOf ← ResolveEnd ⟨policy.reports.balance_sheet.as_of,latest⟩

  profitThrough ← ResolveEnd ⟨policy.reports.profit_and_loss.through,latest⟩
  profitFrom ← ResolveStart ⟨policy.reports.profit_and_loss.from,profitThrough,journalDates⟩

  dailyThrough ← ResolveEnd ⟨policy.reports.daily_flow.through,latest⟩
  dailyFrom ← ResolveStart ⟨policy.reports.daily_flow.from,dailyThrough,journalDates⟩

  monthlyThrough ← ResolveEnd ⟨policy.reports.monthly_accounts.through,latest⟩
  monthlyFrom ← ResolveStart ⟨policy.reports.monthly_accounts.from,monthlyThrough,journalDates⟩

  recentThrough ← ResolveEnd ⟨policy.reports.recent_transactions.through,latest⟩
  recentCount ← policy.reports.recent_transactions.count

  diagnostics ← RangeDiagnostics ⟨
    ⟨"profit-and-loss",profitFrom,profitThrough⟩,
    ⟨"daily-flow",dailyFrom,dailyThrough⟩,
    ⟨"monthly-accounts",monthlyFrom,monthlyThrough⟩
  ⟩
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

Resolve ← {𝕊 policy‿latest‿journalDates:
  diagnostics ← InputDiagnostics ⟨policy,latest,journalDates⟩
  (0=≠diagnostics)◶⟨
    {𝕊:FailureResult ⟨policy,diagnostics⟩},
    {𝕊:ResolveValid ⟨policy,latest,journalDates⟩}
  ⟩ @
}

{Resolve⇐Resolve}
