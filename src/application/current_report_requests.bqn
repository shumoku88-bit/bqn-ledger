# Pure construction of the current report request set from typed Report policy
# plus canonical accounting evidence. No manifest rows or physical source names.

request ← •Import "../report/request.bqn"
route ← •Import "report_route.bqn"
dates ← •Import "../ledger/date_ordinal.bqn"
empty ← ⟨⟩

Diagnostic ← {𝕊 code‿message:{severity⇐"error",stage⇐"application_current_report_requests",code⇐code,message⇐message}}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}
Contains ← {𝕊 item‿items:∨´0∾item⊸≡¨items}
NextMonthExclusive ← {𝕊 dateText:
  y‿m‿d ← dates.Parts dateText
  nextY ← y+(m=12) ⋄ nextM ← (m=12)⊑⟨m+1,1⟩
  7↑dates.FromParts ⟨nextY,nextM,1⟩
}
DailyObservation ← {𝕊 facts‿domain‿start‿through:
  domainMatches ← (domain⊸≡¨facts.domains.code)/facts.domains.index
  result ← start
  {𝕊:
    domainIndex ← ⊑domainMatches
    startOrdinal ← dates.Ordinal start ⋄ throughOrdinal ← dates.Ordinal through
    domainMask ← facts.transactions.domain_index=domainIndex
    startMask ← facts.transactions.date_ordinal≥startOrdinal
    throughMask ← facts.transactions.date_ordinal≤throughOrdinal
    mask ← domainMask ∧ startMask ∧ throughMask
    ordinals ← mask/facts.transactions.date_ordinal
    {𝕊:result↩dates.FromOrdinal⌈´ordinals}⍟(0<≠ordinals) @
  }⍟(1=≠domainMatches) @
  result
}

Build ← {𝕊 domain‿surface‿reportPlan‿actualFacts‿observation‿currentCycle‿baselineCycle:
  diagnostics ← empty
  selection ← request.Validate ⟨"all",surface⟩
  diagnostics∾↩selection.diagnostics
  diagnostics∾↩AddIf ⟨reportPlan.state≢"ok",Diagnostic ⟨"report_plan_not_ok","Resolved Report policy must be ok"⟩⟩
  diagnostics∾↩AddIf ⟨¬dates.IsValid observation,Diagnostic ⟨"current_observation_invalid","Current accounting observation must be strict Gregorian text"⟩⟩
  diagnostics∾↩AddIf ⟨currentCycle.state≢"ok",Diagnostic ⟨"current_cycle_not_ok","Current Cycle must be resolved"⟩⟩
  diagnostics∾↩AddIf ⟨baselineCycle.state≢"ok",Diagnostic ⟨"baseline_cycle_not_ok","Baseline Cycle must be resolved"⟩⟩
  diagnostics∾↩AddIf ⟨1≠+´domain⊸≡¨actualFacts.domains.code,Diagnostic ⟨"report_domain_invalid","Current Report domain must identify exactly one admitted domain"⟩⟩

  baselineObservation ← ""
  {𝕊:
    observationOrdinal ← dates.Ordinal observation
    inCurrent ← (currentCycle.start_ordinal≤observationOrdinal) ∧ observationOrdinal<currentCycle.end_exclusive_ordinal
    diagnostics∾↩AddIf ⟨¬inCurrent,Diagnostic ⟨"current_observation_outside_cycle","Current accounting observation must occur inside current Cycle"⟩⟩
    {𝕊:
      elapsed ← observationOrdinal-currentCycle.start_ordinal
      baselineOrdinal ← baselineCycle.start_ordinal+elapsed
      fits ← baselineOrdinal<baselineCycle.end_exclusive_ordinal
      diagnostics∾↩AddIf ⟨¬fits,Diagnostic ⟨"aligned_baseline_unavailable","Previous Cycle cannot represent current elapsed observation"⟩⟩
      {𝕊:baselineObservation↩dates.FromOrdinal baselineOrdinal}⍟fits @
    }⍟inCurrent @
  }⍟((0=≠diagnostics) ∧ dates.IsValid observation) @

  rows ← empty
  {𝕊:
    p ← reportPlan
    dailyObservation ← DailyObservation ⟨actualFacts,domain,p.daily_flow.from,p.daily_flow.through⟩
    candidates ← ⟨
      {key⇐"envelopes",arguments⇐⟨domain,currentCycle.start,currentCycle.end_exclusive,observation⟩},
      {key⇐"balances",arguments⇐⟨domain,p.trial_balance.as_of⟩},
      {key⇐"balance-sheet",arguments⇐⟨domain,p.balance_sheet.as_of⟩},
      {key⇐"profit-and-loss",arguments⇐⟨domain,p.profit_and_loss.from,dates.AddDays ⟨p.profit_and_loss.through,1⟩⟩},
      {key⇐"recent",arguments⇐⟨p.recent_transactions.through,•Fmt p.recent_transactions.count⟩},
      {key⇐"planned",arguments⇐⟨observation⟩},
      {key⇐"cycle-accounts",arguments⇐⟨domain,observation⟩},
      {key⇐"cycle-comparison",arguments⇐⟨domain,observation,baselineObservation,"aligned_elapsed"⟩},
      {key⇐"monthly-accounts",arguments⇐⟨domain,7↑p.monthly_accounts.from,NextMonthExclusive p.monthly_accounts.through⟩},
      {key⇐"daily-flow",arguments⇐⟨domain,p.daily_flow.from,dates.AddDays ⟨p.daily_flow.through,1⟩,dailyObservation⟩},
      {key⇐"daily-target",arguments⇐⟨domain,observation,currentCycle.end_exclusive⟩},
      {key⇐"issues",arguments⇐empty}
    ⟩
    selectedKeys ← selection.section_keys
    selectedCandidates ← ({Contains ⟨𝕩.key,selectedKeys⟩}¨candidates)/candidates
    admissions ← {𝕊 candidate:route.Admit ⟨candidate.key,surface,candidate.arguments⟩}¨selectedCandidates
    diagnostics∾↩∾{𝕩.diagnostics}¨admissions
    {𝕊:
      rows↩{𝕊 admitted:{key⇐admitted.key,surface⇐admitted.surface,arguments⇐admitted.coordinates}}¨admissions
    }⍟(0=≠diagnostics) @
  }⍟(0=≠diagnostics) @

  {state⇐(0=≠diagnostics)⊑"error"‿"ok",domain⇐domain,surface⇐surface,rows⇐rows,diagnostics⇐diagnostics}
}

{Build⇐Build,DailyObservation⇐DailyObservation}
