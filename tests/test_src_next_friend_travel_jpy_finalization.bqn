#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
finalization ← •Import "../src_next/friend_travel_jpy_finalization.bqn"

tab ← @+9
cr ← @+13
lf ← @+10

Event ← {𝕊 date‿party‿item‿originalAmount‿originalCurrency‿payer‿tripId‿sourceId‿status:
  {
    date ⇐ date,
    party ⇐ party,
    item_or_category ⇐ item,
    original_amount ⇐ originalAmount,
    original_currency ⇐ originalCurrency,
    payer ⇐ payer,
    trip_id ⇐ tripId,
    source_event_id ⇐ sourceId,
    status ⇐ status
  }
}

Account ← {𝕊 name‿exists‿role‿currency:
  {name⇐name, exists⇐exists, role⇐role, currency⇐currency}
}

Request ← {𝕊 event‿finalizationDate‿jpyAmount‿liability‿expense‿existingIds:
  {
    event ⇐ event,
    finalization_date ⇐ finalizationDate,
    jpy_amount ⇐ jpyAmount,
    liability_account ⇐ liability,
    expense_account ⇐ expense,
    existing_finalization_ids ⇐ existingIds
  }
}

ValidEvent ← {𝕊:
  Event ⟨"2026-06-15", "Private Party", "Travel item", "125.50", "EUR", "friend", "trip-2026", "event-001", "pending"⟩
}
ValidLiability ← {𝕊: Account ⟨"liabilities:friend-JPY", 1, "liability", "JPY"⟩ }
ValidExpense ← {𝕊: Account ⟨"expenses:travel-JPY", 1, "expense", "JPY"⟩ }
ValidRequest ← {𝕊:
  Request ⟨ValidEvent @, "2026-07-13", "0012500", ValidLiability @, ValidExpense @, ⟨⟩⟩
}

CheckRejected ← {𝕊 request:
  result ← finalization.ValidateAndPreview request
  "error" lib.AssertEq result.state
  0 lib.AssertEq ≠ result.preview_rows
  lib.Assert 0 < ≠ result.diagnostics
  {𝕊 diagnostic:
    "error" lib.AssertEq diagnostic.severity
    "friend_travel_jpy_finalization" lib.AssertEq diagnostic.stage
    lib.Assert 0 < ≠ diagnostic.code
    lib.Assert 0 < ≠ diagnostic.field
    lib.Assert 0 < ≠ diagnostic.message
  }¨ result.diagnostics
  result
}

# Accepted pending event produces exactly one structured canonical JPY row.
accepted ← finalization.ValidateAndPreview ValidRequest @
"ok" lib.AssertEq accepted.state
0 lib.AssertEq ≠ accepted.diagnostics
1 lib.AssertEq ≠ accepted.preview_rows
row ← ⊑ accepted.preview_rows
"2026-07-13" lib.AssertEq row.date
"Private Party: Travel item" lib.AssertEq row.memo
"liabilities:friend-JPY" lib.AssertEq row.from_account
"expenses:travel-JPY" lib.AssertEq row.to_account
"12500" lib.AssertEq row.amount
⟨"currency=JPY", "source_event_id=event-001", "trip_id=trip-2026"⟩ lib.AssertEq row.metadata

# Purchase date remains source context; only the distinct finalization date is posted.
lib.Assert row.date ≢ (ValidEvent @).date

# Exactly one row and only the selected liability -> expense endpoints: no foreign,
# clearing, original-amount, or second-row preview is present.
1 lib.AssertEq ≠ accepted.preview_rows
lib.Assert ¬ ∨´ "clearing" ⍷ row.from_account ∾ row.to_account
lib.Assert ¬ ∨´ "EUR" ⍷ row.from_account ∾ row.to_account ∾ row.amount ∾ (∾row.metadata)
lib.Assert row.amount ≢ (ValidEvent @).original_amount

