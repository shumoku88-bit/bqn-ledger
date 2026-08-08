#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
registryBuilder ← •Import "../src/ledger/currency_registry.bqn"
io ← •Import "../src/application/source_io.bqn"
sources ← •Import "../src/application/report_source_adapter.bqn"

registryResult ← registryBuilder.Build io.ReadLines "config/currencies.tsv"
"ok" lib.AssertEq registryResult.state

# The retained manifest coordinate is routing debt until report.toml Phase 6.
# It must not choose or provide a physical Plan source after Phase 3 cutover.
fakeAccounts ← {key⇐⟨"not-the-canonical-axis"⟩}
result ← sources.Plan ⟨
  "fixtures/canonical-household-v1",
  "does-not-exist-plan.tsv",
  fakeAccounts,
  registryResult.registry
⟩
"ok" lib.AssertEq result.state
0 lib.AssertEq ≠result.diagnostics
"plan.journal" lib.AssertEq ⊑result.facts.sources.name
⟨"plan"⟩ lib.AssertEq result.facts.layers.name
2 lib.AssertEq result.facts.transactions.count
⟨"plan-groceries","plan-salary"⟩ lib.AssertEq result.facts.transactions.plan_id

•Out "test_application_report_source_canonical_plan: ok"
