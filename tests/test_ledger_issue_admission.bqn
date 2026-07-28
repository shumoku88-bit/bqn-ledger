#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
loader ← •Import "../src_next/loader.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
issues ← •Import "../src/ledger/issue_admission.bqn"
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
lines ← loader.ReadLines "fixtures/ledger-facts-phase1-proof/issues.destination.tsv"
result ← issues.Admit ⟨lines,registry⟩
"ok" lib.AssertEq result.state
3 lib.AssertEq result.issues.count
⟨"subscription-review","missing-receipt","resolved-demo"⟩ lib.AssertEq result.issues.issue_id
⟨"open","open","resolved"⟩ lib.AssertEq result.issues.status
⟨1,0,1⟩ lib.AssertEq result.issues.amount_present
123 lib.AssertEq 0⊑result.issues.coefficient
1 lib.AssertEq 0⊑result.issues.scale
"ILS" lib.AssertEq 0⊑result.issues.currency
⟨⟩ lib.AssertEq 1⊑result.issues.coefficient
⟨⟩ lib.AssertEq 1⊑result.issues.date_ordinal
"issues.tsv:row:2" lib.AssertEq 0⊑result.issues.source_ref

empty ← issues.Admit ⟨⟨"issue_id	status	date	category	title	amount	currency	details"⟩,registry⟩
"ok" lib.AssertEq empty.state
0 lib.AssertEq empty.issues.count
absent ← issues.Admit ⟨⟨⟩,registry⟩
"ok" lib.AssertEq absent.state
0 lib.AssertEq absent.issues.count

Reject ← {𝕊 rows‿code:
  rejected ← issues.Admit ⟨rows,registry⟩
  "error" lib.AssertEq rejected.state
  0 lib.AssertEq rejected.issues.count
  lib.Assert ∨´code⊸≡¨{𝕩.code}¨rejected.diagnostics
}
h ← "issue_id	status	date	category	title	amount	currency	details"
Reject ⟨⟨h,"x	pending	2026-01-01	decision	Title			Details"⟩,"issue_status_invalid"⟩
Reject ⟨⟨h,"x	open	2026-02-30	decision	Title			Details"⟩,"issue_date_invalid"⟩
Reject ⟨⟨h,"x	open		decision	Title	10		Details"⟩,"issue_amount_currency_pair_invalid"⟩
Reject ⟨⟨h,"x	open		decision	Title	1.234	ILS	Details"⟩,"issue_amount_precision_exceeded"⟩
Reject ⟨⟨h,"x	open		decision	One			A","x	resolved		decision	Two			B"⟩,"issue_identity_duplicate"⟩
•Out "test_ledger_issue_admission: ok"