# Purchase and finalization dates are independently required and validated.
CheckRejected Request ⟨Event ⟨"", "Party", "Item", "1", "USD", "friend", "trip", "event", "pending"⟩, "2026-07-13", "1", ValidLiability @, ValidExpense @, ⟨⟩⟩
CheckRejected Request ⟨Event ⟨"2026-02-30", "Party", "Item", "1", "USD", "friend", "trip", "event", "pending"⟩, "2026-07-13", "1", ValidLiability @, ValidExpense @, ⟨⟩⟩
CheckRejected Request ⟨ValidEvent @, "", "1", ValidLiability @, ValidExpense @, ⟨⟩⟩
CheckRejected Request ⟨ValidEvent @, "2026-13-01", "1", ValidLiability @, ValidExpense @, ⟨⟩⟩

# Memo source fields reject empty and TSV-breaking characters.
{𝕩 ⋄ CheckRejected Request ⟨Event ⟨"2026-01-01", 𝕩, "Item", "1", "USD", "friend", "trip", "event", "pending"⟩, "2026-07-13", "1", ValidLiability @, ValidExpense @, ⟨⟩⟩}¨ ⟨"", "bad"∾tab∾"party", "bad"∾cr∾"party", "bad"∾lf∾"party"⟩
{𝕩 ⋄ CheckRejected Request ⟨Event ⟨"2026-01-01", "Party", 𝕩, "1", "USD", "friend", "trip", "event", "pending"⟩, "2026-07-13", "1", ValidLiability @, ValidExpense @, ⟨⟩⟩}¨ ⟨"", "bad"∾tab∾"item", "bad"∾cr∾"item", "bad"∾lf∾"item"⟩

# Original source facts: positive exact decimal and any uppercase ASCII currency token.
{𝕩 ⋄ CheckRejected Request ⟨Event ⟨"2026-01-01", "Party", "Item", 𝕩, "USD", "friend", "trip", "event", "pending"⟩, "2026-07-13", "1", ValidLiability @, ValidExpense @, ⟨⟩⟩}¨ ⟨"", "nope", "0", "0.00", "-1"⟩
{𝕩 ⋄ CheckRejected Request ⟨Event ⟨"2026-01-01", "Party", "Item", "1", 𝕩, "friend", "trip", "event", "pending"⟩, "2026-07-13", "1", ValidLiability @, ValidExpense @, ⟨⟩⟩}¨ ⟨"", "US", "usd", "US1", "US D"⟩
foreignCurrencyAccepted ← finalization.ValidateAndPreview Request ⟨Event ⟨"2026-01-01", "Party", "Item", "1", "CHF", "friend", "trip", "event", "pending"⟩, "2026-07-13", "2", ValidLiability @, ValidExpense @, ⟨⟩⟩
"ok" lib.AssertEq foreignCurrencyAccepted.state
"2" lib.AssertEq (⊑ foreignCurrencyAccepted.preview_rows).amount

# Consumer identity and state are exact.
CheckRejected Request ⟨Event ⟨"2026-01-01", "Party", "Item", "1", "USD", "self", "trip", "event", "pending"⟩, "2026-07-13", "1", ValidLiability @, ValidExpense @, ⟨⟩⟩
CheckRejected Request ⟨Event ⟨"2026-01-01", "Party", "Item", "1", "USD", "friend", "trip", "event", "finalized"⟩, "2026-07-13", "1", ValidLiability @, ValidExpense @, ⟨⟩⟩

# Provenance tokens are nonempty and reject whitespace, TSV controls, and '='.
unsafeTokens ← ⟨"", "two words", "bad"∾tab∾"id", "bad"∾cr∾"id", "bad"∾lf∾"id", "bad=id"⟩
{𝕩 ⋄ CheckRejected Request ⟨Event ⟨"2026-01-01", "Party", "Item", "1", "USD", "friend", "trip", 𝕩, "pending"⟩, "2026-07-13", "1", ValidLiability @, ValidExpense @, ⟨⟩⟩}¨ unsafeTokens
{𝕩 ⋄ CheckRejected Request ⟨Event ⟨"2026-01-01", "Party", "Item", "1", "USD", "friend", 𝕩, "event", "pending"⟩, "2026-07-13", "1", ValidLiability @, ValidExpense @, ⟨⟩⟩}¨ unsafeTokens

