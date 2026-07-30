# Analysis-only private-kernel candidate for src/accounting/sparse_group.bqn.
# Public Build shape, diagnostics, exact reduction, and fail-closed publication mirror production.
# Only the admitted grouping block uses classify-once plus Group.

scale ← •Import "../../src/ledger/exact_scale.bqn"
empty ← ⟨⟩

Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}
IndexOf ← {𝕊 item‿items: ⊑(item⊸≡¨items)⊐1}
Diagnostic ← {𝕊 codeText‿messageText:
  {severity⇐"error",stage⇐"accounting_sparse_group",code⇐codeText,message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}
EmptyGroups ← {𝕊:
  {count⇐0,index⇐empty,row_index⇐empty,column_index⇐empty,coefficient⇐empty,contributors⇐empty}
}

# Private admitted kernel. Inputs have already passed alignment, axis, coordinate,
# column, and contributor validation. Exact reduction may still fail.
GroupAdmitted ← {𝕊 rowAxis‿columnCount‿rowCoordinates‿columnIndices‿coefficients‿contributors:
  rowIndices ← {IndexOf ⟨𝕩,rowAxis⟩}¨rowCoordinates
  cellCount ← columnCount×≠rowAxis
  cellIndices ← (columnCount×rowIndices)+columnIndices

  # Appending cellCount forces Group to publish every possible cell coordinate,
  # including a completely empty destination. The extra index has no matching item.
  forcedGroupIndices ← cellIndices∾cellCount
  coefficientGroups ← forcedGroupIndices⊔coefficients
  nestedContributorGroups ← forcedGroupIndices⊔contributors

  occupied ← 0<≠¨coefficientGroups
  occupiedCells ← occupied/↕cellCount
  occupiedCoefficientGroups ← occupied/coefficientGroups
  occupiedContributorGroups ← occupied/nestedContributorGroups
  summed ← scale.Sum¨occupiedCoefficientGroups

  ⟨occupiedCells,occupiedContributorGroups,summed⟩
}

# Input: row axis, column count, row coordinate/item, column index/item,
# exact coefficient/item, contributor-index-array/item.
Build ← {𝕊 rowAxis‿columnCount‿rowCoordinates‿columnIndices‿coefficients‿contributors:
  diagnostics ← empty
  lengths ← ≠¨⟨rowCoordinates,columnIndices,coefficients,contributors⟩
  aligned ← ∧´(≠rowCoordinates)=lengths
  diagnostics ∾↩ AddIf ⟨¬aligned,Diagnostic ⟨"group_columns_misaligned","group input columns must align"⟩⟩
  diagnostics ∾↩ AddIf ⟨(≠rowAxis)≠≠⍷rowAxis,Diagnostic ⟨"group_row_axis_duplicate","row axis coordinates must be unique"⟩⟩
  columnCountInvalid ← (columnCount<0) ∨ columnCount≠⌊columnCount
  diagnostics ∾↩ AddIf ⟨columnCountInvalid,Diagnostic ⟨"group_column_count_invalid","column count must be a nonnegative integer"⟩⟩
  {𝕊:
    diagnostics ∾↩ AddIf ⟨∨´0∾{¬Contains ⟨𝕩,rowAxis⟩}¨rowCoordinates,Diagnostic ⟨"group_row_coordinate_unknown","every item row coordinate must occur in the row axis"⟩⟩
    columnInvalid ← ∨´0∾{(𝕩<0) ∨ (𝕩≥columnCount) ∨ 𝕩≠⌊𝕩}¨columnIndices
    diagnostics ∾↩ AddIf ⟨columnInvalid,Diagnostic ⟨"group_column_index_invalid","every item column index must be in bounds"⟩⟩
    diagnostics ∾↩ AddIf ⟨∨´0∾{0=≠𝕩}¨contributors,Diagnostic ⟨"group_contributors_missing","every selected item must retain contributors"⟩⟩
  }⍟aligned @

  groups ← EmptyGroups @
  {𝕊:
    occupiedCells‿occupiedContributorGroups‿summed ← GroupAdmitted ⟨
      rowAxis,columnCount,rowCoordinates,columnIndices,coefficients,contributors
    ⟩
    diagnostics ∾↩ ∾{𝕊 result:
      AddIf ⟨result.state≢"ok",Diagnostic ⟨"group_sum_failed","group sum exceeds exact range"⟩⟩
    }¨summed
    {𝕊:
      rows ← {⌊𝕩÷columnCount}¨occupiedCells
      columns ← columnCount|occupiedCells
      groups↩{
        count⇐≠occupiedCells,index⇐↕≠occupiedCells,
        row_index⇐rows,column_index⇐columns,
        coefficient⇐{𝕩.coefficient}¨summed,
        contributors⇐∾¨occupiedContributorGroups
      }
    }⍟(0=≠diagnostics) @
  }⍟(0=≠diagnostics) @

  state ← (0=≠diagnostics)⊑"error"‿"ok"
  {state⇐state,groups⇐groups,diagnostics⇐diagnostics}
}

{Build⇐Build}
