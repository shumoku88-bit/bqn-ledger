#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
admission ← •Import "../src/ledger/issue_admission.bqn"
section ← •Import "../src/sections/issues.bqn"
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
admitted ← admission.Admit ⟨loader.ReadLines "fixtures/ledger-facts-phase1-proof/issues.destination.tsv",registry⟩
result ← section.Build admitted
"ok" lib.AssertEq result.state
"open" lib.AssertEq result.selection
2 lib.AssertEq result.issues.count
⟨"subscription-review","missing-receipt"⟩ lib.AssertEq result.issues.issue_id
⟨"issues.tsv:row:2","issues.tsv:row:3"⟩ lib.AssertEq result.issues.source_ref
(•FChars "../fixtures/ledger-facts-phase1-proof/issues.destination.human.txt") lib.AssertEq section.FormatHuman result
emptyAdmission ← admission.Admit ⟨⟨"issue_id	status	date	category	title	amount	currency	details"⟩,registry⟩
emptyResult ← section.Build emptyAdmission
"ok" lib.AssertEq emptyResult.state
lib.Assert ∨´"(none)"⍷section.FormatHuman emptyResult
rejected ← section.Build admission.Admit ⟨⟨"bad"⟩,registry⟩
"error" lib.AssertEq rejected.state
0 lib.AssertEq rejected.issues.count
•Out "test_section_issues: ok"
