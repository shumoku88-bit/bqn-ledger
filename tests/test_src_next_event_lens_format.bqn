#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
fmt ← •Import "../src_next/event_lens_format.bqn"

Tab ← @+9
Lf ← @+10
Cr ← @+13
Slash ← @+92

Columns ← ⟨
  "source_file",
  "source_row",
  "source_id",
  "when_value",
  "when_state",
  "party_value",
  "party_state",
  "what_value",
  "what_state",
  "from_account",
  "where_to_value",
  "where_to_state",
  "amount_text",
  "amount_coefficient",
  "amount_scale",
  "currency",
  "amount_state",
  "action_value",
  "action_state",
  "layer",
  "kind"
⟩

JoinWith ← {𝕊 sep‿parts:
  (0 = ≠ parts) ? "" ; {𝕊:
    rest ← { sep ∾ 𝕩 }¨ (1 ↓ parts)
    (⊑ parts) ∾ ∾ rest
  } @
}

Header ← JoinWith ⟨Tab, Columns⟩
ExpectedRow ← { JoinWith ⟨Tab, 𝕩⟩ }

MakeRow ← {𝕊 sourceRow‿sourceId‿partyValue‿partyState‿whatValue‿whatState‿amountText‿coefficient‿scale‿currencyValue:
  {
    source_file ⇐ "journal.tsv",
    source_row ⇐ sourceRow,
    source_id ⇐ sourceId,
    when_value ⇐ "2026-06-15",
    when_state ⇐ "direct",
    party_value ⇐ partyValue,
    party_state ⇐ partyState,
    what_value ⇐ whatValue,
    what_state ⇐ whatState,
    from_account ⇐ "assets:bank",
    where_to_value ⇐ "expenses:food",
    where_to_state ⇐ "direct",
    amount_text ⇐ amountText,
    amount_coefficient ⇐ coefficient,
    amount_scale ⇐ scale,
    currency ⇐ currencyValue,
    amount_state ⇐ "direct",
    action_value ⇐ "actual:expense",
    action_state ⇐ "derived",
    layer ⇐ "actual",
    kind ⇐ "expense"
  }
}

# 1. JPY, explicit party, and ambiguous what are emitted in exact column order.
jpyRow ← MakeRow ⟨0, "normal memo", "StoreA", "direct", "normal memo", "ambiguous", "1200", 1200, 0, "JPY"⟩
jpyResult ← fmt.FormatTsv { state ⇐ "ok", rows ⇐ ⟨jpyRow⟩ }
"ok" lib.AssertEq jpyResult.state
"" lib.AssertEq jpyResult.message
jpyExpectedRow ← ExpectedRow ⟨
  "journal.tsv", "0", "normal memo", "2026-06-15", "direct",
  "StoreA", "direct", "normal memo", "ambiguous",
  "assets:bank", "expenses:food", "direct",
  "1200", "1200", "0", "JPY", "direct",
  "actual:expense", "derived", "actual", "expense"
⟩
(Header ∾ Lf ∾ jpyExpectedRow ∾ Lf) lib.AssertEq jpyResult.text

# 2. ILS exact decimal evidence stays split and unformatted.
ilsRow ← MakeRow ⟨1, "book", "", "absent", "book", "ambiguous", "42.50", 4250, 2, "ILS"⟩
ilsResult ← fmt.FormatTsv { state ⇐ "ok", rows ⇐ ⟨ilsRow⟩ }
ilsExpectedRow ← ExpectedRow ⟨
  "journal.tsv", "1", "book", "2026-06-15", "direct",
  "", "absent", "book", "ambiguous",
  "assets:bank", "expenses:food", "direct",
  "42.50", "4250", "2", "ILS", "direct",
  "actual:expense", "derived", "actual", "expense"
⟩
(Header ∾ Lf ∾ ilsExpectedRow ∾ Lf) lib.AssertEq ilsResult.text

# 3. Empty party and empty memo remain empty TSV cells with absent states.
emptyRow ← MakeRow ⟨2, "", "", "absent", "", "absent", "0.05", 5, 2, "ILS"⟩
emptyResult ← fmt.FormatTsv { state ⇐ "ok", rows ⇐ ⟨emptyRow⟩ }
emptyExpectedRow ← ExpectedRow ⟨
  "journal.tsv", "2", "", "2026-06-15", "direct",
  "", "absent", "", "absent",
  "assets:bank", "expenses:food", "direct",
  "0.05", "5", "2", "ILS", "direct",
  "actual:expense", "derived", "actual", "expense"
⟩
(Header ∾ Lf ∾ emptyExpectedRow ∾ Lf) lib.AssertEq emptyResult.text

# 4. Multiple rows preserve source order and one-row-per-source identity.
multiResult ← fmt.FormatTsv { state ⇐ "ok", rows ⇐ ⟨jpyRow, ilsRow, emptyRow⟩ }
(Header ∾ Lf ∾ jpyExpectedRow ∾ Lf ∾ ilsExpectedRow ∾ Lf ∾ emptyExpectedRow ∾ Lf) lib.AssertEq multiResult.text

# 5. Header-only success ends with exactly one LF.
headerOnly ← fmt.FormatTsv { state ⇐ "ok", rows ⇐ ⟨⟩ }
"ok" lib.AssertEq headerOnly.state
(Header ∾ Lf) lib.AssertEq headerOnly.text
"" lib.AssertEq headerOnly.message

# 6. Error input fails closed and preserves the message.
errorResult ← fmt.FormatTsv { state ⇐ "error", message ⇐ "checked result state is not ok" }
"error" lib.AssertEq errorResult.state
"" lib.AssertEq errorResult.text
"checked result state is not ok" lib.AssertEq errorResult.message

# 7. Backslash, TAB, CR, and LF are escaped deterministically inside cells.
special ← "a" ∾ ⟨Slash⟩ ∾ "b" ∾ ⟨Tab⟩ ∾ "c" ∾ ⟨Cr⟩ ∾ "d" ∾ ⟨Lf⟩ ∾ "e"
escaped ← "a" ∾ ⟨Slash, Slash⟩ ∾ "b" ∾ ⟨Slash, @+116⟩ ∾ "c" ∾ ⟨Slash, @+114⟩ ∾ "d" ∾ ⟨Slash, @+110⟩ ∾ "e"
escapeRow ← MakeRow ⟨3, special, "", "absent", special, "ambiguous", "100", 100, 0, "JPY"⟩
escapeResult ← fmt.FormatTsv { state ⇐ "ok", rows ⇐ ⟨escapeRow⟩ }
escapeExpectedRow ← ExpectedRow ⟨
  "journal.tsv", "3", escaped, "2026-06-15", "direct",
  "", "absent", escaped, "ambiguous",
  "assets:bank", "expenses:food", "direct",
  "100", "100", "0", "JPY", "direct",
  "actual:expense", "derived", "actual", "expense"
⟩
(Header ∾ Lf ∾ escapeExpectedRow ∾ Lf) lib.AssertEq escapeResult.text

# 8. Repeated calls with equal input are equal.
repeatResult ← fmt.FormatTsv { state ⇐ "ok", rows ⇐ ⟨jpyRow, ilsRow⟩ }
repeatResult.text lib.AssertEq (fmt.FormatTsv { state ⇐ "ok", rows ⇐ ⟨jpyRow, ilsRow⟩ }).text
repeatResult.message lib.AssertEq (fmt.FormatTsv { state ⇐ "ok", rows ⇐ ⟨jpyRow, ilsRow⟩ }).message

•Out "All event lens TSV formatter tests passed!"
