# event_lens_format.bqn
# Pure deterministic TSV formatter for read-only Event Lens results.

Tab ← @+9
Lf ← @+10

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

FormatRowCells ← { ¯1 ↓ ∾ (𝕩 ∾¨ Tab) }
Header ← FormatRowCells Columns

FormatTsv ← {𝕊 lensResult:
  { state ⇐ lensResult.state, text ⇐ Header ∾ Lf, message ⇐ "" }
}

{
  FormatTsv ⇐ FormatTsv
}
