#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
fmt ← •Import "../src_next/event_lens_format.bqn"

tab_char ← @+9
lf_char ← @+10
cr_char ← @+13
slash_char ← @+92

header_text ← "source_file" ∾ tab_char ∾ "source_row" ∾ tab_char ∾ "source_id" ∾ tab_char ∾ "when_value" ∾ tab_char ∾ "when_state" ∾ tab_char ∾ "party_value" ∾ tab_char ∾ "party_state" ∾ tab_char ∾ "what_value" ∾ tab_char ∾ "what_state" ∾ tab_char ∾ "from_account" ∾ tab_char ∾ "where_to_value" ∾ tab_char ∾ "where_to_state" ∾ tab_char ∾ "amount_text" ∾ tab_char ∾ "amount_coefficient" ∾ tab_char ∾ "amount_scale" ∾ tab_char ∾ "currency" ∾ tab_char ∾ "amount_state" ∾ tab_char ∾ "action_value" ∾ tab_char ∾ "action_state" ∾ tab_char ∾ "layer" ∾ tab_char ∾ "kind"

MakeRow ← {𝕊 ⟨party_val, party_st, what_val, what_st, amt_txt, coef, scale, curr, src_id⟩:
  {
    source_file ⇐ "journal.tsv",
    source_row ⇐ 0,
    source_id ⇐ src_id,
    when_value ⇐ "2026-06-15",
    when_state ⇐ "direct",
    party_value ⇐ party_val,
    party_state ⇐ party_st,
    what_value ⇐ what_val,
    what_state ⇐ what_st,
    from_account ⇐ "assets:bank",
    where_to_value ⇐ "expenses:food",
    where_to_state ⇐ "direct",
    amount_text ⇐ amt_txt,
    amount_coefficient ⇐ coef,
    amount_scale ⇐ scale,
    currency ⇐ curr,
    amount_state ⇐ "direct",
    action_value ⇐ "actual:expense",
    action_state ⇐ "derived",
    layer ⇐ "actual",
    kind ⇐ "expense"
  }
}

# 1. One normal JPY row
row1 ← MakeRow ⟨"", "absent", "normal memo", "ambiguous", "1200", 1200, 0, "JPY", "normal memo"⟩
res1 ← fmt.FormatTsv { state ⇐ "ok", rows ⇐ ⟨row1⟩ }
"ok" lib.AssertEq res1.state
"" lib.AssertEq res1.message

expected_row1 ← "journal.tsv" ∾ tab_char ∾ "0" ∾ tab_char ∾ "normal memo" ∾ tab_char ∾ "2026-06-15" ∾ tab_char ∾ "direct" ∾ tab_char ∾ "" ∾ tab_char ∾ "absent" ∾ tab_char ∾ "normal memo" ∾ tab_char ∾ "ambiguous" ∾ tab_char ∾ "assets:bank" ∾ tab_char ∾ "expenses:food" ∾ tab_char ∾ "direct" ∾ tab_char ∾ "1200" ∾ tab_char ∾ "1200" ∾ tab_char ∾ "0" ∾ tab_char ∾ "JPY" ∾ tab_char ∾ "direct" ∾ tab_char ∾ "actual:expense" ∾ tab_char ∾ "derived" ∾ tab_char ∾ "actual" ∾ tab_char ∾ "expense"
expected_text1 ← header_text ∾ lf_char ∾ expected_row1 ∾ lf_char
expected_text1 lib.AssertEq res1.text

# 2. Empty and ambiguous values
row2 ← MakeRow ⟨"", "absent", "nonempty", "ambiguous", "1200", 1200, 0, "JPY", "memo"⟩
res2 ← fmt.FormatTsv { state ⇐ "ok", rows ⇐ ⟨row2⟩ }
expected_row2 ← "journal.tsv" ∾ tab_char ∾ "0" ∾ tab_char ∾ "memo" ∾ tab_char ∾ "2026-06-15" ∾ tab_char ∾ "direct" ∾ tab_char ∾ "" ∾ tab_char ∾ "absent" ∾ tab_char ∾ "nonempty" ∾ tab_char ∾ "ambiguous" ∾ tab_char ∾ "assets:bank" ∾ tab_char ∾ "expenses:food" ∾ tab_char ∾ "direct" ∾ tab_char ∾ "1200" ∾ tab_char ∾ "1200" ∾ tab_char ∾ "0" ∾ tab_char ∾ "JPY" ∾ tab_char ∾ "direct" ∾ tab_char ∾ "actual:expense" ∾ tab_char ∾ "derived" ∾ tab_char ∾ "actual" ∾ tab_char ∾ "expense"
(header_text ∾ lf_char ∾ expected_row2 ∾ lf_char) lib.AssertEq res2.text

