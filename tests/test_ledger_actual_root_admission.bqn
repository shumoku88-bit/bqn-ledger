#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
root ← •Import "../src/ledger/actual_root_admission.bqn"

lf ← @+10
Raw ← {𝕊 lines: ∾ lines ∾¨ lf }
HasCode ← {𝕊 code‿diagnostics: ∨´0∾{𝕩.code≡code}¨diagnostics }

known ← root.Admit ⟨Raw ⟨
  "include accounts.journal",
  "",
  "2026-08-08 * valid",
  "  Assets:Cash  -100 JPY",
  "  Expenses:Food"
⟩,"accounts.journal"⟩
"ok" lib.AssertEq known.state
⟨"accounts.journal"⟩ lib.AssertEq known.includes

none ← root.Admit ⟨Raw ⟨
  "2026-08-08 * standalone resolved document",
  "  Assets:Cash  -100 JPY",
  "  Expenses:Food"
⟩,"accounts.journal"⟩
"ok" lib.AssertEq none.state
0 lib.AssertEq ≠none.includes

unknown ← root.Admit ⟨Raw ⟨"include typo-accounts.journal"⟩,"accounts.journal"⟩
"error" lib.AssertEq unknown.state
lib.Assert HasCode ⟨"actual_include_unknown",unknown.diagnostics⟩

duplicate ← root.Admit ⟨Raw ⟨
  "include accounts.journal",
  "include accounts.journal"
⟩,"accounts.journal"⟩
"error" lib.AssertEq duplicate.state
lib.Assert HasCode ⟨"actual_include_duplicate",duplicate.diagnostics⟩

emptyInclude ← root.Admit ⟨Raw ⟨"include"⟩,"accounts.journal"⟩
"error" lib.AssertEq emptyInclude.state
lib.Assert HasCode ⟨"actual_include_empty",emptyInclude.diagnostics⟩

•Out "test_ledger_actual_root_admission: ok"
