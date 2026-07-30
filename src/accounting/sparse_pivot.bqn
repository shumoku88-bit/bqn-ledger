# Policy-free dense Pivot over deterministic sparse Group coordinates.
# Axis coordinates are opaque admitted values; labels/format/sign policy stay outside.

matrixResult ← •Import "matrix_result.bqn"
empty ← ⟨⟩

Diagnostic ← {𝕊 codeText‿messageText:
  {severity⇐"error",stage⇐"accounting_sparse_pivot",code⇐codeText,message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}
EmptyMatrix ← {𝕊: (matrixResult.Build ⟨empty,empty,0,empty,empty⟩).matrix }

# Input: explicit row coordinates, explicit column coordinates, exact value scale,
# and one sparse_group-compatible aligned group table.
Build ← {𝕊 rowCoordinates‿columnCoordinates‿valueScale‿groups:
  diagnostics ← empty
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
    rowCount ← ≠rowCoordinates
    columnCount ← ≠columnCoordinates
    cellCount ← rowCount×columnCount

    # Encode each occupied sparse coordinate once. Index Of classifies every dense
    # destination cell as one Group item or the absent bound groups.count.
    groupCells ← (columnCount×groups.row_index)+groups.column_index
    groupLookup ← groupCells ⊐ ↕cellCount
    cells ← {𝕊 groupIndex:
      value ← 0
      cellContributors ← empty
      {𝕊:
        value↩groupIndex⊑groups.coefficient
        cellContributors↩groupIndex⊑groups.contributors
      }⍟(groupIndex<groups.count) @
      {value⇐value,contributors⇐cellContributors}
    }¨groupLookup

    valuesFlat ← {𝕩.value}¨cells
    contributorsFlat ← {𝕩.contributors}¨cells
    values ← {𝕊 rowIndex:
      ((columnCount×rowIndex)+↕columnCount)⊏valuesFlat
    }¨↕rowCount
    contributors ← {𝕊 rowIndex:
      ((columnCount×rowIndex)+↕columnCount)⊏contributorsFlat
    }¨↕rowCount

    built ← matrixResult.Build ⟨rowCoordinates,columnCoordinates,valueScale,values,contributors⟩
    diagnostics ∾↩ built.diagnostics
    {𝕊: matrix↩built.matrix}⍟(built.state≡"ok") @
  }⍟(0=≠diagnostics) @

  state ← (0=≠diagnostics)⊑"error"‿"ok"
  {state⇐state,matrix⇐matrix,diagnostics⇐diagnostics}
}

{Build⇐Build}