# 3. Explicit party
row3 ← MakeRow ⟨"StoreA", "direct", "memo text", "ambiguous", "1200", 1200, 0, "JPY", "memo"⟩
res3 ← fmt.FormatTsv { state ⇐ "ok", rows ⇐ ⟨row3⟩ }
expected_row3 ← "journal.tsv" ∾ tab_char ∾ "0" ∾ tab_char ∾ "memo" ∾ tab_char ∾ "2026-06-15" ∾ tab_char ∾ "direct" ∾ tab_char ∾ "StoreA" ∾ tab_char ∾ "direct" ∾ tab_char ∾ "memo text" ∾ tab_char ∾ "ambiguous" ∾ tab_char ∾ "assets:bank" ∾ tab_char ∾ "expenses:food" ∾ tab_char ∾ "direct" ∾ tab_char ∾ "1200" ∾ tab_char ∾ "1200" ∾ tab_char ∾ "0" ∾ tab_char ∾ "JPY" ∾ tab_char ∾ "direct" ∾ tab_char ∾ "actual:expense" ∾ tab_char ∾ "derived" ∾ tab_char ∾ "actual" ∾ tab_char ∾ "expense"
(header_text ∾ lf_char ∾ expected_row3 ∾ lf_char) lib.AssertEq res3.text

# 4. Empty memo / absent what
row4 ← MakeRow ⟨"", "absent", "", "absent", "1200", 1200, 0, "JPY", ""⟩
res4 ← fmt.FormatTsv { state ⇐ "ok", rows ⇐ ⟨row4⟩ }
expected_row4 ← "journal.tsv" ∾ tab_char ∾ "0" ∾ tab_char ∾ "" ∾ tab_char ∾ "2026-06-15" ∾ tab_char ∾ "direct" ∾ tab_char ∾ "" ∾ tab_char ∾ "absent" ∾ tab_char ∾ "" ∾ tab_char ∾ "absent" ∾ tab_char ∾ "assets:bank" ∾ tab_char ∾ "expenses:food" ∾ tab_char ∾ "direct" ∾ tab_char ∾ "1200" ∾ tab_char ∾ "1200" ∾ tab_char ∾ "0" ∾ tab_char ∾ "JPY" ∾ tab_char ∾ "direct" ∾ tab_char ∾ "actual:expense" ∾ tab_char ∾ "derived" ∾ tab_char ∾ "actual" ∾ tab_char ∾ "expense"
(header_text ∾ lf_char ∾ expected_row4 ∾ lf_char) lib.AssertEq res4.text

# 5. Multiple rows
res5 ← fmt.FormatTsv { state ⇐ "ok", rows ⇐ ⟨row1, row2⟩ }
expected_text5 ← header_text ∾ lf_char ∾ expected_row1 ∾ lf_char ∾ expected_row2 ∾ lf_char
expected_text5 lib.AssertEq res5.text

# 6. All-ILS exact decimal rows
row_ils1 ← MakeRow ⟨"", "absent", "food", "ambiguous", "1200", 120000, 2, "ILS", "food"⟩
row_ils2 ← MakeRow ⟨"", "absent", "book", "ambiguous", "42.50", 4250, 2, "ILS", "book"⟩
row_ils3 ← MakeRow ⟨"", "absent", "small", "ambiguous", "0.05", 5, 2, "ILS", "small"⟩
res_ils ← fmt.FormatTsv { state ⇐ "ok", rows ⇐ ⟨row_ils1, row_ils2, row_ils3⟩ }

