#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
root ← •Import "../src/ledger/canonical_journal_root_admission.bqn"

lf ← @+10
tab ← @+9
Raw ← {𝕊 lines: ∾ lines ∾¨ lf }
HasCode ← {𝕊 code‿diagnostics: ∨´0∾{𝕩.code≡code}¨diagnostics }
Codes ← {𝕊 diagnostics: {𝕩.code}¨diagnostics }
Lines ← {𝕊 diagnostics: {𝕩.line}¨diagnostics }

known ← root.Admit ⟨Raw ⟨
  "include accounts.journal",
  "",
  "2026-08-08 valid",
  "  Assets:Cash  -100 JPY",
  "  Expenses:Food"
⟩,"accounts.journal"⟩
"ok" lib.AssertEq known.state
⟨"accounts.journal"⟩ lib.AssertEq known.includes

none ← root.Admit ⟨Raw ⟨
  "2026-08-08 standalone resolved document",
  "  Assets:Cash  -100 JPY",
  "  Expenses:Food"
⟩,"accounts.journal"⟩
"ok" lib.AssertEq none.state
0 lib.AssertEq ≠none.includes

# Directive recognition is lexical at the root boundary: leading whitespace and
# ASCII tab separators are admitted, semicolon comments are removed from the path,
# and words that merely begin with "include" are ordinary Journal source text.
boundaries ← root.Admit ⟨Raw ⟨
  "  include accounts.journal   ; canonical Account source",
  "include"∾⟨tab⟩∾"accounts.journal ; same canonical source",
  "; include typo-accounts.journal",
  "includeaccounts.journal",
  "included accounts.journal",
  "in",
  ""
⟩,"accounts.journal"⟩
"error" lib.AssertEq boundaries.state
⟨"accounts.journal","accounts.journal"⟩ lib.AssertEq boundaries.includes
⟨"journal_include_duplicate"⟩ lib.AssertEq Codes boundaries.diagnostics
⟨0⟩ lib.AssertEq Lines boundaries.diagnostics

unknown ← root.Admit ⟨Raw ⟨"include typo-accounts.journal"⟩,"accounts.journal"⟩
"error" lib.AssertEq unknown.state
⟨"typo-accounts.journal"⟩ lib.AssertEq unknown.includes
lib.Assert HasCode ⟨"journal_include_unknown",unknown.diagnostics⟩

duplicate ← root.Admit ⟨Raw ⟨
  "include accounts.journal",
  "include accounts.journal"
⟩,"accounts.journal"⟩
"error" lib.AssertEq duplicate.state
lib.Assert HasCode ⟨"journal_include_duplicate",duplicate.diagnostics⟩

emptyInclude ← root.Admit ⟨Raw ⟨"include"⟩,"accounts.journal"⟩
"error" lib.AssertEq emptyInclude.state
0 lib.AssertEq ≠emptyInclude.includes
lib.Assert HasCode ⟨"journal_include_empty",emptyInclude.diagnostics⟩

# Per-directive diagnostics remain source ordered; the duplicate canonical-source
# law is an aggregate root diagnostic and is appended after line-owned failures.
orderedDiagnostics ← root.Admit ⟨Raw ⟨
  "include typo-accounts.journal",
  "include ; comment leaves an empty path",
  "include accounts.journal",
  "include accounts.journal"
⟩,"accounts.journal"⟩
"error" lib.AssertEq orderedDiagnostics.state
⟨"typo-accounts.journal","accounts.journal","accounts.journal"⟩ lib.AssertEq orderedDiagnostics.includes
⟨"journal_include_unknown","journal_include_empty","journal_include_duplicate"⟩ lib.AssertEq Codes orderedDiagnostics.diagnostics
⟨1,2,0⟩ lib.AssertEq Lines orderedDiagnostics.diagnostics

•Out "test_ledger_canonical_journal_root_admission: ok"
