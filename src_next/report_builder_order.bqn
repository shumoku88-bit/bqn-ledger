# report_builder_order.bqn — pure report builder/descriptor correspondence
#
# This production helper validates and orders report.bqn's executable builder
# entries. It owns no builders, rendering, ViewModels, CLI, config, or I/O.

Unique ← {𝕊 xs: ((xs ⊐ xs) = ↕≠xs) / xs }

DuplicateKeys ← {𝕊 keys:
  sorted ← (⍋keys) ⊏ keys
  adjacent_duplicates ← ((1↓sorted) ≡¨ (¯1↓sorted)) / 1↓sorted
  Unique adjacent_duplicates
}

JoinComma ← {𝕊 xs:
  out ← ""
  {𝕊 x:
    separator ← (0 = ≠out) ⊑ ⟨",", ""⟩
    out ↩ out ∾ separator ∾ x
  }¨ xs
  out
}

OrderBuilderEntries ← {𝕊 descriptor_rows‿builder_entries:
  descriptor_keys ← {0⊑𝕩}¨ descriptor_rows
  builder_keys ← {0⊑𝕩}¨ builder_entries
  duplicate_keys ← DuplicateKeys builder_keys
  missing_keys ← ({¬ ∨´ 𝕩⊸≡¨ builder_keys}¨ descriptor_keys) / descriptor_keys
  extra_keys ← Unique (({¬ ∨´ 𝕩⊸≡¨ descriptor_keys}¨ builder_keys) / builder_keys)
  expected_count ← ≠descriptor_keys
  actual_count ← ≠builder_keys
  count_mismatch ← expected_count ≠ actual_count
  valid ← (0 = ≠duplicate_keys) ∧ (0 = ≠missing_keys) ∧ (0 = ≠extra_keys) ∧ ¬ count_mismatch

  ordered_entries ← ⟨⟩
  {𝕊:
    ordered_entries ↩ {𝕊 key:
      idx ← ⊑ (builder_keys ⊐ ⟨key⟩)
      idx ⊑ builder_entries
    }¨ descriptor_keys
  }⍟valid @

  newline ← @+10
  message ← "ERROR: report section descriptor/builder mismatch" ∾ newline
  message ∾↩ "duplicate=" ∾ (JoinComma duplicate_keys) ∾ newline
  message ∾↩ "missing=" ∾ (JoinComma missing_keys) ∾ newline
  message ∾↩ "extra=" ∾ (JoinComma extra_keys) ∾ newline
  message ∾↩ "expected_count=" ∾ (•Fmt expected_count) ∾ newline
  message ∾↩ "actual_count=" ∾ (•Fmt actual_count)

  {
    valid ⇐ valid,
    duplicate_keys ⇐ duplicate_keys,
    missing_keys ⇐ missing_keys,
    extra_keys ⇐ extra_keys,
    expected_count ⇐ expected_count,
    actual_count ⇐ actual_count,
    count_mismatch ⇐ count_mismatch,
    ordered_entries ⇐ ordered_entries,
    message ⇐ message
  }
}

{ DuplicateKeys ⇐ DuplicateKeys, OrderBuilderEntries ⇐ OrderBuilderEntries }
