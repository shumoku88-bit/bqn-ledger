# friend_travel_source_event.bqn
# I/O-free validation for Israel friend-paid pending source events.

dates ← •Import "date.bqn"
decimal ← •Import "../src/ledger/exact_decimal.bqn"
util ← •Import "../src/text/parse.bqn"

empty ← ⟨⟩
tab ← @+9
lf ← @+10
cr ← @+13

Diagnostic ← {𝕊 codeText‿fieldText‿messageText:
  {severity⇐"error", stage⇐"friend_travel_source_event", code⇐codeText, field⇐fieldText, message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid / ⟨diagnostic⟩ }
IsSafeText ← {𝕊 text: (0 < ≠text) ∧ ¬ ∨´ text ∊ tab‿lf‿cr }
IsPositive ← {𝕊 parsed: (parsed.state ≡ "ok") ∧ 0 < parsed.coefficient }
FractionDigits ← {𝕊 text:
  positions ← ('.' = text) / ↕≠text
  (1 = ≠positions) ◶ ⟨{𝕩 ⋄ 0}, {𝕩 ⋄ ((≠text)-1)-⊑positions}⟩ text
}

Event ← {𝕊 fields:
  {date⇐0⊑fields, party⇐1⊑fields, item_or_category⇐2⊑fields, original_amount⇐3⊑fields,
   original_currency⇐4⊑fields, payer⇐5⊑fields, trip_id⇐6⊑fields,
   source_event_id⇐7⊑fields, status⇐8⊑fields}
}
Fields ← {𝕊 event:
  ⟨event.date, event.party, event.item_or_category, event.original_amount,
   event.original_currency, event.payer, event.trip_id, event.source_event_id, event.status⟩
}
Render ← {𝕊 event:
  fields ← Fields event
  ∾ ({𝕩∾tab}¨ ¯1↓fields) ∾ ⟨¯1⊑fields⟩
}

ValidateEvent ← {𝕊 event:
  parsed ← decimal.Parse event.original_amount
  diagnostics ← empty
  diagnostics ∾↩ AddIf ⟨¬ dates.IsValidDateText event.date, Diagnostic ⟨"date_invalid", "date", "date must be a valid YYYY-MM-DD calendar date"⟩⟩
  diagnostics ∾↩ AddIf ⟨¬ IsSafeText event.party, Diagnostic ⟨"party_invalid", "party", "party must be nonempty and TSV-field safe"⟩⟩
  diagnostics ∾↩ AddIf ⟨¬ IsSafeText event.item_or_category, Diagnostic ⟨"item_or_category_invalid", "item_or_category", "item or category must be nonempty and TSV-field safe"⟩⟩
  diagnostics ∾↩ AddIf ⟨¬ IsPositive parsed, Diagnostic ⟨"original_amount_invalid", "original_amount", "original amount must be a positive exact decimal"⟩⟩
  diagnostics ∾↩ AddIf ⟨2 < FractionDigits event.original_amount, Diagnostic ⟨"original_amount_precision_invalid", "original_amount", "ILS amount must have at most two fractional digits"⟩⟩
  diagnostics ∾↩ AddIf ⟨event.original_currency ≢ "ILS", Diagnostic ⟨"original_currency_invalid", "original_currency", "original currency must be ILS"⟩⟩
  diagnostics ∾↩ AddIf ⟨event.payer ≢ "friend", Diagnostic ⟨"payer_invalid", "payer", "payer must be friend"⟩⟩
  diagnostics ∾↩ AddIf ⟨event.trip_id ≢ "israel-2026", Diagnostic ⟨"trip_id_invalid", "trip_id", "trip id must be israel-2026"⟩⟩
  diagnostics ∾↩ AddIf ⟨¬ IsSafeText event.source_event_id, Diagnostic ⟨"source_event_id_invalid", "source_event_id", "source event id must be nonempty and TSV-field safe"⟩⟩
  diagnostics ∾↩ AddIf ⟨event.status ≢ "pending", Diagnostic ⟨"status_invalid", "status", "status must be pending"⟩⟩
  diagnostics
}

ParseExisting ← {𝕊 lines:
  diagnostics ← empty
  events ← empty
  {𝕊 line:
    fields ← tab util.SplitKeepEmpty line
    {𝕊:
      event ← Event fields
      eventDiagnostics ← ValidateEvent event
      diagnostics ∾↩ eventDiagnostics
      events ∾↩ (0=≠eventDiagnostics) / ⟨event⟩
    } ⍟ (9=≠fields) @
    diagnostics ∾↩ AddIf ⟨9≠≠fields, Diagnostic ⟨"existing_row_shape_invalid", "existing_source", "existing data row must contain exactly nine columns"⟩⟩
  }¨ lines
  ids ← {𝕩.source_event_id}¨ events
  duplicate ← (≠ids) ≠ ≠⍷ids
  diagnostics ∾↩ AddIf ⟨duplicate, Diagnostic ⟨"existing_source_event_id_duplicate", "existing_source", "existing source event ids must be unique"⟩⟩
  {state⇐(0=≠diagnostics)⊑"error"‿"ok", diagnostics⇐diagnostics, events⇐events, ids⇐ids}
}

ValidateExisting ← {𝕊 lines:
  parsed ← ParseExisting lines
  {state⇐parsed.state, diagnostics⇐parsed.diagnostics, event_count⇐≠parsed.events}
}

ValidateAndPreview ← {𝕊 request:
  existing ← ParseExisting request.existing_lines
  candidateDiagnostics ← ValidateEvent request.event
  duplicate ← ∨´ 0 ∾ request.event.source_event_id⊸≡¨ existing.ids
  candidateDiagnostics ∾↩ AddIf ⟨duplicate, Diagnostic ⟨"source_event_id_duplicate", "source_event_id", "source event id already exists"⟩⟩
  diagnostics ← existing.diagnostics ∾ candidateDiagnostics
  rows ← empty
  {𝕊: rows ↩ ⟨Render request.event⟩ } ⍟ (0=≠diagnostics) @
  {state⇐(0=≠diagnostics)⊑"error"‿"ok", diagnostics⇐diagnostics, preview_rows⇐rows}
}

{ValidateAndPreview⇐ValidateAndPreview, ValidateExisting⇐ValidateExisting, Render⇐Render}
