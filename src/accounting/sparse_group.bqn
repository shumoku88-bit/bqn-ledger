# Deterministic two-coordinate sparse Group over already-selected exact evidence.
# Row-axis order and column count are explicit; each input item retains contributors.

scale ← •Import "../ledger/exact_scale.bqn"
empty ← ⟨⟩

Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}
Unique ← {𝕊 items:
  result ← empty
  {𝕊 item: {𝕊: result∾↩⟨item⟩}⍟(¬Contains ⟨item,result⟩) @}¨items
  result
}
Diagnostic ← {𝕊 codeText‿messageText:
  {severity⇐"error",stage⇐"accounting_sparse_group",code⇐codeText,message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}
EmptyGroups ← {𝕊:
  {count⇐0,index⇐empty,row_index⇐empty,column_index⇐empty,coefficient⇐empty,contributors⇐empty}
}

# Input: row axis, column count, row coordinate/item, column index/item,
# exact coefficient/item, contributor-index-array/item.
Build ← {𝕊 rowAxis‿columnCount‿rowCoordinates‿columnIndices‿coefficients‿contributors:
  diagnostics ← empty
  lengths ← ≠¨⟨rowCoordinates,columnIndices,coefficients,contributors⟩
  aligned ← ∧´(≠rowCoordinates)=lengths
  diagnostics ∾↩ AddIf ⟨¬aligned,Diagnostic ⟨"group_columns_misaligned","group input columns must align"⟩⟩
  diagnostics ∾↩ AddIf ⟨(≠rowAxis)≠≠Unique rowAxis,Diagnostic ⟨"group_row_axis_duplicate","row axis coordinates must be unique"⟩⟩
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
    candidate ← empty
    {𝕊 rowIndex:
      coordinate ← rowIndex⊑rowAxis
      {𝕊 columnIndex:
        mask ← (coordinate⊸≡¨rowCoordinates) ∧ columnIndex=columnIndices
        selected ← mask/coefficients
        {𝕊:
          summed ← scale.Sum selected
          diagnostics ∾↩ AddIf ⟨summed.state≢"ok",Diagnostic ⟨"group_sum_failed","group sum exceeds exact range"⟩⟩
          {𝕊:
            selectedContributors ← mask/contributors
            candidate∾↩⟨{
              row_index⇐rowIndex,column_index⇐columnIndex,
              coefficient⇐summed.coefficient,contributors⇐∾selectedContributors
            }⟩
          }⍟(summed.state≡"ok") @
        }⍟(0<≠selected) @
      }¨↕columnCount
    }¨↕≠rowAxis
    {𝕊:
      groups↩{
        count⇐≠candidate,index⇐↕≠candidate,
        row_index⇐{𝕩.row_index}¨candidate,column_index⇐{𝕩.column_index}¨candidate,
        coefficient⇐{𝕩.coefficient}¨candidate,contributors⇐{𝕩.contributors}¨candidate
      }
    }⍟(0=≠diagnostics) @
  }⍟(0=≠diagnostics) @

  state ← (0=≠diagnostics)⊑"error"‿"ok"
  {state⇐state,groups⇐groups,diagnostics⇐diagnostics}
}

{Build⇐Build}
