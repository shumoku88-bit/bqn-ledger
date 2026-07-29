# Canonical presentation-neutral dense MatrixResult constructor.
# Coordinates are opaque; accounting, label, sign, and formatting policy stay outside.

empty ← ⟨⟩

Diagnostic ← {𝕊 codeText‿messageText:
  {severity⇐"error",stage⇐"accounting_matrix_result",code⇐codeText,message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}
EmptyMatrix ← {𝕊:
  {
    row_count⇐0,column_count⇐0,cell_count⇐0,
    row_index⇐empty,column_index⇐empty,row_coordinates⇐empty,column_coordinates⇐empty,
    scale⇐0,values⇐empty,contributors⇐empty
  }
}

# Input: row coordinates, column coordinates, exact value scale,
# dense value rows, dense contributor-index-array rows.
Build ← {𝕊 rowCoordinates‿columnCoordinates‿valueScale‿values‿contributors:
  diagnostics ← empty
  rowCount ← ≠rowCoordinates
  columnCount ← ≠columnCoordinates
  # Deduplicate compares opaque major cells and preserves their first occurrence.
  diagnostics ∾↩ AddIf ⟨rowCount≠≠⍷rowCoordinates,Diagnostic ⟨"matrix_row_axis_duplicate","row axis coordinates must be unique"⟩⟩
  diagnostics ∾↩ AddIf ⟨columnCount≠≠⍷columnCoordinates,Diagnostic ⟨"matrix_column_axis_duplicate","column axis coordinates must be unique"⟩⟩
  scaleInvalid ← (valueScale<0) ∨ valueScale≠⌊valueScale
  diagnostics ∾↩ AddIf ⟨scaleInvalid,Diagnostic ⟨"matrix_scale_invalid","value scale must be a nonnegative integer"⟩⟩
  rowsAligned ← (rowCount=≠values) ∧ rowCount=≠contributors
  diagnostics ∾↩ AddIf ⟨¬rowsAligned,Diagnostic ⟨"matrix_rows_misaligned","value and contributor rows must align with row axis"⟩⟩
  {𝕊:
    valueColumnsAligned ← ∧´1∾{(≠𝕩)=columnCount}¨values
    contributorColumnsAligned ← ∧´1∾{(≠𝕩)=columnCount}¨contributors
    diagnostics ∾↩ AddIf ⟨¬valueColumnsAligned,Diagnostic ⟨"matrix_value_columns_misaligned","every value row must align with column axis"⟩⟩
    diagnostics ∾↩ AddIf ⟨¬contributorColumnsAligned,Diagnostic ⟨"matrix_contributor_columns_misaligned","every contributor row must align with column axis"⟩⟩
  }⍟rowsAligned @

  # A successful matrix is constructed only after all admission diagnostics are absent.
  ok ← 0=≠diagnostics
  matrix ← {𝕊:
    {
      row_count⇐rowCount,column_count⇐columnCount,cell_count⇐rowCount×columnCount,
      row_index⇐↕rowCount,column_index⇐↕columnCount,
      row_coordinates⇐rowCoordinates,column_coordinates⇐columnCoordinates,
      scale⇐valueScale,values⇐values,contributors⇐contributors
    }
  }⍟ok EmptyMatrix @
  {state⇐ok⊑"error"‿"ok",matrix⇐matrix,diagnostics⇐diagnostics}
}

{Build⇐Build}
