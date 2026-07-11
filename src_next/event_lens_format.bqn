# event_lens_format.bqn
# Pure deterministic TSV formatter for read-only Event Lens results.

tab_char ← @+9
lf_char ← @+10
cr_char ← @+13
slash_char ← @+92

columns ← ⟨
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

FormatFields ← { ¯1 ↓ ∾ (𝕩 ∾¨ tab_char) }

EscapeChar ← {𝕊 ch:
  (ch = slash_char) ? ⟨slash_char, slash_char⟩ ;
  (ch = tab_char) ? ⟨slash_char, @+116⟩ ;
  (ch = cr_char) ? ⟨slash_char, @+114⟩ ;
  (ch = lf_char) ? ⟨slash_char, @+110⟩ ;
  ⟨ch⟩
}

EscapeCell ← {𝕊 cell:
  pieces ← EscapeChar¨ cell
  (0 = ≠ pieces) ? "" ; ∾ pieces
}

RowCells ← {𝕊 row:
  ⟨
    row.source_file,
    •Fmt row.source_row,
    row.source_id,
    row.when_value,
    row.when_state,
    row.party_value,
    row.party_state,
    row.what_value,
    row.what_state,
    row.from_account,
    row.where_to_value,
    row.where_to_state,
    row.amount_text,
    •Fmt row.amount_coefficient,
    •Fmt row.amount_scale,
    row.currency,
    row.amount_state,
    row.action_value,
    row.action_state,
    row.layer,
    row.kind
  ⟩
}

header ← FormatFields columns
FormatRow ← { FormatFields EscapeCell¨ RowCells 𝕩 }

FormatTsv ← {
  (𝕩.state ≢ "ok") ?
    {𝕊 lensResult:
      { state ⇐ "error", text ⇐ "", message ⇐ lensResult.message }
    } 𝕩 ;
    {𝕊 lensResult:
      data_lines ← FormatRow¨ lensResult.rows
      text ← header ∾ lf_char ∾ ∾ (data_lines ∾¨ lf_char)
      { state ⇐ "ok", text ⇐ text, message ⇐ "" }
    } 𝕩
}

{
  FormatTsv ⇐ FormatTsv
}
