# Pure resolution of admitted report.toml query policy.
#
# `latest` is supplied by the application boundary. `beginning` is derived from
# admitted Actual transaction dates through the resolved end date. A symbolic
# current-cycle query consumes only an already-resolved Cycle window; no clock,
# source path, Cycle policy, renderer, or manifest shape lives here.

dates ← •Import "../ledger/date_ordinal.bqn"
empty ← ⟨⟩

Diagnostic ← {𝕊 code‿message:{severity⇐"error",stage⇐"application_report_policy_resolution",code⇐code,message⇐message}}
AddIf ← {𝕊 invalid‿diagnostic:invalid/⟨diagnostic⟩}
NoCurrentCycle ← {state⇐"unavailable",start⇐"",end_exclusive⇐""}

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
NeedsCurrentCycle ← {𝕊 policy:
  ∨´0∾"current-cycle-to-date"⊸≡¨⟨
    policy.reports.profit_and_loss.range_kind,
    policy.reports.daily_flow.range_kind
  ⟩
}

CurrentCycleDiagnostics ← {𝕊 policy‿latest‿currentCycle:
  diagnostics ← empty
  needs ← NeedsCurrentCycle policy
  {𝕊:
    available ← currentCycle.state≡"ok"
    diagnostics∾↩AddIf ⟨¬available,Diagnostic ⟨"report_current_cycle_context_required","current-cycle-to-date requires a resolved Household Cycle"⟩⟩
    {𝕊:
      valid ← (dates.IsValid currentCycle.start) ∧ dates.IsValid currentCycle.end_exclusive
      diagnostics∾↩AddIf ⟨¬valid,Diagnostic ⟨"report_current_cycle_context_invalid","resolved Household Cycle must contain strict Gregorian boundaries"⟩⟩
      {𝕊:
        latestOrdinal ← dates.Ordinal latest
        inside ← (dates.Ordinal currentCycle.start)≤latestOrdinal
          ∧ latestOrdinal<dates.Ordinal currentCycle.end_exclusive
        diagnostics∾↩AddIf ⟨¬inside,Diagnostic ⟨"report_current_cycle_observation_outside_period","latest Report date must occur inside the resolved current Cycle"⟩⟩
      }⍟(valid ∧ dates.IsValid latest) @
    }⍟available @
  }⍟needs @
  diagnostics
}
InputDiagnostics ← {𝕊 policy‿latest‿journalDates‿currentCycle:
  policyDiagnostics ← AddIf ⟨policy.state≢"ok",Diagnostic ⟨"report_policy_not_ok","Report policy must be admitted before resolution"⟩⟩
  latestDiagnostics ← AddIf ⟨¬dates.IsValid latest,Diagnostic ⟨"report_latest_invalid","latest Report date must be strict Gregorian text"⟩⟩
  journalCells ← {𝕊 value:AddIf ⟨¬dates.IsValid value,Diagnostic ⟨"report_journal_date_invalid","Actual journal dates must be strict Gregorian text"⟩⟩}¨journalDates
  journalDiagnostics ← ∾⟨empty⟩∾journalCells
  cycleDiagnostics ← empty
  {𝕊:cycleDiagnostics↩CurrentCycleDiagnostics ⟨policy,latest,currentCycle⟩}⍟(policy.state≡"ok") @
  policyDiagnostics∾latestDiagnostics∾journalDiagnostics∾cycleDiagnostics
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
ResolveRange ← {𝕊 spec‿latest‿journalDates‿currentCycle:
  symbolic ← spec.range_kind≡"current-cycle-to-date"
  from ← currentCycle.start ⋄ through ← latest
  {𝕊:
    through↩ResolveEnd ⟨spec.through,latest⟩
    from↩ResolveStart ⟨spec.from,through,journalDates⟩
  }⍟(¬symbolic) @
  {from⇐from,through⇐through}
}
ResolveValid ← {𝕊 policy‿latest‿journalDates‿currentCycle:
  trialAsOf ← ResolveEnd ⟨policy.reports.trial_balance.as_of,latest⟩
  balanceAsOf ← ResolveEnd ⟨policy.reports.balance_sheet.as_of,latest⟩

  profit ← ResolveRange ⟨policy.reports.profit_and_loss,latest,journalDates,currentCycle⟩
  daily ← ResolveRange ⟨policy.reports.daily_flow,latest,journalDates,currentCycle⟩

  monthlyThrough ← ResolveEnd ⟨policy.reports.monthly_accounts.through,latest⟩
  monthlyFrom ← ResolveStart ⟨policy.reports.monthly_accounts.from,monthlyThrough,journalDates⟩

  recentThrough ← ResolveEnd ⟨policy.reports.recent_transactions.through,latest⟩
  recentCount ← policy.reports.recent_transactions.count

  diagnostics ← RangeDiagnostics ⟨
    ⟨"profit-and-loss",profit.from,profit.through⟩,
    ⟨"daily-flow",daily.from,daily.through⟩,
    ⟨"monthly-accounts",monthlyFrom,monthlyThrough⟩
  ⟩
  {
    state⇐(0=≠diagnostics)⊑"error"‿"ok",
    trial_balance⇐{as_of⇐trialAsOf},
    balance_sheet⇐{as_of⇐balanceAsOf},
    profit_and_loss⇐profit,
    daily_flow⇐{from⇐daily.from,through⇐daily.through,max_date_columns⇐policy.presentation.daily_flow_max_date_columns},
    monthly_accounts⇐{from⇐monthlyFrom,through⇐monthlyThrough},
    recent_transactions⇐{through⇐recentThrough,count⇐recentCount},
    presentation⇐policy.presentation,
    diagnostics⇐diagnostics
  }
}

ResolveWithCurrentCycle ← {𝕊 policy‿latest‿journalDates‿currentCycle:
  diagnostics ← InputDiagnostics ⟨policy,latest,journalDates,currentCycle⟩
  (0=≠diagnostics)◶⟨
    {𝕊:FailureResult ⟨policy,diagnostics⟩},
    {𝕊:ResolveValid ⟨policy,latest,journalDates,currentCycle⟩}
  ⟩ @
}
Resolve ← {𝕊 policy‿latest‿journalDates:
  ResolveWithCurrentCycle ⟨policy,latest,journalDates,NoCurrentCycle⟩
}

{Resolve⇐Resolve,ResolveWithCurrentCycle⇐ResolveWithCurrentCycle,NeedsCurrentCycle⇐NeedsCurrentCycle}
