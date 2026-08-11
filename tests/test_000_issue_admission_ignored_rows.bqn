#!/usr/bin/env bqn

loader ← •Import "../src/application/source_io.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
issues ← •Import "../src/ledger/issue_admission.bqn"
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
fixture ← loader.ReadLines "fixtures/ledger-facts-phase1-proof/issues.destination.tsv"
lines ← ⟨0⊑fixture,"","# comment"⟩∾1↓fixture
result ← issues.Admit ⟨lines,registry⟩
result.state

•Out "temporary Issue totality gate: ok"
