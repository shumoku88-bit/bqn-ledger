#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
issues ← •Import "../src/ledger/issue_admission.bqn"
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
fixture ← loader.ReadLines "fixtures/ledger-facts-phase1-proof/issues.destination.tsv"

# Admit is a pure line-vector boundary. Empty/comment rows are ignored while the
# original supplied-row coordinates remain the source references of data rows.
lines ← ⟨0⊑fixture,"","# comment"⟩∾1↓fixture
result ← issues.Admit ⟨lines,registry⟩
"ok" lib.AssertEq result.state
0 lib.AssertEq ≠result.diagnostics
3 lib.AssertEq result.issues.count
⟨"subscription-review","missing-receipt","resolved-demo"⟩ lib.AssertEq result.issues.issue_id
⟨4,5,6⟩ lib.AssertEq result.issues.source_row
⟨"issues.tsv:row:4","issues.tsv:row:5","issues.tsv:row:6"⟩ lib.AssertEq result.issues.source_ref

•Out "test_ledger_issue_admission_ignored_rows: ok"
