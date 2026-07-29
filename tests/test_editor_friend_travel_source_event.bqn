#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
source ← •Import "../src/editor/friend_travel_source_event.bqn"

tab ← @+9
lf ← @+10

Event ← {𝕊 date‿party‿item‿amount‿currency‿payer‿trip‿id‿status:
  {date⇐date, party⇐party, item_or_category⇐item, original_amount⇐amount,
   original_currency⇐currency, payer⇐payer, trip_id⇐trip, source_event_id⇐id, status⇐status}
}
Valid ← {𝕊: Event ⟨"2026-07-20", "Synthetic Friend", "meal", "42.50", "ILS", "friend", "israel-2026", "israel-2026-friend-0001", "pending"⟩ }
Request ← {𝕊 event‿lines: {event⇐event, existing_lines⇐lines} }

accepted ← source.ValidateAndPreview Request ⟨Valid @, ⟨⟩⟩
"ok" lib.AssertEq accepted.state
0 lib.AssertEq ≠accepted.diagnostics
1 lib.AssertEq ≠accepted.preview_rows
("2026-07-20"∾tab∾"Synthetic Friend"∾tab∾"meal"∾tab∾"42.50"∾tab∾"ILS"∾tab∾"friend"∾tab∾"israel-2026"∾tab∾"israel-2026-friend-0001"∾tab∾"pending") lib.AssertEq ⊑accepted.preview_rows

CheckRejected ← {𝕊 event‿lines:
  result ← source.ValidateAndPreview Request ⟨event, lines⟩
  "error" lib.AssertEq result.state
  0 lib.AssertEq ≠result.preview_rows
  lib.Assert 0 < ≠result.diagnostics
  result
}

CheckRejected ⟨Event ⟨"2026-02-30", "Friend", "meal", "1", "ILS", "friend", "israel-2026", "id", "pending"⟩, ⟨⟩⟩
CheckRejected ⟨Event ⟨"2026-07-20", "Friend", "meal", "0", "ILS", "friend", "israel-2026", "id", "pending"⟩, ⟨⟩⟩
CheckRejected ⟨Event ⟨"2026-07-20", "Friend", "meal", "1.001", "ILS", "friend", "israel-2026", "id", "pending"⟩, ⟨⟩⟩
CheckRejected ⟨Event ⟨"2026-07-20", "Friend", "meal", "1", "JPY", "friend", "israel-2026", "id", "pending"⟩, ⟨⟩⟩
CheckRejected ⟨Event ⟨"2026-07-20", "Friend", "meal", "1", "ILS", "self", "israel-2026", "id", "pending"⟩, ⟨⟩⟩
CheckRejected ⟨Event ⟨"2026-07-20", "Friend", "meal", "1", "ILS", "friend", "other", "id", "pending"⟩, ⟨⟩⟩
CheckRejected ⟨Event ⟨"2026-07-20", "Friend"∾tab∾"bad", "meal", "1", "ILS", "friend", "israel-2026", "id", "pending"⟩, ⟨⟩⟩
CheckRejected ⟨Event ⟨"2026-07-20", "Friend", "meal"∾lf∾"bad", "1", "ILS", "friend", "israel-2026", "id", "pending"⟩, ⟨⟩⟩
CheckRejected ⟨Event ⟨"2026-07-20", "Friend", "meal", "1", "ILS", "friend", "israel-2026", "", "pending"⟩, ⟨⟩⟩
CheckRejected ⟨Event ⟨"2026-07-20", "Friend", "meal", "1", "ILS", "friend", "israel-2026", "id", "done"⟩, ⟨⟩⟩

line ← ⊑accepted.preview_rows
duplicate ← CheckRejected ⟨Valid @, ⟨line⟩⟩
"source_event_id_duplicate" lib.AssertEq (¯1⊑duplicate.diagnostics).code
malformed ← CheckRejected ⟨Event ⟨"2026-07-21", "Friend", "other", "2", "ILS", "friend", "israel-2026", "id-2", "pending"⟩, ⟨"bad"∾tab∾"row"⟩⟩
"existing_row_shape_invalid" lib.AssertEq (⊑malformed.diagnostics).code
existingDuplicate ← source.ValidateExisting ⟨line, line⟩
"error" lib.AssertEq existingDuplicate.state

# Diagnostics expose fixed contracts, never source values.
privacy ← CheckRejected ⟨Event ⟨"private-date", "Private Party"∾tab∾"x", "Private Item"∾lf∾"x", "987x", "JPY", "self", "private-trip", "private-id", "done"⟩, ⟨⟩⟩
messages ← ∾({𝕩.message∾"\n"}¨privacy.diagnostics)
{𝕩 ⋄ 0 lib.AssertEq ∨´𝕩⍷messages}¨ ⟨"private-date", "Private Party", "Private Item", "987x", "private-trip", "private-id"⟩

•Out "test_editor_friend_travel_source_event: ok"