# JPY amount must parse exactly, be positive, and canonicalize at scale zero.
{𝕩 ⋄ CheckRejected Request ⟨ValidEvent @, "2026-07-13", 𝕩, ValidLiability @, ValidExpense @, ⟨⟩⟩}¨ ⟨"", "0", "0.00", "-1", "1.5", "12x"⟩

# Both explicit descriptors must already exist, use JPY, and have exact roles.
CheckRejected Request ⟨ValidEvent @, "2026-07-13", "1", Account ⟨"unknown", 0, "liability", "JPY"⟩, ValidExpense @, ⟨⟩⟩
CheckRejected Request ⟨ValidEvent @, "2026-07-13", "1", ValidLiability @, Account ⟨"unknown", 0, "expense", "JPY"⟩, ⟨⟩⟩
CheckRejected Request ⟨ValidEvent @, "2026-07-13", "1", Account ⟨"liability", 1, "liability", "USD"⟩, ValidExpense @, ⟨⟩⟩
CheckRejected Request ⟨ValidEvent @, "2026-07-13", "1", ValidLiability @, Account ⟨"expense", 1, "expense", "ILS"⟩, ⟨⟩⟩
CheckRejected Request ⟨ValidEvent @, "2026-07-13", "1", Account ⟨"liability", 1, "asset", "JPY"⟩, ValidExpense @, ⟨⟩⟩
CheckRejected Request ⟨ValidEvent @, "2026-07-13", "1", ValidLiability @, Account ⟨"expense", 1, "liability", "JPY"⟩, ⟨⟩⟩

# Any existing index entry rejects re-preview, regardless of other historical detail.
preExisting ← CheckRejected Request ⟨ValidEvent @, "2026-07-13", "1", ValidLiability @, ValidExpense @, ⟨"other", "event-001", "event-001"⟩⟩
"source_event_already_finalized" lib.AssertEq (¯1⊑preExisting.diagnostics).code

# Independent errors are collected in deterministic validation order.
multi ← CheckRejected Request ⟨Event ⟨"bad", "", "", "0", "usd", "self", "", "private-event", "done"⟩, "bad", "0", Account ⟨"private-liability", 0, "asset", "USD"⟩, Account ⟨"private-expense", 0, "asset", "USD"⟩, ⟨"private-event"⟩⟩
⟨"purchase_date_invalid", "finalization_date_invalid", "payer_invalid", "status_invalid"⟩ lib.AssertEq 4 ↑ ({𝕩.code}¨ multi.diagnostics)

# Diagnostic messages never reflect private memo, amounts, ids, currency, or account names.
privacy ← CheckRejected Request ⟨
  Event ⟨"private-date", "Private Party"∾tab∾"secret", "Private Item"∾lf∾"secret", "987654x", "ZZ1", "private-payer", "private trip", "private=event", "private-status"⟩,
  "private-finalization-date", "private-jpy", Account ⟨"private-liability", 0, "asset", "USD"⟩, Account ⟨"private-expense", 0, "asset", "ILS"⟩, ⟨"private=event"⟩
⟩
privateValues ← ⟨"private-date", "Private Party", "Private Item", "987654x", "ZZ1", "private-payer", "private trip", "private=event", "private-status", "private-finalization-date", "private-jpy", "private-liability", "private-expense"⟩
messages ← ∾ ({𝕩.message∾"\n"}¨ privacy.diagnostics)
{𝕩 ⋄ 0 lib.AssertEq ∨´ 𝕩 ⍷ messages}¨ privateValues

•Out "test_src_next_friend_travel_jpy_finalization.bqn: OK"
