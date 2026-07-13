# travel_exchange_event.bqn
# I/O-free Israel JPY-to-ILS exchange validation and structured preview.

dates ← •Import "date.bqn"
decimal ← •Import "exact_decimal.bqn"
util ← •Import "util.bqn"

empty ← ⟨⟩
tab ← @+9
lf ← @+10
cr ← @+13

Diagnostic ← {𝕊 codeText‿fieldText‿messageText:
  {severity⇐"error", stage⇐"travel_exchange_event", code⇐codeText, field⇐fieldText, message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid / ⟨diagnostic⟩ }
IsSafeText ← {𝕊 text: (0<≠text) ∧ ¬∨´text∊tab‿lf‿cr }
IsPositive ← {𝕊 parsed: (parsed.state≡"ok") ∧ 0<parsed.coefficient }
FractionDigits ← {𝕊 text:
  positions ← ('.'=text)/↕≠text
  (1=≠positions) ◶ ⟨{𝕩⋄0}, {𝕩⋄((≠text)-1)-⊑positions}⟩ text
}
AccountDiagnostics ← {𝕊 account‿fieldName‿currency:
  diagnostics ← empty
  diagnostics ∾↩ AddIf ⟨¬IsSafeText account.name, Diagnostic ⟨fieldName∾"_name_invalid", fieldName, "selected account name must be nonempty and TSV-field safe"⟩⟩
  diagnostics ∾↩ AddIf ⟨account.exists≠1, Diagnostic ⟨fieldName∾"_not_existing", fieldName, "selected account must already exist"⟩⟩
  diagnostics ∾↩ AddIf ⟨account.currency≢currency, Diagnostic ⟨fieldName∾"_currency_invalid", fieldName, "selected account uses the wrong currency"⟩⟩
  diagnostics
}

Preview ← {𝕊 request:
  {state⇐"ok", date⇐request.date, memo⇐request.memo,
   source_account⇐request.source_account.name, source_amount⇐request.source_amount, source_currency⇐request.source_currency,
   target_account⇐request.target_account.name, target_amount⇐request.target_amount, target_currency⇐request.target_currency,
   exchange_id⇐request.exchange_id, trip_id⇐request.trip_id}
}

ValidateExtracted ← {𝕊 request:
  sourceParsed ← decimal.Parse request.source_amount
  targetParsed ← decimal.Parse request.target_amount
  diagnostics ← empty
  diagnostics ∾↩ AddIf ⟨¬dates.IsValidDateText request.date, Diagnostic ⟨"date_invalid", "date", "date must be a valid YYYY-MM-DD calendar date"⟩⟩
  diagnostics ∾↩ AddIf ⟨¬IsSafeText request.memo, Diagnostic ⟨"memo_invalid", "memo", "memo must be nonempty and TSV-field safe"⟩⟩
  diagnostics ∾↩ AccountDiagnostics ⟨request.source_account, "source_account", "JPY"⟩
  diagnostics ∾↩ AccountDiagnostics ⟨request.target_account, "target_account", "ILS"⟩
  diagnostics ∾↩ AddIf ⟨request.source_account.name≡request.target_account.name, Diagnostic ⟨"accounts_same", "accounts", "source and target accounts must differ"⟩⟩
  diagnostics ∾↩ AddIf ⟨request.source_currency≢"JPY", Diagnostic ⟨"source_currency_invalid", "source_currency", "source currency must be JPY"⟩⟩
  diagnostics ∾↩ AddIf ⟨request.target_currency≢"ILS", Diagnostic ⟨"target_currency_invalid", "target_currency", "target currency must be ILS"⟩⟩
  diagnostics ∾↩ AddIf ⟨request.source_currency≡request.target_currency, Diagnostic ⟨"currencies_same", "currencies", "source and target currencies must differ"⟩⟩
  diagnostics ∾↩ AddIf ⟨¬IsPositive sourceParsed, Diagnostic ⟨"source_amount_invalid", "source_amount", "source amount must be a positive exact decimal"⟩⟩
  diagnostics ∾↩ AddIf ⟨0<FractionDigits request.source_amount, Diagnostic ⟨"source_amount_precision_invalid", "source_amount", "JPY source amount must have zero fractional digits"⟩⟩
  diagnostics ∾↩ AddIf ⟨¬IsPositive targetParsed, Diagnostic ⟨"target_amount_invalid", "target_amount", "target amount must be a positive exact decimal"⟩⟩
  diagnostics ∾↩ AddIf ⟨2<FractionDigits request.target_amount, Diagnostic ⟨"target_amount_precision_invalid", "target_amount", "ILS target amount must have at most two fractional digits"⟩⟩
  diagnostics ∾↩ AddIf ⟨¬IsSafeText request.exchange_id, Diagnostic ⟨"exchange_id_invalid", "exchange_id", "exchange id must be nonempty and TSV-field safe"⟩⟩
  unsafeExisting ← ∨´0∾(¬IsSafeText¨request.existing_exchange_ids)
  diagnostics ∾↩ AddIf ⟨unsafeExisting, Diagnostic ⟨"existing_exchange_id_invalid", "existing_exchange_ids", "existing exchange ids must be nonempty and TSV-field safe"⟩⟩
  existingUnique ← (≠request.existing_exchange_ids)=≠⍷request.existing_exchange_ids
  diagnostics ∾↩ AddIf ⟨¬existingUnique, Diagnostic ⟨"existing_exchange_id_duplicate", "existing_exchange_ids", "existing exchange ids must be unique"⟩⟩
  duplicate ← ∨´0∾request.exchange_id⊸≡¨request.existing_exchange_ids
  diagnostics ∾↩ AddIf ⟨duplicate, Diagnostic ⟨"exchange_id_duplicate", "exchange_id", "exchange id already exists"⟩⟩
  diagnostics ∾↩ AddIf ⟨request.trip_id≢"israel-2026", Diagnostic ⟨"trip_id_invalid", "trip_id", "trip id must be israel-2026"⟩⟩
  previews ← empty
  {𝕊: previews ↩ ⟨Preview request⟩}⍟(0=≠diagnostics) @
  {state⇐(0=≠diagnostics)⊑"error"‿"ok", diagnostics⇐diagnostics, preview_events⇐previews}
}

ExtractRequest ← {𝕊 request:
  sourceAccount ← request.source_account
  targetAccount ← request.target_account
  normalizedSource ← {name⇐sourceAccount.name, exists⇐sourceAccount.exists, currency⇐sourceAccount.currency}
  normalizedTarget ← {name⇐targetAccount.name, exists⇐targetAccount.exists, currency⇐targetAccount.currency}
  value ← {
    date⇐request.date, memo⇐request.memo,
    source_account⇐normalizedSource,
    source_amount⇐request.source_amount, source_currency⇐request.source_currency,
    target_account⇐normalizedTarget,
    target_amount⇐request.target_amount, target_currency⇐request.target_currency,
    exchange_id⇐request.exchange_id, trip_id⇐request.trip_id,
    existing_exchange_ids⇐request.existing_exchange_ids
  }
  {ok⇐1, value⇐value}
}⎊{𝕩⋄{ok⇐0, value⇐empty}}

ValidateAndPreview ← {𝕊 request:
  extracted ← ExtractRequest request
  shapeDiagnostic ← Diagnostic ⟨"request_shape_invalid", "request", "request is missing required members"⟩
  result ← {state⇐"error", diagnostics⇐⟨shapeDiagnostic⟩, preview_events⇐empty}
  {𝕊: result ↩ ValidateExtracted extracted.value}⍟extracted.ok @
  result
}

Fields ← {𝕊 request:
  ⟨request.date, request.memo, request.source_account.name, request.source_amount, request.source_currency,
   request.target_account.name, request.target_amount, request.target_currency, request.exchange_id, request.trip_id⟩
}
Render ← {𝕊 request:
  fields ← Fields request
  ∾({𝕩∾tab}¨¯1↓fields)∾⟨¯1⊑fields⟩
}
ResolveAccount ← {𝕊 accounts‿name:
  names ← {𝕩.name}¨accounts
  idx ← ⊑names⊐⟨name⟩
  (idx<≠accounts) ◶ ⟨{𝕩⋄{name⇐name, exists⇐0, currency⇐""}}, {𝕩⋄idx⊑accounts}⟩ @
}
RequestFromFields ← {𝕊 fields‿accounts‿existingIds:
  {date⇐0⊑fields, memo⇐1⊑fields,
   source_account⇐ResolveAccount ⟨accounts, 2⊑fields⟩, source_amount⇐3⊑fields, source_currency⇐4⊑fields,
   target_account⇐ResolveAccount ⟨accounts, 5⊑fields⟩, target_amount⇐6⊑fields, target_currency⇐7⊑fields,
   exchange_id⇐8⊑fields, trip_id⇐9⊑fields, existing_exchange_ids⇐existingIds}
}
ParseExisting ← {𝕊 lines‿accounts:
  diagnostics ← empty
  requests ← empty
  {𝕊 line:
    fields ← tab util.SplitKeepEmpty line
    {𝕊:
      request ← RequestFromFields ⟨fields, accounts, ⟨⟩⟩
      result ← ValidateAndPreview request
      diagnostics ∾↩ result.diagnostics
      requests ∾↩ (result.state≡"ok")/⟨request⟩
    }⍟(10=≠fields) @
    diagnostics ∾↩ AddIf ⟨10≠≠fields, Diagnostic ⟨"existing_row_shape_invalid", "existing_source", "existing data row must contain exactly ten columns"⟩⟩
  }¨lines
  ids ← {𝕩.exchange_id}¨requests
  diagnostics ∾↩ AddIf ⟨(≠ids)≠≠⍷ids, Diagnostic ⟨"existing_exchange_id_duplicate", "existing_source", "existing exchange ids must be unique"⟩⟩
  {state⇐(0=≠diagnostics)⊑"error"‿"ok", diagnostics⇐diagnostics, requests⇐requests, ids⇐ids}
}
ValidateExisting ← {𝕊 lines‿accounts:
  parsed ← ParseExisting ⟨lines, accounts⟩
  {state⇐parsed.state, diagnostics⇐parsed.diagnostics, event_count⇐≠parsed.requests}
}
ValidateSourceAndPreview ← {𝕊 request:
  parsed ← ParseExisting ⟨request.existing_lines, request.accounts⟩
  candidate ← RequestFromFields ⟨request.candidate_fields, request.accounts, parsed.ids⟩
  candidateResult ← ValidateAndPreview candidate
  diagnostics ← parsed.diagnostics∾candidateResult.diagnostics
  rows ← empty
  events ← empty
  {𝕊: rows↩⟨Render candidate⟩ ⋄ events↩candidateResult.preview_events}⍟(0=≠diagnostics) @
  {state⇐(0=≠diagnostics)⊑"error"‿"ok", diagnostics⇐diagnostics, preview_rows⇐rows, preview_events⇐events}
}

{ValidateAndPreview⇐ValidateAndPreview, ValidateExisting⇐ValidateExisting, ValidateSourceAndPreview⇐ValidateSourceAndPreview, Render⇐Render}
