# Pure rendering dispatch for one successfully composed retained result.

catalog ← •Import "catalog.bqn"
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
surfaces ← ⟨"human","compact","json"⟩
relation ← catalog.Table @

humanRenderers ← ⟨
  {𝕊 input: envelopes.FormatHuman input},
  {𝕊 input: balances.FormatHuman input},
  {𝕊 input: balanceSheet.FormatHuman input},
  {𝕊 input: profitLoss.FormatHuman input},
  {𝕊 input: recent.FormatHuman input},
  {𝕊 input: planned.FormatHuman input},
  {𝕊 input: cycleAccounts.FormatHuman input},
  {𝕊 input: cycleComparison.FormatHuman input},
  {𝕊 input: monthlyAccounts.FormatHuman input},
  {𝕊 input: dailyFlow.FormatHuman input},
  {𝕊 input: dailyTarget.FormatHuman input},
  {𝕊 input: issues.FormatHuman input}
⟩
compactRenderers ← ⟨
  {𝕊 result: envelopes.FormatCompact result},
  {𝕊 result: balances.FormatCompact result},
  {𝕊 result: recent.FormatCompact result},
  {𝕊 result: planned.FormatCompact result},
  {𝕊 result: dailyTarget.FormatCompact result}
⟩
jsonRenderers ← ⟨
  {𝕊 result: envelopes.FormatJson result},
  {𝕊 result: balances.FormatJson result},
  {𝕊 result: planned.FormatJson result}
⟩

Diagnostic ← {𝕊 code‿message:
  {severity⇐"error",stage⇐"report_render",code⇐code,message⇐message}
}
Failure ← {𝕊 diagnosticsValue:
  {state⇐"error",text⇐"",diagnostics⇐diagnosticsValue}
}

RenderHuman ← {𝕊 index‿result‿presentation:
  index◶humanRenderers ⟨result,presentation⟩
}
RenderCompact ← {𝕊 index‿result‿presentation:
  coordinate ← +´index↑relation.compact
  coordinate◶compactRenderers result
}
RenderJson ← {𝕊 index‿result‿presentation:
  coordinate ← +´index↑relation.json
  coordinate◶jsonRenderers result
}
Dispatch ← {𝕊 surface‿index‿result‿presentation:
  surfaceIndex ← ⊑(surface⊸≡¨surfaces)⊐1
  surfaceIndex◶⟨RenderHuman,RenderCompact,RenderJson⟩ ⟨index,result,presentation⟩
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
    index ← ⊑admitted.section_indices
    rendered ← Dispatch ⟨surface,index,composition.result,presentation⟩
    output↩{state⇐"ok",text⇐rendered,diagnostics⇐empty}
  }⍟(0=≠diagnostics) @
  output
}

{Render⇐Render}
