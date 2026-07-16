#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
sections ← •Import "../src_next/report_sections.bqn"
builder_order ← •Import "../src_next/report_builder_order.bqn"

Contains ← {𝕊 haystack‿needle: ∨´ needle ⍷ haystack }
MkEntry ← {⟨𝕩, "builder:"∾𝕩⟩}
keys ← {0⊑𝕩}¨ sections.rows
normal ← MkEntry¨ keys

# Duplicate detection compares adjacent key strings, not characters within keys.
⟨"a"⟩ lib.AssertEq builder_order.DuplicateKeys ⟨"a", "a", "b"⟩
⟨"b"⟩ lib.AssertEq builder_order.DuplicateKeys ⟨"a", "b", "b"⟩
⟨⟩ lib.AssertEq builder_order.DuplicateKeys ⟨"a", "b", "c"⟩
⟨⟩ lib.AssertEq builder_order.DuplicateKeys ⟨⟩
⟨⟩ lib.AssertEq builder_order.DuplicateKeys ⟨"a"⟩

# Normal 15 builders succeed; valid reordered input returns descriptor order.
normal_result ← builder_order.OrderBuilderEntries ⟨sections.rows, normal⟩
lib.Assert normal_result.valid
keys lib.AssertEq {0⊑𝕩}¨ normal_result.ordered_entries
reordered_result ← builder_order.OrderBuilderEntries ⟨sections.rows, ⌽normal⟩
lib.Assert reordered_result.valid
keys lib.AssertEq {0⊑𝕩}¨ reordered_result.ordered_entries

# Missing builder fails closed with key and count evidence.
missing_result ← builder_order.OrderBuilderEntries ⟨sections.rows, ¯1↓normal⟩
lib.Assert ¬missing_result.valid
⟨"debug"⟩ lib.AssertEq missing_result.missing_keys
lib.Assert missing_result.count_mismatch
lib.Assert Contains ⟨missing_result.message, "missing=debug"⟩

# Duplicate builder is detected directly; count mismatch is also visible.
duplicate_result ← builder_order.OrderBuilderEntries ⟨sections.rows, normal∾⟨MkEntry "snapshot"⟩⟩
lib.Assert ¬duplicate_result.valid
⟨"snapshot"⟩ lib.AssertEq duplicate_result.duplicate_keys
lib.Assert duplicate_result.count_mismatch
lib.Assert Contains ⟨duplicate_result.message, "duplicate=snapshot"⟩
lib.Assert Contains ⟨duplicate_result.message, "expected_count=15"⟩
lib.Assert Contains ⟨duplicate_result.message, "actual_count=16"⟩

# Extra builder and count mismatch are both reported.
extra_result ← builder_order.OrderBuilderEntries ⟨sections.rows, normal∾⟨MkEntry "extra"⟩⟩
lib.Assert ¬extra_result.valid
⟨"extra"⟩ lib.AssertEq extra_result.extra_keys
lib.Assert extra_result.count_mismatch
lib.Assert Contains ⟨extra_result.message, "extra=extra"⟩

# Duplicate + missing at equal count preserves both causes.
duplicate_missing_input ← (¯1↓normal)∾⟨MkEntry "snapshot"⟩
duplicate_missing ← builder_order.OrderBuilderEntries ⟨sections.rows, duplicate_missing_input⟩
lib.Assert ¬duplicate_missing.valid
⟨"snapshot"⟩ lib.AssertEq duplicate_missing.duplicate_keys
⟨"debug"⟩ lib.AssertEq duplicate_missing.missing_keys
lib.Assert ¬duplicate_missing.count_mismatch
lib.Assert Contains ⟨duplicate_missing.message, "duplicate=snapshot"⟩
lib.Assert Contains ⟨duplicate_missing.message, "missing=debug"⟩

# Extra + missing at equal count preserves both causes.
extra_missing_input ← (¯1↓normal)∾⟨MkEntry "extra"⟩
extra_missing ← builder_order.OrderBuilderEntries ⟨sections.rows, extra_missing_input⟩
lib.Assert ¬extra_missing.valid
⟨"extra"⟩ lib.AssertEq extra_missing.extra_keys
⟨"debug"⟩ lib.AssertEq extra_missing.missing_keys
lib.Assert ¬extra_missing.count_mismatch
lib.Assert Contains ⟨extra_missing.message, "extra=extra"⟩
lib.Assert Contains ⟨extra_missing.message, "missing=debug"⟩

•Out "test_src_next_report_builder_order.bqn: OK"
