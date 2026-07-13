#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
admission ← •Import "../src_next/source_currency_admission.bqn"

tab ← @+9
Line ← {𝕊 fields: ∾ fields ∾¨ tab }
Snapshot ← {𝕊 journal‿plan‿budget:
  {
    sources ⇐ ⟨
      {source_file⇐"journal.tsv", required⇐1, lines⇐journal},
      {source_file⇐"plan.tsv", required⇐0, lines⇐plan},
      {source_file⇐"budget_alloc.tsv", required⇐0, lines⇐budget}
    ⟩
  }
}
accounts ← ⟨"assets:bank"∾tab∾"role=asset"∾tab∾"currency=JPY", "expenses:food"∾tab∾"role=expense"∾tab∾"currency=ILS"⟩
policyCarrier ← admission.policy
strictPolicy ← policyCarrier.production_strict
compatibilityPolicy ← policyCarrier.legacy_compatibility
explicitRows ← Snapshot ⟨
  ⟨Line ⟨"2026-07-01", "safe memo", "assets:bank", "expenses:food", "10", "currency=JPY"⟩⟩,
  ⟨Line ⟨"2026-07-02", "safe plan", "assets:bank", "expenses:food", "20", "currency=ILS"⟩⟩,
  ⟨Line ⟨"2026-07-03", "safe budget", "assets:bank", "expenses:food", "30", "currency=JPY"⟩⟩
⟩

strict ← admission.Admit ⟨strictPolicy, accounts, explicitRows⟩
"ok" lib.AssertEq strict.state
0 lib.AssertEq ≠ strict.diagnostics
2 lib.AssertEq ≠ strict.admitted_account_evidence
3 lib.AssertEq ≠ strict.admitted_row_evidence
⟨"journal.tsv", "plan.tsv", "budget_alloc.tsv"⟩ lib.AssertEq ({𝕩.source_file}¨ strict.admitted_row_evidence)
⟨"explicit", "explicit", "explicit"⟩ lib.AssertEq ({𝕩.provenance}¨ strict.admitted_row_evidence)

CheckStrictError ← {𝕊 accountLines‿snapshot‿expectedCode‿expectedFile‿expectedRow:
  result ← admission.Admit ⟨strictPolicy, accountLines, snapshot⟩
  "error" lib.AssertEq result.state
  0 lib.AssertEq ≠ result.admitted_account_evidence
  0 lib.AssertEq ≠ result.admitted_row_evidence
  diagnostic ← ⊑ result.diagnostics
  "error" lib.AssertEq diagnostic.severity
  "source_currency_admission" lib.AssertEq diagnostic.stage
  expectedCode lib.AssertEq diagnostic.code
  expectedFile lib.AssertEq diagnostic.source_file
  expectedRow lib.AssertEq diagnostic.source_row
  1
}

# Account missing, empty, duplicate, and unsupported are independently classified.
CheckStrictError ⟨⟨"assets:bank"⟩, explicitRows, "account_currency_missing", "accounts.tsv", 0⟩
CheckStrictError ⟨⟨"assets:bank"∾tab∾"currency="⟩, explicitRows, "account_currency_empty", "accounts.tsv", 0⟩
CheckStrictError ⟨⟨"assets:bank"∾tab∾"currency=JPY"∾tab∾"currency=ILS"⟩, explicitRows, "account_currency_duplicate", "accounts.tsv", 0⟩
CheckStrictError ⟨⟨"assets:bank"∾tab∾"currency=USD"⟩, explicitRows, "account_currency_unsupported", "accounts.tsv", 0⟩

# Journal-like missing, empty, duplicate, and unsupported are independently classified.
baseRow ← ⟨"2026-07-01", "private memo", "assets:bank", "expenses:food", "999"⟩
CheckStrictError ⟨accounts, Snapshot ⟨⟨Line baseRow⟩, ⟨⟩, ⟨⟩⟩, "row_currency_missing", "journal.tsv", 0⟩
CheckStrictError ⟨accounts, Snapshot ⟨⟨Line (baseRow ∾ ⟨"currency="⟩)⟩, ⟨⟩, ⟨⟩⟩, "row_currency_empty", "journal.tsv", 0⟩
CheckStrictError ⟨accounts, Snapshot ⟨⟨Line (baseRow ∾ ⟨"currency=JPY", "currency=ILS"⟩)⟩, ⟨⟩, ⟨⟩⟩, "row_currency_duplicate", "journal.tsv", 0⟩
CheckStrictError ⟨accounts, Snapshot ⟨⟨Line (baseRow ∾ ⟨"currency=USD"⟩)⟩, ⟨⟩, ⟨⟩⟩, "row_currency_unsupported", "journal.tsv", 0⟩

# All optional source rows are admitted and their zero-based row indices are retained.
planBad ← Snapshot ⟨⟨⟩, ⟨"# ignored", Line baseRow⟩, ⟨⟩⟩
CheckStrictError ⟨accounts, planBad, "row_currency_missing", "plan.tsv", 1⟩
budgetBad ← Snapshot ⟨⟨⟩, ⟨⟩, ⟨"", Line baseRow⟩⟩
CheckStrictError ⟨accounts, budgetBad, "row_currency_missing", "budget_alloc.tsv", 1⟩
emptyOptional ← admission.Admit ⟨strictPolicy, accounts, Snapshot ⟨⟨⟩, ⟨⟩, ⟨⟩⟩⟩
"ok" lib.AssertEq emptyOptional.state
0 lib.AssertEq ≠ emptyOptional.admitted_row_evidence

