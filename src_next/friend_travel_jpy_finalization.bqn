# friend_travel_jpy_finalization.bqn
# I/O-free validation and all-or-nothing one-row JPY journal preview.

dates ← •Import "date.bqn"
decimal ← •Import "exact_decimal.bqn"

empty ← ⟨⟩
tab ← @+9
lf ← @+10
vt ← @+11
ff ← @+12
cr ← @+13
asciiUpper ← "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
tokenWhitespace ← " " ∾ ⟨tab, lf, vt, ff, cr⟩

Diagnostic ← {𝕊 codeText‿fieldText‿messageText:
  {
    severity ⇐ "error",
    stage ⇐ "friend_travel_jpy_finalization",
    code ⇐ codeText,
    field ⇐ fieldText,
    message ⇐ messageText
  }
}

AddIf ← {𝕊 invalid‿diagnostic: invalid / ⟨diagnostic⟩ }

IsSafeText ← {𝕊 text:
  (0 < ≠ text) ∧ ¬ ∨´ (text ∊ ⟨tab, cr, lf⟩)
}

IsSafeToken ← {𝕊 text:
  forbidden ← tokenWhitespace ∾ "="
  (0 < ≠ text) ∧ ¬ ∨´ (text ∊ forbidden)
}

IsCurrencyToken ← {𝕊 text:
  (3 = ≠ text) ∧ ∧´ (text ∊ asciiUpper)
}

IsPositiveDecimal ← {𝕊 parsed:
  (parsed.state ≡ "ok") ∧ (0 < parsed.coefficient)
}

IsPositiveJpyInteger ← {𝕊 parsed:
  (parsed.state ≡ "ok") ∧ (0 < parsed.coefficient) ∧ (0 = parsed.scale)
}

AccountDiagnostics ← {𝕊 descriptor‿fieldName‿requiredRole:
  diagnostics ← empty
  diagnostics ∾↩ AddIf ⟨¬ IsSafeText descriptor.name, Diagnostic ⟨fieldName∾"_name_invalid", fieldName, "selected account name must be nonempty and journal-field safe"⟩⟩
  diagnostics ∾↩ AddIf ⟨descriptor.exists ≠ 1, Diagnostic ⟨fieldName∾"_not_existing", fieldName, "selected account must already exist"⟩⟩
  diagnostics ∾↩ AddIf ⟨descriptor.currency ≢ "JPY", Diagnostic ⟨fieldName∾"_currency_invalid", fieldName, "selected account must use JPY"⟩⟩
  diagnostics ∾↩ AddIf ⟨descriptor.role ≢ requiredRole, Diagnostic ⟨fieldName∾"_role_invalid", fieldName, "selected account has the wrong role"⟩⟩
  diagnostics
}

# Catch only required-member extraction. Validation and preview bugs remain visible.
ExtractRequest ← {𝕊 request:
  sourceEvent ← request.event
  liability ← request.liability_account
  expense ← request.expense_account
  normalizedEvent ← {
    date ⇐ sourceEvent.date,
    party ⇐ sourceEvent.party,
    item_or_category ⇐ sourceEvent.item_or_category,
    original_amount ⇐ sourceEvent.original_amount,
    original_currency ⇐ sourceEvent.original_currency,
    payer ⇐ sourceEvent.payer,
    trip_id ⇐ sourceEvent.trip_id,
    source_event_id ⇐ sourceEvent.source_event_id,
    status ⇐ sourceEvent.status
  }
  normalizedLiability ← {
    name ⇐ liability.name,
    exists ⇐ liability.exists,
    role ⇐ liability.role,
    currency ⇐ liability.currency
  }
  normalizedExpense ← {
    name ⇐ expense.name,
    exists ⇐ expense.exists,
    role ⇐ expense.role,
    currency ⇐ expense.currency
  }
  normalizedRequest ← {
    event ⇐ normalizedEvent,
    finalization_date ⇐ request.finalization_date,
    jpy_amount ⇐ request.jpy_amount,
    liability_account ⇐ normalizedLiability,
    expense_account ⇐ normalizedExpense,
    existing_finalization_ids ⇐ request.existing_finalization_ids
  }
  {ok⇐1, value⇐normalizedRequest}
} ⎊ {𝕩 ⋄ {ok⇐0, value⇐empty}}

