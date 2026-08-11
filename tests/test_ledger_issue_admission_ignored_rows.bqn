#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
issues ← •Import "../src/ledger/issue_admission.bqn"
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry

header ← "issue_id\tstatus\tdate\tcategory\ttitle\tamount\tcurrency\tdetails"
row ← "blank-proof\topen\t2026-08-11\tdecision\tBlank row proof\t\t\tkept"

# Admit is a pure line-vector boundary. Empty/comment rows are ignored while the
# original supplied-row coordinate remains the source reference of data rows.
result ← issues.Admit ⟨⟨header,"","# comment",row⟩,registry⟩
"ok" lib.AssertEq result.state
0 lib.AssertEq ≠result.diagnostics
1 lib.AssertEq result.issues.count
⟨"blank-proof"⟩ lib.AssertEq result.issues.issue_id
⟨4⟩ lib.AssertEq result.issues.source_row
⟨"issues.tsv:row:4"⟩ lib.AssertEq result.issues.source_ref

•Out "test_ledger_issue_admission_ignored_rows: ok"
