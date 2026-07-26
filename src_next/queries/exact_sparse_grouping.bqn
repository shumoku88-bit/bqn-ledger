# exact_sparse_grouping.bqn
# I/O-free exact grouping over explicit keys and already-admitted exact values.
#
# The kernel is deliberately unaware of accounting axes, commodities, scales,
# valuation, and source provenance. Callers must partition incompatible arithmetic
# domains before grouping or include the domain in each exact key.
#
# Output order is deterministic: groups retain first-occurrence key order.
# ContributorIndices is a separate sidecar helper so numeric grouped facts do not
# become the owner of posting identity or other source evidence.

empty ← ⟨⟩

Sum0 ← { 0 < ≠𝕩 ? +´𝕩 ; 0 }
Contains ← {𝕊 item‿items: ∨´ 0 ∾ item⊸≡¨ items }

ReplaceAt ← {𝕊 values‿index‿value:
  (index ↑ values) ∾ ⟨value⟩ ∾ (index + 1) ↓ values
}

Failure ← {𝕊 messageText:
  {
    state         ⇐ "error",
    keys          ⇐ empty,
    values        ⇐ empty,
    input_count   ⇐ 0,
    grouped_count ⇐ 0,
    input_total   ⇐ 0,
    grouped_total ⇐ 0,
    conserved     ⇐ 0,
    order         ⇐ "first_occurrence",
    message       ⇐ messageText
  }
}

Group ← {𝕊 keys‿values:
  result ← Failure "key and value counts differ"

  {𝕊:
    inputCount ← ≠ keys
    groupedKeys ← empty
    groupedValues ← empty

    {𝕊 index:
      key ← index ⊑ keys
      value ← index ⊑ values
      found ← Contains ⟨key, groupedKeys⟩

      {𝕊:
        groupedKeys ∾↩ ⟨key⟩
        groupedValues ∾↩ ⟨value⟩
      }⍟(¬ found) @

      {𝕊:
        groupIndex ← ⊑ (key⊸≡¨ groupedKeys) / ↕ ≠ groupedKeys
        groupedValue ← (groupIndex ⊑ groupedValues) + value
        groupedValues ↩ ReplaceAt ⟨groupedValues, groupIndex, groupedValue⟩
      }⍟found @
    }¨ ↕ inputCount

    inputTotal ← Sum0 values
    groupedTotal ← Sum0 groupedValues
    result ↩ {
      state         ⇐ "ok",
      keys          ⇐ groupedKeys,
      values        ⇐ groupedValues,
      input_count   ⇐ inputCount,
      grouped_count ⇐ ≠ groupedKeys,
      input_total   ⇐ inputTotal,
      grouped_total ⇐ groupedTotal,
      conserved     ⇐ inputTotal = groupedTotal,
      order         ⇐ "first_occurrence",
      message       ⇐ ""
    }
  }⍟((≠ keys) = ≠ values) @

  result
}

ContributorIndices ← {𝕊 inputKeys‿groupedKeys:
  {𝕊 key: (key⊸≡¨ inputKeys) / ↕ ≠ inputKeys }¨ groupedKeys
}

{
  Sum0              ⇐ Sum0,
  Group             ⇐ Group,
  ContributorIndices ⇐ ContributorIndices
}
