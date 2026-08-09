# Strict post-write admission for canonical plan.journal.

planSource ← •Import "../src/application/plan_source_adapter.bqn"
canonical ← •Import "../src/application/canonical_household_sources.bqn"
editorCurrency ← •Import "../src/application/editor_currency.bqn"
setup ← editorCurrency.Load @
args ← •args
tab ← @+9
{𝕊:•Out "ERROR"∾tab∾"usage"∾tab∾"expected base" ⋄ •Exit 2}⍟(1≠≠args) @
base ← ⊑args
result ← planSource.Load ⟨base,setup.registry⟩
{𝕊:
  diagnostic ← ⊑result.diagnostics
  •Out "ERROR"∾tab∾diagnostic.stage∾tab∾diagnostic.code∾tab∾diagnostic.message
  •Exit 1
}⍟(result.state≢"ok") @
•Out "OK"∾tab∾"PLAN_JOURNAL"∾tab∾canonical.plan∾tab∾•Fmt result.facts.transactions.count