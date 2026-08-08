#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
registryBuilder ← •Import "../src/ledger/currency_registry.bqn"
io ← •Import "../src/application/source_io.bqn"
sources ← •Import "../src/application/report_source_adapter.bqn"

registryResult ← registryBuilder.Build io.ReadLines "config/currencies.tsv"
"ok" lib.AssertEq registryResult.state

# Plan source identity is fixed by the canonical Household root. There is no
# caller-selected Plan path or caller-provided Account axis after cutover.
result ← sources.CanonicalPlan ⟨"fixtures/canonical-household-v1",registryResult.registry⟩
"ok" lib.AssertEq result.state
0 lib.AssertEq ≠result.diagnostics
"plan.journal" lib.AssertEq ⊑result.facts.sources.name
⟨"plan"⟩ lib.AssertEq result.facts.layers.name
⟨"plan-groceries","plan-salary"⟩ lib.AssertEq result.facts.transactions.plan_id

•Out "test_application_report_source_canonical_plan: ok"
