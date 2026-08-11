#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
issues ← •Import "../src/ledger/issue_admission.bqn"
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry

h ← "issue_id	status	date	category	title	amount	currency	details"
result ← issues.Admit ⟨
  ⟨
    h,
    "bad-status	pending	2026-01-01	decision	Bad status			A",
    "dup	open	2026-01-02	decision	One			B",
    "bad-date	open	2026-02-30	decision	Bad date			C",
    "dup	resolved	2026-01-03	decision	Two			D"
  ⟩,
  registry
⟩

"error" lib.AssertEq result.state
0 lib.AssertEq result.issues.count
⟨"issue_status_invalid","issue_date_invalid","issue_identity_duplicate"⟩ lib.AssertEq {𝕩.code}¨result.diagnostics
⟨2,4,0⟩ lib.AssertEq {𝕩.source_row}¨result.diagnostics

•Out "test_ledger_issue_admission_diagnostic_order: ok"
