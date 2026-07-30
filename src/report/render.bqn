# Pure rendering dispatch for one successfully composed retained result.

request ← •Import "request.bqn"
envelopes ← •Import "../sections/envelope_backing.bqn"
balances ← •Import "../sections/account_balances.bqn"
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

Render ← {𝕊 key‿surface‿composition:
  admitted ← request.Validate ⟨key,surface⟩
  diagnostics ← admitted.diagnostics
  diagnostics∾↩(key≡"all")/⟨Diagnostic ⟨"single_render_required","one-result renderer does not accept all"⟩⟩
  diagnostics∾↩(composition.state≢"ok")/⟨Diagnostic ⟨"composition_not_ok","composition must be successful before rendering"⟩⟩
  diagnostics∾↩((composition.state≡"ok") ∧ composition.key≢key)/⟨Diagnostic ⟨"composition_key_mismatch","composition key must equal rendering key"⟩⟩
  output ← Failure diagnostics
  {𝕊:
    result ← composition.result ⋄ rendered ← ""
    {𝕊:
      {𝕊:rendered↩envelopes.FormatHuman result}⍟(key≡"envelopes") @
      {𝕊:rendered↩balances.FormatHuman result}⍟(key≡"balances") @
      {𝕊:rendered↩recent.FormatHuman result}⍟(key≡"recent") @
      {𝕊:rendered↩planned.FormatHuman result}⍟(key≡"planned") @
      {𝕊:rendered↩cycleAccounts.FormatHuman result}⍟(key≡"cycle-accounts") @
      {𝕊:rendered↩cycleComparison.FormatHuman result}⍟(key≡"cycle-comparison") @
      {𝕊:rendered↩monthlyAccounts.FormatHuman result}⍟(key≡"monthly-accounts") @
      {𝕊:rendered↩dailyFlow.FormatHuman result}⍟(key≡"daily-flow") @
      {𝕊:rendered↩dailyTarget.FormatHuman result}⍟(key≡"daily-target") @
      {𝕊:rendered↩issues.FormatHuman result}⍟(key≡"issues") @
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
