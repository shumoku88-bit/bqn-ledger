# Deterministic two-coordinate sparse Group over already-selected exact evidence.
# Row-axis order and column count are explicit; each input item retains contributors.

scale ← •Import "../ledger/exact_scale.bqn"
empty ← ⟨⟩

Diagnostic ← {𝕊 codeText‿messageText:
  {severity⇐"error",stage⇐"accounting_sparse_group",code⇐codeText,message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}
EmptyGroups ← {𝕊:
  {count⇐0,index⇐empty,row_index⇐empty,column_index⇐empty,coefficient⇐empty,contributors⇐empty}
}

# Private kernel over admitted integer coordinates. Each item is already classified onto
# the explicit row axis; encode row × column once, then group coefficients and contributors.
GroupAdmitted ← {𝕊 rowCount‿columnCount‿rowIndices‿columnIndices‿coefficients‿contributors:
  cellCount ← columnCount×rowCount
  cellIndices ← (columnCount×rowIndices)+columnIndices

  # The unmatched trailing group index forces Group to represent the complete coordinate bound,
  # including empty axes, without adding an evidence item.
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
  rowIndices ← rowAxis⊐rowCoordinates
  diagnostics ∾↩ AddIf ⟨¬aligned,Diagnostic ⟨"group_columns_misaligned","group input columns must align"⟩⟩
  # Deduplicate compares opaque row-axis major cells and preserves first-occurrence order.
  diagnostics ∾↩ AddIf ⟨(≠rowAxis)≠≠⍷rowAxis,Diagnostic ⟨"group_row_axis_duplicate","row axis coordinates must be unique"⟩⟩
  columnCountInvalid ← (columnCount<0) ∨ columnCount≠⌊columnCount
  diagnostics ∾↩ AddIf ⟨columnCountInvalid,Diagnostic ⟨"group_column_count_invalid","column count must be a nonnegative integer"⟩⟩
  {𝕊:
    # Index Of's absent bound is the unknown-row sentinel and the admitted row coordinate.
    diagnostics ∾↩ AddIf ⟨∨´0∾(rowIndices=≠rowAxis),Diagnostic ⟨"group_row_coordinate_unknown","every item row coordinate must occur in the row axis"⟩⟩
    columnInvalid ← ∨´0∾((columnIndices<0) ∨ (columnIndices≥columnCount) ∨ columnIndices≠⌊columnIndices)
    diagnostics ∾↩ AddIf ⟨columnInvalid,Diagnostic ⟨"group_column_index_invalid","every item column index must be in bounds"⟩⟩
    diagnostics ∾↩ AddIf ⟨∨´0∾{0=≠𝕩}¨contributors,Diagnostic ⟨"group_contributors_missing","every selected item must retain contributors"⟩⟩
  }⍟aligned @

  groups ← EmptyGroups @
  {𝕊:
    occupiedCells‿occupiedContributorGroups‿summed ← GroupAdmitted ⟨
      ≠rowAxis,columnCount,rowIndices,columnIndices,coefficients,contributors
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
