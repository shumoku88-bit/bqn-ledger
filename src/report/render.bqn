# Pure rendering dispatch for one successfully composed retained result.

request ← •Import "request.bqn"
envelopes ← •Import "../sections/envelope_backing.bqn"
balances ← •Import "../sections/account_balances.bqn"
recent ← •Import "../sections/recent_journal.bqn"
planned ← •Import "../sections/planned_payments.bqn"
cycleAccounts ← •Import "../sections/cycle_accounts.bqn"
cycleComparison ← •Import "../sections/cycle_comparison.bqn"
monthlyAccounts ← •Import "../sections/monthly_accounts.bqn"
dailyTarget ← •Import "../sections/daily_target.bqn"
issues ← •Import "../sections/issues.bqn"
empty ← ⟨⟩
surfaces ← ⟨"human","compact","json"⟩

# Each route aligns report keys and formatter functions at the same coordinates.
Route ← {𝕊 keysValue‿formattersValue: {keys⇐keysValue,formatters⇐formattersValue}}
routes ← ⟨
  Route ⟨
    ⟨"envelopes","balances","recent","planned","cycle-accounts","cycle-comparison","monthly-accounts","daily-target","issues"⟩,
    ⟨envelopes.FormatHuman,balances.FormatHuman,recent.FormatHuman,planned.FormatHuman,cycleAccounts.FormatHuman,cycleComparison.FormatHuman,monthlyAccounts.FormatHuman,dailyTarget.FormatHuman,issues.FormatHuman⟩
  ⟩,
  Route ⟨
    ⟨"envelopes","balances","recent","planned","daily-target"⟩,
    ⟨envelopes.FormatCompact,balances.FormatCompact,recent.FormatCompact,planned.FormatCompact,dailyTarget.FormatCompact⟩
  ⟩,
  Route ⟨
    ⟨"envelopes","balances","planned"⟩,
    ⟨envelopes.FormatJson,balances.FormatJson,planned.FormatJson⟩
  ⟩
⟩

Diagnostic ← {𝕊 code‿message:
  {severity⇐"error",stage⇐"report_render",code⇐code,message⇐message}
}
Failure ← {𝕊 diagnosticsValue:
  {state⇐"error",text⇐"",diagnostics⇐diagnosticsValue}
}

# Formatter functions are selected as subject values, then called through function-role spelling.
Format ← {𝕊 key‿surface‿result:
  surfaceIndex ← ⊑ surfaces ⊐ ⟨surface⟩
  route ← surfaceIndex⊑routes
  keyIndex ← ⊑ route.keys ⊐ ⟨key⟩
  formatter ← keyIndex⊑route.formatters
  Formatter result
}

Render ← {𝕊 key‿surface‿composition:
  admitted ← request.Validate ⟨key,surface⟩
  diagnostics ← admitted.diagnostics
  diagnostics∾↩(key≡"all")/⟨Diagnostic ⟨"single_render_required","one-result renderer does not accept all"⟩⟩
  diagnostics∾↩(composition.state≢"ok")/⟨Diagnostic ⟨"composition_not_ok","composition must be successful before rendering"⟩⟩
  diagnostics∾↩((composition.state≡"ok") ∧ composition.key≢key)/⟨Diagnostic ⟨"composition_key_mismatch","composition key must equal rendering key"⟩⟩
  {𝕊:
    {state⇐"ok",text⇐Format ⟨key,surface,composition.result⟩,diagnostics⇐empty}
  }⍟(0=≠diagnostics) Failure diagnostics
}

{Render⇐Render}
