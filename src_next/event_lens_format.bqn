# event_lens_format.bqn
# Pure deterministic TSV formatter for read-only Event Lens results.

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

EscapeChar ← {𝕊 ch:
  (ch = Slash) ? ⟨Slash, Slash⟩ ;
  ((ch = Tab) ? ⟨Slash, @+116⟩ ;
    ((ch = Cr) ? ⟨Slash, @+114⟩ ;
      ((ch = Lf) ? ⟨Slash, @+110⟩ ; ⟨ch⟩)))
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

Header ← JoinWith ⟨Tab, Columns⟩
FormatRow ← {𝕊 row:
  cells ← RowCells row
  JoinWith ⟨Tab, EscapeCell¨ cells⟩
}

FormatTsv ← {
  (𝕩.state ≢ "ok") ?
    {𝕊 lensResult:
      { state ⇐ "error", text ⇐ "", message ⇐ lensResult.message }
    } 𝕩 ;
    {𝕊 lensResult:
      lines ← ⟨Header⟩ ∾ FormatRow¨ lensResult.rows
      { state ⇐ "ok", text ⇐ (JoinWith ⟨Lf, lines⟩) ∾ Lf, message ⇐ "" }
    } 𝕩
}

{
  FormatTsv ⇐ FormatTsv
}
