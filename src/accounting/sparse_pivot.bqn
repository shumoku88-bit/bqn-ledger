# Policy-free dense Pivot over deterministic sparse Group coordinates.
# Axis coordinates are opaque admitted values; labels/format/sign policy stay outside.

empty ← ⟨⟩

Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}
Unique ← {𝕊 items:
  result ← empty
  {𝕊 item: {𝕊: result∾↩⟨item⟩}⍟(¬Contains ⟨item,result⟩) @}¨items
  result
}
Diagnostic ← {𝕊 codeText‿messageText:
  {severity⇐"error",stage⇐"accounting_sparse_pivot",code⇐codeText,message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}
EmptyMatrix ← {𝕊:
  {
    row_count⇐0,column_count⇐0,cell_count⇐0,
    row_index⇐empty,column_index⇐empty,row_coordinates⇐empty,column_coordinates⇐empty,
    scale⇐0,values⇐empty,contributors⇐empty
  }
}

# Input: explicit row coordinates, explicit column coordinates, exact value scale,
# and one sparse_group-compatible aligned group table.
Build ← {𝕊 rowCoordinates‿columnCoordinates‿valueScale‿groups:
  diagnostics ← empty
  diagnostics ∾↩ AddIf ⟨(≠rowCoordinates)≠≠Unique rowCoordinates,Diagnostic ⟨"pivot_row_axis_duplicate","row axis coordinates must be unique"⟩⟩
  diagnostics ∾↩ AddIf ⟨(≠columnCoordinates)≠≠Unique columnCoordinates,Diagnostic ⟨"pivot_column_axis_duplicate","column axis coordinates must be unique"⟩⟩
  scaleInvalid ← (valueScale<0) ∨ valueScale≠⌊valueScale
  diagnostics ∾↩ AddIf ⟨scaleInvalid,Diagnostic ⟨"pivot_scale_invalid","value scale must be a nonnegative integer"⟩⟩

  groupLengths ← ≠¨⟨groups.row_index,groups.column_index,groups.coefficient,groups.contributors⟩
  aligned ← (groups.count=≠groups.row_index) ∧ ∧´groups.count=groupLengths
  diagnostics ∾↩ AddIf ⟨¬aligned,Diagnostic ⟨"pivot_group_columns_misaligned","sparse Group columns must align with count"⟩⟩
  {𝕊:
    rowInvalid ← ∨´0∾{(𝕩<0) ∨ (𝕩≥≠rowCoordinates) ∨ 𝕩≠⌊𝕩}¨groups.row_index
    columnInvalid ← ∨´0∾{(𝕩<0) ∨ (𝕩≥≠columnCoordinates) ∨ 𝕩≠⌊𝕩}¨groups.column_index
    diagnostics ∾↩ AddIf ⟨rowInvalid,Diagnostic ⟨"pivot_row_index_invalid","sparse row indices must be in bounds"⟩⟩
    diagnostics ∾↩ AddIf ⟨columnInvalid,Diagnostic ⟨"pivot_column_index_invalid","sparse column indices must be in bounds"⟩⟩
    duplicate ← ∨´0∾{𝕊 i:
      r←i⊑groups.row_index ⋄ c←i⊑groups.column_index
      1<+´(r=groups.row_index) ∧ c=groups.column_index
    }¨↕groups.count
    diagnostics ∾↩ AddIf ⟨duplicate,Diagnostic ⟨"pivot_coordinate_duplicate","sparse Group must contain at most one item per coordinate"⟩⟩
  }⍟aligned @

  matrix ← EmptyMatrix @
  {𝕊:
    rowIndices ← ↕≠rowCoordinates
    columnIndices ← ↕≠columnCoordinates
    values ← {𝕊 rowIndex:
      {𝕊 columnIndex:
        matches ← ((rowIndex=groups.row_index) ∧ columnIndex=groups.column_index)/↕groups.count
        value ← 0
        {𝕊: value↩(⊑matches)⊑groups.coefficient}⍟(1=≠matches) @
        value
      }¨columnIndices
    }¨rowIndices
    contributors ← {𝕊 rowIndex:
      {𝕊 columnIndex:
        matches ← ((rowIndex=groups.row_index) ∧ columnIndex=groups.column_index)/↕groups.count
        cell ← empty
        {𝕊: cell↩(⊑matches)⊑groups.contributors}⍟(1=≠matches) @
        cell
      }¨columnIndices
    }¨rowIndices
    matrix↩{
      row_count⇐≠rowCoordinates,column_count⇐≠columnCoordinates,
      cell_count⇐(≠rowCoordinates)×≠columnCoordinates,
      row_index⇐rowIndices,column_index⇐columnIndices,
      row_coordinates⇐rowCoordinates,column_coordinates⇐columnCoordinates,
      scale⇐valueScale,values⇐values,contributors⇐contributors
    }
  }⍟(0=≠diagnostics) @

  state ← (0=≠diagnostics)⊑"error"‿"ok"
  {state⇐state,matrix⇐matrix,diagnostics⇐diagnostics}
}

{Build⇐Build}
