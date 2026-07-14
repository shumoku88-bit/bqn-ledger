#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
check ← •Import "../src_edit/journal_source_integrity.bqn"
tab ← @+9
Line ← {𝕊 fields: ∾({𝕩∾tab}¨¯1↓fields)∾⟨¯1⊑fields⟩}
accounts ← ⟨
  Line ⟨"assets:jpy", "role=asset", "currency=JPY"⟩,
  Line ⟨"expenses:jpy", "role=expense", "currency=JPY"⟩,
  Line ⟨"assets:ils", "role=asset", "currency=ILS"⟩,
  Line ⟨"expenses:ils", "role=expense", "currency=ILS"⟩
⟩
Request ← {𝕊 lines: {account_lines⇐accounts, journal_lines⇐lines} }
CheckOk ← {𝕊 lines:
  result ← check.Check Request lines
  "ok" lib.AssertEq result.state
  0 lib.AssertEq ≠result.diagnostics
  (≠lines) lib.AssertEq result.row_count
}
CheckError ← {𝕊 lines‿code:
  result ← check.Check Request lines
  "error" lib.AssertEq result.state
  0 lib.AssertEq result.row_count
  lib.Assert 0<≠result.diagnostics
  lib.Assert ∨´code⊸≡¨({𝕩.code}¨result.diagnostics)
  result
}
jpy ← Line ⟨"2026-07-20", "jpy", "assets:jpy", "expenses:jpy", "100", "currency=JPY"⟩
ils ← Line ⟨"2026-07-21", "ils", "assets:ils", "expenses:ils", "42.50", "currency=ILS"⟩
legacy ← Line ⟨"2026-07-19", "legacy", "assets:jpy", "expenses:jpy", "50"⟩
CheckOk ⟨jpy⟩
CheckOk ⟨ils⟩
CheckOk ⟨ils, jpy⟩
CheckOk ⟨jpy, ils⟩
CheckOk ⟨jpy, ils, jpy, ils⟩
CheckOk ⟨legacy, ils⟩
commented ← check.Check Request ⟨"", "# comment", "\\ comment", jpy⟩
"ok" lib.AssertEq commented.state
1 lib.AssertEq commented.row_count

CheckError ⟨⟨Line ⟨"2026-07-20", "x", "missing", "expenses:jpy", "1", "currency=JPY"⟩⟩, "row_from_account_unknown"⟩
CheckError ⟨⟨Line ⟨"2026-07-20", "x", "assets:jpy", "expenses:ils", "1", "currency=JPY"⟩⟩, "row_to_currency_mismatch"⟩
CheckError ⟨⟨Line ⟨"2026-07-20", "x", "assets:jpy", "expenses:jpy", "1", "currency=EUR"⟩⟩, "row_currency_unsupported"⟩
CheckError ⟨⟨Line ⟨"2026-07-20", "x", "assets:jpy", "expenses:jpy", "1", "currency=JPY", "currency=JPY"⟩⟩, "row_currency_duplicate"⟩
CheckError ⟨⟨Line ⟨"2026-07-20", "x", "assets:jpy", "expenses:jpy", "1x", "currency=JPY"⟩⟩, "row_amount_invalid"⟩
CheckError ⟨⟨Line ⟨"2026-07-20", "x", "assets:ils", "expenses:ils", "1.001", "currency=ILS"⟩⟩, "row_currency_amount_invalid"⟩
CheckError ⟨⟨"2026-07-20"∾tab∾"broken"⟩, "row_column_count_invalid"⟩
CheckError ⟨⟨Line ⟨"2026-02-30", "x", "assets:jpy", "expenses:jpy", "1", "currency=JPY"⟩⟩, "row_date_invalid"⟩

privacy ← CheckError ⟨⟨Line ⟨"private-date", "private-memo", "private-from", "private-to", "private-amount", "currency=SECRET"⟩⟩, "row_currency_unsupported"⟩
messages ← ∾({𝕩.message∾"\n"}¨privacy.diagnostics)
{𝕩⋄0 lib.AssertEq ∨´𝕩⍷messages}¨⟨"private-date", "private-memo", "private-from", "private-to", "private-amount", "SECRET"⟩
•Out "test_edit_journal_source_integrity.bqn: OK"
