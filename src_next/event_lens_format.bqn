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

FormatTsv ← {𝕊 lensResult:
  { state ⇐ lensResult.state, text ⇐ "", message ⇐ "" }
}

{
  FormatTsv ⇐ FormatTsv
}
