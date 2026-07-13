#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
exchange ← •Import "../src_next/travel_exchange_event.bqn"

tab ← @+9
lf ← @+10
Account ← {𝕊 name‿exists‿currency: {name⇐name, exists⇐exists, currency⇐currency} }
Request ← {𝕊 date‿memo‿sourceAccount‿sourceAmount‿sourceCurrency‿targetAccount‿targetAmount‿targetCurrency‿exchangeId‿tripId‿existingIds:
  {date⇐date, memo⇐memo, source_account⇐sourceAccount, source_amount⇐sourceAmount, source_currency⇐sourceCurrency,
   target_account⇐targetAccount, target_amount⇐targetAmount, target_currency⇐targetCurrency,
   exchange_id⇐exchangeId, trip_id⇐tripId, existing_exchange_ids⇐existingIds}
}
Source ← {𝕊: Account ⟨"assets:bank-jpy", 1, "JPY"⟩ }
Target ← {𝕊: Account ⟨"assets:cash-ils", 1, "ILS"⟩ }
Valid ← {𝕊: Request ⟨"2026-07-20", "airport exchange", Source @, "10000", "JPY", Target @, "250.00", "ILS", "israel-2026-exchange-0001", "israel-2026", ⟨⟩⟩ }

accepted ← exchange.ValidateAndPreview Valid @
"ok" lib.AssertEq accepted.state
0 lib.AssertEq ≠accepted.diagnostics
1 lib.AssertEq ≠accepted.preview_events
preview ← ⊑accepted.preview_events
"ok" lib.AssertEq preview.state
"10000" lib.AssertEq preview.source_amount
"JPY" lib.AssertEq preview.source_currency
"250.00" lib.AssertEq preview.target_amount
"ILS" lib.AssertEq preview.target_currency
"israel-2026-exchange-0001" lib.AssertEq preview.exchange_id
"israel-2026" lib.AssertEq preview.trip_id

CheckRejected ← {𝕊 request:
  result ← exchange.ValidateAndPreview request
  "error" lib.AssertEq result.state
  0 lib.AssertEq ≠result.preview_events
  lib.Assert 0<≠result.diagnostics
  result
}
shape ← CheckRejected {date⇐"private-date", memo⇐"private-memo"}
"request_shape_invalid" lib.AssertEq (⊑shape.diagnostics).code
CheckRejected Request ⟨"bad", "memo", Source @, "100", "JPY", Target @, "2", "ILS", "id", "israel-2026", ⟨⟩⟩
CheckRejected Request ⟨"2026-07-20", "bad"∾tab∾"memo", Source @, "100", "JPY", Target @, "2", "ILS", "id", "israel-2026", ⟨⟩⟩
CheckRejected Request ⟨"2026-07-20", "memo", Source @, "100", "ILS", Target @, "2", "ILS", "id", "israel-2026", ⟨⟩⟩
CheckRejected Request ⟨"2026-07-20", "memo", Source @, "100", "ILS", Target @, "2", "JPY", "id", "israel-2026", ⟨⟩⟩
CheckRejected Request ⟨"2026-07-20", "memo", Account ⟨"unknown", 0, "JPY"⟩, "100", "JPY", Target @, "2", "ILS", "id", "israel-2026", ⟨⟩⟩
CheckRejected Request ⟨"2026-07-20", "memo", Source @, "100", "JPY", Account ⟨"unknown", 0, "ILS"⟩, "2", "ILS", "id", "israel-2026", ⟨⟩⟩
CheckRejected Request ⟨"2026-07-20", "memo", Account ⟨"wrong", 1, "ILS"⟩, "100", "JPY", Target @, "2", "ILS", "id", "israel-2026", ⟨⟩⟩
CheckRejected Request ⟨"2026-07-20", "memo", Source @, "100", "JPY", Account ⟨"wrong", 1, "JPY"⟩, "2", "ILS", "id", "israel-2026", ⟨⟩⟩
CheckRejected Request ⟨"2026-07-20", "memo", Source @, "100", "JPY", Account ⟨"assets:bank-jpy", 1, "ILS"⟩, "2", "ILS", "id", "israel-2026", ⟨⟩⟩
{𝕩 ⋄ CheckRejected Request ⟨"2026-07-20", "memo", Source @, 𝕩, "JPY", Target @, "2", "ILS", "id", "israel-2026", ⟨⟩⟩}¨ ⟨"0", "-1", "12x", "1.5"⟩
{𝕩 ⋄ CheckRejected Request ⟨"2026-07-20", "memo", Source @, "100", "JPY", Target @, 𝕩, "ILS", "id", "israel-2026", ⟨⟩⟩}¨ ⟨"0", "-1", "12x", "1.001"⟩
CheckRejected Request ⟨"2026-07-20", "memo", Source @, "100", "JPY", Target @, "2", "ILS", "", "israel-2026", ⟨⟩⟩
CheckRejected Request ⟨"2026-07-20", "memo", Source @, "100", "JPY", Target @, "2", "ILS", "id"∾lf∾"bad", "israel-2026", ⟨⟩⟩
duplicate ← CheckRejected Request ⟨"2026-07-20", "memo", Source @, "100", "JPY", Target @, "2", "ILS", "id", "israel-2026", ⟨"other", "id"⟩⟩
"exchange_id_duplicate" lib.AssertEq (¯1⊑duplicate.diagnostics).code
CheckRejected Request ⟨"2026-07-20", "memo", Source @, "100", "JPY", Target @, "2", "ILS", "id", "other", ⟨⟩⟩

# The structured contract contains observations, not a rate or journal row.
1 lib.AssertEq ({𝕩.rate ⋄ 0}⎊{𝕩⋄1}) preview
1 lib.AssertEq ({𝕩.journal_row ⋄ 0}⎊{𝕩⋄1}) preview
lib.Assert preview.source_amount ≢ preview.target_amount

# Diagnostics are fixed and privacy-safe.
privacy ← CheckRejected Request ⟨"private-date", "Private Memo"∾tab∾"x", Account ⟨"private-source", 0, "ILS"⟩, "987x", "ILS", Account ⟨"private-target", 0, "JPY"⟩, "654x", "JPY", "private-id"∾lf∾"x", "private-trip", ⟨⟩⟩
messages ← ∾({𝕩.message∾"\n"}¨privacy.diagnostics)
{𝕩 ⋄ 0 lib.AssertEq ∨´𝕩⍷messages}¨ ⟨"private-date", "Private Memo", "private-source", "private-target", "987x", "654x", "private-id", "private-trip"⟩

•Out "test_src_next_travel_exchange_event.bqn: OK"
