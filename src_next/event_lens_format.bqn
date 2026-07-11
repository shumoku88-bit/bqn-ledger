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

Escape ← {
  ∾ {
    𝕩 = slash_char ? ⟨slash_char, slash_char⟩ ;
    𝕩 = tab_char   ? ⟨slash_char, @+116⟩ ;
    𝕩 = lf_char    ? ⟨slash_char, @+110⟩ ;
    𝕩 = cr_char    ? ⟨slash_char, @+114⟩ ;
    ⟨𝕩⟩
  }¨ 𝕩
}

FormatFields ← { ¯1 ↓ ∾ (𝕩 ∾¨ tab_char) }
header ← FormatFields Escape¨ columns

FormatInt ← {
  𝕩 < 0 ? "-" ∾ •Fmt -𝕩 ;
  •Fmt 𝕩
}

FormatRow ← {
  FormatFields Escape¨ ⟨
    𝕩.source_file,
    FormatInt 𝕩.source_row,
    𝕩.source_id,
    𝕩.when_value,
    𝕩.when_state,
    𝕩.party_value,
    𝕩.party_state,
    𝕩.what_value,
    𝕩.what_state,
    𝕩.from_account,
    𝕩.where_to_value,
    𝕩.where_to_state,
    𝕩.amount_text,
    FormatInt 𝕩.amount_coefficient,
    FormatInt 𝕩.amount_scale,
    𝕩.currency,
    𝕩.amount_state,
    𝕩.action_value,
    𝕩.action_state,
    𝕩.layer,
    𝕩.kind
  ⟩
}

FormatTsv ← {
  (𝕩.state ≢ "ok") ? {
    msg ← 𝕩.message
    {
      state ⇐ "error",
      text ⇐ "",
      message ⇐ msg
    }
  } 𝕩 ;
  formatted_rows ← FormatRow¨ 𝕩.rows
  text_out ← header ∾ lf_char ∾ ∾ formatted_rows ∾¨ lf_char
  {
    state ⇐ "ok",
    text ⇐ text_out,
    message ⇐ ""
  }
}

{
  FormatTsv ⇐ FormatTsv
}
