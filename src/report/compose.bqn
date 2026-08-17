# Pure purpose-specific one-result composition. No I/O, clock, CLI, or all-report record.

request ← •Import "request.bqn"
dates ← •Import "../ledger/date_ordinal.bqn"
issueAdmission ← •Import "../ledger/issue_admission.bqn"
accountBalance ← •Import "../accounting/account_balance.bqn"
balanceSheetAccounting ← •Import "../accounting/balance_sheet.bqn"
profitLossAccounting ← •Import "../accounting/profit_and_loss.bqn"
recentTransactions ← •Import "../accounting/recent_transactions.bqn"
cycleAccountPeriod ← •Import "../accounting/cycle_account_period.bqn"
comparisonAccounting ← •Import "../accounting/cycle_comparison.bqn"
monthMovement ← •Import "../accounting/month_account_movement.bqn"
dateCategoryFlow ← •Import "../accounting/date_category_flow.bqn"
envelopeBacking ← •Import "../accounting/envelope_backing.bqn"
targetAccounting ← •Import "../accounting/daily_target.bqn"
balancesSection ← •Import "../sections/account_balances.bqn"
balanceSheetSection ← •Import "../sections/balance_sheet.bqn"
profitLossSection ← •Import "../sections/profit_and_loss.bqn"
recentSection ← •Import "../sections/recent_journal.bqn"
plannedSection ← •Import "../sections/planned_payments.bqn"
cycleAccountsSection ← •Import "../sections/cycle_accounts.bqn"
cycleComparisonSection ← •Import "../sections/cycle_comparison.bqn"
monthlySection ← •Import "../sections/monthly_accounts.bqn"
dailyFlowSection ← •Import "../sections/daily_flow.bqn"
envelopeSection ← •Import "../sections/envelope_backing.bqn"
dailyTargetSection ← •Import "../sections/daily_target.bqn"
issuesSection ← •Import "../sections/issues.bqn"
empty ← ⟨⟩

