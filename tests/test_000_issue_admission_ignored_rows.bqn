#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
issues ← •Import "../src/ledger/issue_admission.bqn"
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
fixture ← loader.ReadLines "fixtures/ledger-facts-phase1-proof/issues.destination.tsv"
lines ← ⟨0⊑fixture,"","# comment"⟩∾1↓fixture
result ← issues.Admit ⟨lines,registry⟩
"ok" lib.AssertEq result.state
0 lib.AssertEq ≠result.diagnostics
3 lib.AssertEq result.issues.count
⟨4,5,6⟩ lib.AssertEq result.issues.source_row
⟨"issues.tsv:row:4","issues.tsv:row:5","issues.tsv:row:6"⟩ lib.AssertEq result.issues.source_ref

•Out "temporary Issue gate: ok"