PreviewRow ← {𝕊 request‿jpyParsed:
  event ← request.event
  {
    date ⇐ request.finalization_date,
    memo ⇐ event.party ∾ ": " ∾ event.item_or_category,
    from_account ⇐ request.liability_account.name,
    to_account ⇐ request.expense_account.name,
    amount ⇐ •Fmt jpyParsed.coefficient,
    metadata ⇐ ⟨"currency=JPY", "source_event_id="∾event.source_event_id, "trip_id="∾event.trip_id⟩
  }
}

ValidateExtractedRequest ← {𝕊 request:
  event ← request.event
  originalParsed ← decimal.Parse event.original_amount
  jpyParsed ← decimal.Parse request.jpy_amount

  diagnostics ← empty
  diagnostics ∾↩ AddIf ⟨¬ dates.IsValidDateText event.date, Diagnostic ⟨"purchase_date_invalid", "event.date", "purchase date must be a valid YYYY-MM-DD date"⟩⟩
  diagnostics ∾↩ AddIf ⟨¬ dates.IsValidDateText request.finalization_date, Diagnostic ⟨"finalization_date_invalid", "finalization_date", "finalization date must be a valid YYYY-MM-DD date"⟩⟩
  diagnostics ∾↩ AddIf ⟨event.payer ≢ "friend", Diagnostic ⟨"payer_invalid", "event.payer", "payer must be friend"⟩⟩
  diagnostics ∾↩ AddIf ⟨event.status ≢ "pending", Diagnostic ⟨"status_invalid", "event.status", "source event must be pending"⟩⟩
  diagnostics ∾↩ AddIf ⟨¬ IsSafeText event.party, Diagnostic ⟨"party_invalid", "event.party", "party must be nonempty and journal-field safe"⟩⟩
  diagnostics ∾↩ AddIf ⟨¬ IsSafeText event.item_or_category, Diagnostic ⟨"item_or_category_invalid", "event.item_or_category", "item or category must be nonempty and journal-field safe"⟩⟩
  diagnostics ∾↩ AddIf ⟨¬ IsPositiveDecimal originalParsed, Diagnostic ⟨"original_amount_invalid", "event.original_amount", "original amount must be a positive exact decimal"⟩⟩
  diagnostics ∾↩ AddIf ⟨¬ IsCurrencyToken event.original_currency, Diagnostic ⟨"original_currency_invalid", "event.original_currency", "original currency must be a three-letter uppercase token"⟩⟩
  diagnostics ∾↩ AddIf ⟨¬ IsSafeToken event.source_event_id, Diagnostic ⟨"source_event_id_invalid", "event.source_event_id", "source event id must be a nonempty safe token"⟩⟩
  diagnostics ∾↩ AddIf ⟨¬ IsSafeToken event.trip_id, Diagnostic ⟨"trip_id_invalid", "event.trip_id", "trip id must be a nonempty safe token"⟩⟩
  diagnostics ∾↩ AddIf ⟨¬ IsPositiveJpyInteger jpyParsed, Diagnostic ⟨"jpy_amount_invalid", "jpy_amount", "JPY amount must be a positive integer"⟩⟩
  diagnostics ∾↩ AccountDiagnostics ⟨request.liability_account, "liability_account", "liability"⟩
  diagnostics ∾↩ AccountDiagnostics ⟨request.expense_account, "expense_account", "expense"⟩
  alreadyFinalized ← ∨´ 0 ∾ (event.source_event_id⊸≡¨ request.existing_finalization_ids)
  diagnostics ∾↩ AddIf ⟨alreadyFinalized, Diagnostic ⟨"source_event_already_finalized", "event.source_event_id", "source event already has a finalization entry"⟩⟩

  result ← {state⇐"error", diagnostics⇐diagnostics, preview_rows⇐empty}
  {𝕊:
    result ↩ {state⇐"ok", diagnostics⇐empty, preview_rows⇐⟨PreviewRow ⟨request, jpyParsed⟩⟩}
  } ⍟ (0 = ≠ diagnostics) @
  result
}

ValidateAndPreview ← {𝕊 request:
  extracted ← ExtractRequest request
  shapeDiagnostic ← Diagnostic ⟨"request_shape_invalid", "request", "request is missing required members"⟩
  result ← {state⇐"error", diagnostics⇐⟨shapeDiagnostic⟩, preview_rows⇐empty}
  {𝕊: result ↩ ValidateExtractedRequest extracted.value } ⍟ extracted.ok @
  result
}

{
  ValidateAndPreview ⇐ ValidateAndPreview
}