# Errors collect across supplied account and every journal-like source without partial admission.
multi ← admission.Admit ⟨strictPolicy, ⟨"assets:bank"⟩, Snapshot ⟨⟨Line baseRow⟩, ⟨Line (baseRow ∾ ⟨"currency="⟩)⟩, ⟨Line (baseRow ∾ ⟨"currency=USD"⟩)⟩⟩⟩
"error" lib.AssertEq multi.state
4 lib.AssertEq ≠ multi.diagnostics
0 lib.AssertEq ≠ multi.admitted_account_evidence
0 lib.AssertEq ≠ multi.admitted_row_evidence

# Compatibility preserves only missing-as-JPY; malformed explicit source stays fatal.
compatMissing ← admission.Admit ⟨compatibilityPolicy, ⟨"assets:bank"⟩, Snapshot ⟨⟨Line baseRow⟩, ⟨⟩, ⟨⟩⟩⟩
"ok" lib.AssertEq compatMissing.state
"JPY" lib.AssertEq (⊑ compatMissing.admitted_account_evidence).currency
"legacy_compatibility" lib.AssertEq (⊑ compatMissing.admitted_account_evidence).provenance
"JPY" lib.AssertEq (⊑ compatMissing.admitted_row_evidence).currency
"legacy_compatibility" lib.AssertEq (⊑ compatMissing.admitted_row_evidence).provenance
compatIls ← admission.Admit ⟨compatibilityPolicy, ⟨"assets:bank"∾tab∾"currency=ILS"⟩, Snapshot ⟨⟨Line (baseRow ∾ ⟨"currency=ILS"⟩)⟩, ⟨⟩, ⟨⟩⟩⟩
"ok" lib.AssertEq compatIls.state
"ILS" lib.AssertEq (⊑ compatIls.admitted_account_evidence).currency
"explicit" lib.AssertEq (⊑ compatIls.admitted_row_evidence).provenance
compatBad ← admission.Admit ⟨compatibilityPolicy, ⟨"assets:bank"∾tab∾"currency="⟩, Snapshot ⟨⟨Line (baseRow ∾ ⟨"currency=USD"⟩)⟩, ⟨⟩, ⟨⟩⟩⟩
"error" lib.AssertEq compatBad.state
2 lib.AssertEq ≠ compatBad.diagnostics
0 lib.AssertEq ≠ compatBad.admitted_account_evidence
0 lib.AssertEq ≠ compatBad.admitted_row_evidence
compatDuplicate ← admission.Admit ⟨compatibilityPolicy, ⟨"assets:bank"∾tab∾"currency=JPY"∾tab∾"currency=ILS"⟩, Snapshot ⟨⟨Line (baseRow ∾ ⟨"currency=JPY", "currency=ILS"⟩)⟩, ⟨⟩, ⟨⟩⟩⟩
"error" lib.AssertEq compatDuplicate.state
⟨"account_currency_duplicate", "row_currency_duplicate"⟩ lib.AssertEq ({𝕩.code}¨ compatDuplicate.diagnostics)
0 lib.AssertEq ≠ compatDuplicate.admitted_account_evidence
0 lib.AssertEq ≠ compatDuplicate.admitted_row_evidence

# Unknown policy is checked and fail-closed.
unknown ← admission.Admit ⟨"future_policy", accounts, explicitRows⟩
"error" lib.AssertEq unknown.state
"source_currency_policy_unknown" lib.AssertEq (⊑ unknown.diagnostics).code
0 lib.AssertEq ≠ unknown.admitted_account_evidence
0 lib.AssertEq ≠ unknown.admitted_row_evidence

# Diagnostics are safe summaries: they retain only basename, row, and classification.
privateAccount ← "private-account-name"
privateMemo ← "private memo"
privateAmount ← "999"
privateToken ← "currency=SECRET"
privacy ← admission.Admit ⟨strictPolicy, ⟨privateAccount∾tab∾privateToken⟩, Snapshot ⟨⟨Line ⟨"2026-07-01", privateMemo, "from", "to", privateAmount, privateToken⟩⟩, ⟨⟩, ⟨⟩⟩⟩
message ← (⊑ privacy.diagnostics).message
0 lib.AssertEq ∨´ privateAccount ⍷ message
0 lib.AssertEq ∨´ privateMemo ⍷ message
0 lib.AssertEq ∨´ privateAmount ⍷ message
0 lib.AssertEq ∨´ "SECRET" ⍷ message
"accounts.tsv row 0: account_currency_unsupported" lib.AssertEq message

# An unknown or path-shaped supplied source is rejected without reflecting its value.
privateSourceFile ← "/private/example/journal.tsv"
privateSourceSnapshot ← {
  sources ⇐ ⟨{source_file⇐privateSourceFile, required⇐1, lines⇐⟨Line (baseRow ∾ ⟨"currency=JPY"⟩)⟩}⟩
}
privateSource ← admission.Admit ⟨strictPolicy, accounts, privateSourceSnapshot⟩
"error" lib.AssertEq privateSource.state
0 lib.AssertEq ≠ privateSource.admitted_account_evidence
0 lib.AssertEq ≠ privateSource.admitted_row_evidence
privateSourceDiagnostic ← ⊑ privateSource.diagnostics
"source_currency_source_file_invalid" lib.AssertEq privateSourceDiagnostic.code
"" lib.AssertEq privateSourceDiagnostic.source_kind
"" lib.AssertEq privateSourceDiagnostic.source_file
¯1 lib.AssertEq privateSourceDiagnostic.source_row
"posting source file invalid" lib.AssertEq privateSourceDiagnostic.message
0 lib.AssertEq ∨´ privateSourceFile ⍷ privateSourceDiagnostic.message
0 lib.AssertEq ∨´ privateSourceFile ⍷ privateSourceDiagnostic.source_file

•Out "test_src_next_source_currency_admission.bqn: OK"