Diagnostic ← {𝕊 code‿message:{severity⇐"error",stage⇐"report_composition",code⇐code,message⇐message}}
Failure ← {𝕊 keyValue‿diagnosticsValue:{state⇐"error",reason⇐"",key⇐keyValue,result⇐empty,diagnostics⇐diagnosticsValue}}
Publish ← {𝕊 keyValue‿resultValue:
  renderable ← ∨´resultValue.state⊸≡¨⟨"ok","deficit"⟩
  unavailable ← resultValue.state≡"unavailable"
  publication ← renderable + 2×unavailable
  publication◶⟨
    {𝕊:Failure ⟨keyValue,resultValue.diagnostics⟩},
    {𝕊:{state⇐"ok",reason⇐"",key⇐keyValue,result⇐resultValue,diagnostics⇐empty}},
    {𝕊:{state⇐"unavailable",reason⇐resultValue.reason,key⇐keyValue,result⇐empty,diagnostics⇐resultValue.diagnostics}}
  ⟩ @
}
ValidateSingle ← {𝕊 keyValue‿surface:
  admitted ← request.Validate ⟨keyValue,surface⟩ ⋄ diagnostics ← admitted.diagnostics
  diagnostics∾↩(keyValue≡"all")/⟨Diagnostic ⟨"single_composition_required","one-result composer does not accept all"⟩⟩
  {state⇐(0=≠diagnostics)⊑"error"‿"ok",diagnostics⇐diagnostics}
}
DateFailure ← {𝕊 keyValue:Failure ⟨keyValue,⟨Diagnostic ⟨"composition_date_invalid","composition date must be strict Gregorian text"⟩⟩⟩}
Balances ← {𝕊 facts‿domain‿observation:
  output ← DateFailure "balances"
  {𝕊:accounting←accountBalance.Build ⟨facts,domain,dates.Ordinal observation⟩ ⋄ output↩Publish ⟨"balances",balancesSection.Build ⟨accounting,observation⟩⟩}⍟(dates.IsValid observation) @
  output
}
BalanceSheet ← {𝕊 facts‿domain‿observation:
  output ← DateFailure "balance-sheet"
  {𝕊:accounting←balanceSheetAccounting.Build ⟨facts,domain,dates.Ordinal observation⟩ ⋄ output↩Publish ⟨"balance-sheet",balanceSheetSection.Build ⟨accounting,observation⟩⟩}⍟(dates.IsValid observation) @
  output
}
ProfitAndLoss ← {𝕊 facts‿domain‿start‿finish:
  output ← DateFailure "profit-and-loss" ⋄ valid ← (dates.IsValid start) ∧ dates.IsValid finish
  {𝕊:accounting←profitLossAccounting.Build ⟨facts,domain,dates.Ordinal start,dates.Ordinal finish⟩ ⋄ output↩Publish ⟨"profit-and-loss",profitLossSection.Build ⟨accounting,start,finish⟩⟩}⍟valid @
  output
}
Recent ← {𝕊 facts‿limit:Publish ⟨"recent",recentSection.Build recentTransactions.Build ⟨facts,limit⟩⟩}
RecentThrough ← {𝕊 facts‿through‿limit:
  output ← DateFailure "recent"
  {𝕊:output↩Publish ⟨"recent",recentSection.Build recentTransactions.BuildThrough ⟨facts,dates.Ordinal through,limit⟩⟩}⍟(dates.IsValid through) @
  output
}
Planned ← {𝕊 planFacts‿actualFacts‿cycle‿observation:Publish ⟨"planned",plannedSection.Build ⟨planFacts,actualFacts,cycle,observation⟩⟩}
CycleAccounts ← {𝕊 facts‿domain‿cycle‿observation:
  accounting ← cycleAccountPeriod.Build ⟨facts,domain,cycle,observation⟩ ⋄ Publish ⟨"cycle-accounts",cycleAccountsSection.Build accounting⟩
}
CycleComparison ← {𝕊 facts‿domain‿currentCycle‿currentObservation‿baselineCycle‿baselineObservation‿policy:
  current ← cycleAccountPeriod.Build ⟨facts,domain,currentCycle,currentObservation⟩
  baseline ← cycleAccountPeriod.Build ⟨facts,domain,baselineCycle,baselineObservation⟩
  Publish ⟨"cycle-comparison",cycleComparisonSection.Build comparisonAccounting.Build ⟨current,baseline,policy⟩⟩
}
MonthlyAccounts ← {𝕊 facts‿domain‿firstMonth‿lastMonthExclusive:
  Publish ⟨"monthly-accounts",monthlySection.Build monthMovement.Build ⟨facts,domain,firstMonth,lastMonthExclusive⟩⟩
}
DailyFlow ← {𝕊 facts‿envelopeHistory‿domain‿start‿finish‿observation:
  output ← DateFailure "daily-flow" ⋄ valid ← (dates.IsValid start) ∧ (dates.IsValid finish) ∧ dates.IsValid observation
  {𝕊:
    accounting ← dateCategoryFlow.Build ⟨facts,envelopeHistory,domain,"actual",dates.Ordinal start,dates.Ordinal finish⟩
    output↩Publish ⟨"daily-flow",dailyFlowSection.Build ⟨accounting,start,finish,observation⟩⟩
  }⍟valid @
  output
}
Envelopes ← {𝕊 entitlement‿envelopePolicy‿envelopeHistory‿actualFacts‿planFacts‿planRetirements‿domain‿start‿finish‿observation:
  output ← DateFailure "envelopes" ⋄ valid ← (dates.IsValid start) ∧ (dates.IsValid finish) ∧ dates.IsValid observation
  {𝕊:
    accounting ← envelopeBacking.Build ⟨entitlement,envelopePolicy,envelopeHistory,actualFacts,planFacts,planRetirements,domain,dates.Ordinal start,dates.Ordinal finish,dates.Ordinal observation⟩
    output↩Publish ⟨"envelopes",envelopeSection.Build ⟨accounting,start,finish,observation⟩⟩
  }⍟valid @
  output
}
DailyTarget ← {𝕊 observation‿target‿domain‿assetScope‿obligationScope:
  Publish ⟨"daily-target",dailyTargetSection.Build targetAccounting.Build ⟨observation,target,domain,assetScope,obligationScope⟩⟩
}
Issues ← {𝕊 lines‿registry:Publish ⟨"issues",issuesSection.Build issueAdmission.Admit ⟨lines,registry⟩⟩}

{
  ValidateSingle⇐ValidateSingle,
  Balances⇐Balances,BalanceSheet⇐BalanceSheet,ProfitAndLoss⇐ProfitAndLoss,Recent⇐Recent,RecentThrough⇐RecentThrough,Planned⇐Planned,
  CycleAccounts⇐CycleAccounts,CycleComparison⇐CycleComparison,MonthlyAccounts⇐MonthlyAccounts,DailyFlow⇐DailyFlow,
  Envelopes⇐Envelopes,DailyTarget⇐DailyTarget,Issues⇐Issues
}
