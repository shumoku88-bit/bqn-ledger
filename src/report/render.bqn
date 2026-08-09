# Pure rendering dispatch for one successfully composed retained result.

request ← •Import "request.bqn"
envelopes ← •Import "../sections/envelope_backing.bqn"
balances ← •Import "../sections/account_balances.bqn"
balanceSheet ← •Import "../sections/balance_sheet.bqn"
profitLoss ← •Import "../sections/profit_and_loss.bqn"
recent ← •Import "../sections/recent_journal.bqn"
planned ← •Import "../sections/planned_payments.bqn"
cycleAccounts ← •Import "../sections/cycle_accounts.bqn"
cycleComparison ← •Import "../sections/cycle_comparison.bqn"
monthlyAccounts ← •Import "../sections/monthly_accounts.bqn"
dailyFlow ← •Import "../sections/daily_flow.bqn"
dailyTarget ← •Import "../sections/daily_target.bqn"
issues ← •Import "../sections/issues.bqn"
empty ← ⟨⟩

Diagnostic ← {𝕊 code‿message:
  {severity⇐"error",stage⇐"report_render",code⇐code,message⇐message}
}
Failure ← {𝕊 diagnosticsValue:
  {state⇐"error",text⇐"",diagnostics⇐diagnosticsValue}
}

Render ← {𝕊 args:
  key‿surface‿composition ← 3↑args
  presentation ← {negative_style⇐"minus",daily_flow_max_date_columns⇐14}
  {𝕊: presentation ↩ 3⊑args}⍟(3<≠args) @
  admitted ← request.Validate ⟨key,surface⟩
  diagnostics ← admitted.diagnostics
  diagnostics∾↩(key≡"all")/⟨Diagnostic ⟨"single_render_required","one-result renderer does not accept all"⟩⟩
  diagnostics∾↩(composition.state≢"ok")/⟨Diagnostic ⟨"composition_not_ok","composition must be successful before rendering"⟩⟩
  diagnostics∾↩((composition.state≡"ok") ∧ composition.key≢key)/⟨Diagnostic ⟨"composition_key_mismatch","composition key must equal rendering key"⟩⟩
  output ← Failure diagnostics
  {𝕊:
    result ← composition.result ⋄ rendered ← ""
    {𝕊:
      {𝕊:rendered↩envelopes.FormatHuman ⟨result,presentation⟩}⍟(key≡"envelopes") @
      {𝕊:rendered↩balances.FormatHuman ⟨result,presentation⟩}⍟(key≡"balances") @
      {𝕊:rendered↩balanceSheet.FormatHuman ⟨result,presentation⟩}⍟(key≡"balance-sheet") @
      {𝕊:rendered↩profitLoss.FormatHuman ⟨result,presentation⟩}⍟(key≡"profit-and-loss") @
      {𝕊:rendered↩recent.FormatHuman ⟨result,presentation⟩}⍟(key≡"recent") @
      {𝕊:rendered↩planned.FormatHuman ⟨result,presentation⟩}⍟(key≡"planned") @
      {𝕊:rendered↩cycleAccounts.FormatHuman ⟨result,presentation⟩}⍟(key≡"cycle-accounts") @
      {𝕊:rendered↩cycleComparison.FormatHuman ⟨result,presentation⟩}⍟(key≡"cycle-comparison") @
      {𝕊:rendered↩monthlyAccounts.FormatHuman ⟨result,presentation⟩}⍟(key≡"monthly-accounts") @
      {𝕊:rendered↩dailyFlow.FormatHuman ⟨result,presentation⟩}⍟(key≡"daily-flow") @
      {𝕊:rendered↩dailyTarget.FormatHuman ⟨result,presentation⟩}⍟(key≡"daily-target") @
      {𝕊:rendered↩issues.FormatHuman ⟨result,presentation⟩}⍟(key≡"issues") @
    }⍟(surface≡"human") @
    {𝕊:
      {𝕊:rendered↩envelopes.FormatCompact result}⍟(key≡"envelopes") @
      {𝕊:rendered↩balances.FormatCompact result}⍟(key≡"balances") @
      {𝕊:rendered↩recent.FormatCompact result}⍟(key≡"recent") @
      {𝕊:rendered↩planned.FormatCompact result}⍟(key≡"planned") @
      {𝕊:rendered↩dailyTarget.FormatCompact result}⍟(key≡"daily-target") @
    }⍟(surface≡"compact") @
    {𝕊:
      {𝕊:rendered↩envelopes.FormatJson result}⍟(key≡"envelopes") @
      {𝕊:rendered↩balances.FormatJson result}⍟(key≡"balances") @
      {𝕊:rendered↩planned.FormatJson result}⍟(key≡"planned") @
    }⍟(surface≡"json") @
    output↩{state⇐"ok",text⇐rendered,diagnostics⇐empty}
  }⍟(0=≠diagnostics) @
  output
}

{Render⇐Render}