expected_row_ils1 ← "journal.tsv" ∾ tab_char ∾ "0" ∾ tab_char ∾ "food" ∾ tab_char ∾ "2026-06-15" ∾ tab_char ∾ "direct" ∾ tab_char ∾ "" ∾ tab_char ∾ "absent" ∾ tab_char ∾ "food" ∾ tab_char ∾ "ambiguous" ∾ tab_char ∾ "assets:bank" ∾ tab_char ∾ "expenses:food" ∾ tab_char ∾ "direct" ∾ tab_char ∾ "1200" ∾ tab_char ∾ "120000" ∾ tab_char ∾ "2" ∾ tab_char ∾ "ILS" ∾ tab_char ∾ "direct" ∾ tab_char ∾ "actual:expense" ∾ tab_char ∾ "derived" ∾ tab_char ∾ "actual" ∾ tab_char ∾ "expense"
expected_row_ils2 ← "journal.tsv" ∾ tab_char ∾ "0" ∾ tab_char ∾ "book" ∾ tab_char ∾ "2026-06-15" ∾ tab_char ∾ "direct" ∾ tab_char ∾ "" ∾ tab_char ∾ "absent" ∾ tab_char ∾ "book" ∾ tab_char ∾ "ambiguous" ∾ tab_char ∾ "assets:bank" ∾ tab_char ∾ "expenses:food" ∾ tab_char ∾ "direct" ∾ tab_char ∾ "42.50" ∾ tab_char ∾ "4250" ∾ tab_char ∾ "2" ∾ tab_char ∾ "ILS" ∾ tab_char ∾ "direct" ∾ tab_char ∾ "actual:expense" ∾ tab_char ∾ "derived" ∾ tab_char ∾ "actual" ∾ tab_char ∾ "expense"
expected_row_ils3 ← "journal.tsv" ∾ tab_char ∾ "0" ∾ tab_char ∾ "small" ∾ tab_char ∾ "2026-06-15" ∾ tab_char ∾ "direct" ∾ tab_char ∾ "" ∾ tab_char ∾ "absent" ∾ tab_char ∾ "small" ∾ tab_char ∾ "ambiguous" ∾ tab_char ∾ "assets:bank" ∾ tab_char ∾ "expenses:food" ∾ tab_char ∾ "direct" ∾ tab_char ∾ "0.05" ∾ tab_char ∾ "5" ∾ tab_char ∾ "2" ∾ tab_char ∾ "ILS" ∾ tab_char ∾ "direct" ∾ tab_char ∾ "actual:expense" ∾ tab_char ∾ "derived" ∾ tab_char ∾ "actual" ∾ tab_char ∾ "expense"

expected_text_ils ← header_text ∾ lf_char ∾ expected_row_ils1 ∾ lf_char ∾ expected_row_ils2 ∾ lf_char ∾ expected_row_ils3 ∾ lf_char
expected_text_ils lib.AssertEq res_ils.text

# 7. Successful zero-row result
res7 ← fmt.FormatTsv { state ⇐ "ok", rows ⇐ ⟨⟩ }
(header_text ∾ lf_char) lib.AssertEq res7.text

# 8. Failed lens result
res8 ← fmt.FormatTsv { state ⇐ "error", message ⇐ "custom error message" }
"error" lib.AssertEq res8.state
"" lib.AssertEq res8.text
"custom error message" lib.AssertEq res8.message

# 9. Escaping
esc_str ← "a" ∾ slash_char ∾ "b" ∾ tab_char ∾ "c" ∾ lf_char ∾ "d" ∾ cr_char ∾ "e"
row9 ← MakeRow ⟨"", "absent", esc_str, "ambiguous", "1200", 1200, 0, "JPY", "memo"⟩
res9 ← fmt.FormatTsv { state ⇐ "ok", rows ⇐ ⟨row9⟩ }
expected_escaped ← "a\\b\tc\nd\re"
expected_row9 ← "journal.tsv" ∾ tab_char ∾ "0" ∾ tab_char ∾ "memo" ∾ tab_char ∾ "2026-06-15" ∾ tab_char ∾ "direct" ∾ tab_char ∾ "" ∾ tab_char ∾ "absent" ∾ tab_char ∾ expected_escaped ∾ tab_char ∾ "ambiguous" ∾ tab_char ∾ "assets:bank" ∾ tab_char ∾ "expenses:food" ∾ tab_char ∾ "direct" ∾ tab_char ∾ "1200" ∾ tab_char ∾ "1200" ∾ tab_char ∾ "0" ∾ tab_char ∾ "JPY" ∾ tab_char ∾ "direct" ∾ tab_char ∾ "actual:expense" ∾ tab_char ∾ "derived" ∾ tab_char ∾ "actual" ∾ tab_char ∾ "expense"
(header_text ∾ lf_char ∾ expected_row9 ∾ lf_char) lib.AssertEq res9.text

# 10. Determinism
res10_a ← fmt.FormatTsv { state ⇐ "ok", rows ⇐ ⟨row1, row_ils2⟩ }
res10_b ← fmt.FormatTsv { state ⇐ "ok", rows ⇐ ⟨row1, row_ils2⟩ }
res10_a.state lib.AssertEq res10_b.state
res10_a.text lib.AssertEq res10_b.text
res10_a.message lib.AssertEq res10_b.message

•Out "All event lens TSV formatter focused tests passed successfully!"
