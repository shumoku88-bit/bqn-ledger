#!/usr/bin/env bqn

# Analysis-only probe for the complete src/accounting/sparse_group.bqn result envelope.
# It compares the production rescan Build with a classify-once candidate while
# preserving diagnostic order, fail-closed groups, exact reduction, and final shape.

production ← •Import "../../src/accounting/sparse_group.bqn"
scale ← •Import "../../src/ledger/exact_scale.bqn"
empty ← ⟨⟩

Show ← {𝕊 name‿value: •Out name∾": "∾•Repr value}
AssertEq ← {
  𝕨≡𝕩 ? 1;
  •Out "Assertion failed"
  •Out "expected: "∾•Repr 𝕨
  •Out "actual:   "∾•Repr 𝕩
  •Exit 1
}
Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}
IndexOf ← {𝕊 item‿items: ⊑(item⊸≡¨items)⊐1}
Diagnostic ← {𝕊 codeText‿messageText:
  {severity⇐"error",stage⇐"accounting_sparse_group",code⇐codeText,message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}
EmptyGroups ← {𝕊:
  {count⇐0,index⇐empty,row_index⇐empty,column_index⇐empty,coefficient⇐empty,contributors⇐empty}
}

CandidateBuild ← {𝕊 rowAxis‿columnCount‿rowCoordinates‿columnIndices‿coefficients‿contributors:
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
    rowIndices ← {IndexOf ⟨𝕩,rowAxis⟩}¨rowCoordinates
    cellCount ← columnCount×≠rowAxis
    cellIndices ← (columnCount×rowIndices)+columnIndices
    forcedGroupIndices ← cellIndices∾cellCount
    coefficientGroups ← forcedGroupIndices⊔coefficients
    nestedContributorGroups ← forcedGroupIndices⊔contributors
    occupied ← 0<≠¨coefficientGroups
    occupiedCells ← occupied/↕cellCount
    occupiedCoefficientGroups ← occupied/coefficientGroups
    occupiedContributorGroups ← occupied/nestedContributorGroups
    summed ← scale.Sum¨occupiedCoefficientGroups
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

DiagnosticView ← {𝕊 diagnostics:
  {𝕊 d: ⟨d.severity,d.stage,d.code,d.message⟩}¨diagnostics
}
ResultView ← {𝕊 result:
  g ← result.groups
  ⟨
    result.state,
    ⟨g.count,g.index,g.row_index,g.column_index,g.coefficient,g.contributors⟩,
    DiagnosticView result.diagnostics
  ⟩
}

Compare ← {𝕊 name‿input:
  expected ← ResultView production.Build input
  actual ← ResultView CandidateBuild input
  expected AssertEq actual
  Show ⟨name,actual⟩
}

sparseInput ← ⟨
  ⟨"d0","d1","d2"⟩,3,
  ⟨"d0","d2","d0","d1","d2"⟩,
  0‿2‿0‿1‿2,
  5‿7‿¯5‿3‿4,
  ⟨⟨"p0"⟩,⟨"p1"⟩,⟨"p2"⟩,⟨"p3"⟩,⟨"p4","p4b"⟩⟩
⟩

denseInput ← ⟨
  ⟨"r0","r1"⟩,2,
  ⟨"r1","r0","r1","r0"⟩,
  1‿0‿0‿1,
  4‿1‿3‿2,
  ⟨⟨"a"⟩,⟨"b"⟩,⟨"c"⟩,⟨"d"⟩⟩
⟩

emptyRowsInput ← ⟨empty,3,empty,empty,empty,empty⟩
zeroColumnsInput ← ⟨⟨"r0","r1"⟩,0,empty,empty,empty,empty⟩
overflowInput ← ⟨
  ⟨"r0"⟩,1,
  ⟨"r0","r0"⟩,
  0‿0,
  9007199254740992‿1,
  ⟨⟨"big"⟩,⟨"one"⟩⟩
⟩

misalignedInput ← ⟨⟨"r0"⟩,2,⟨"r0"⟩,empty,⟨1⟩,⟨⟨"x"⟩⟩⟩
duplicateAxisInput ← ⟨⟨"r0","r0"⟩,1,⟨"r0"⟩,⟨0⟩,⟨1⟩,⟨⟨"x"⟩⟩⟩
invalidCountInput ← ⟨⟨"r0"⟩,¯1,empty,empty,empty,empty⟩
unknownRowInput ← ⟨⟨"r0"⟩,2,⟨"missing"⟩,⟨0⟩,⟨1⟩,⟨⟨"x"⟩⟩⟩
invalidColumnInput ← ⟨⟨"r0"⟩,2,⟨"r0"⟩,⟨2⟩,⟨1⟩,⟨⟨"x"⟩⟩
missingContributorsInput ← ⟨⟨"r0"⟩,2,⟨"r0"⟩,⟨0⟩,⟨1⟩,⟨empty⟩⟩
combinedInvalidInput ← ⟨
  ⟨"r0","r0"⟩,¯1,
  ⟨"missing"⟩,⟨0⟩,⟨1⟩,⟨empty⟩
⟩

Compare ⟨"valid sparse publication",sparseInput⟩
Compare ⟨"valid dense publication",denseInput⟩
Compare ⟨"empty row axis publication",emptyRowsInput⟩
Compare ⟨"zero column axis publication",zeroColumnsInput⟩
Compare ⟨"overflow fail-closed publication",overflowInput⟩
Compare ⟨"misaligned admission",misalignedInput⟩
Compare ⟨"duplicate row axis admission",duplicateAxisInput⟩
Compare ⟨"invalid column count admission",invalidCountInput⟩
Compare ⟨"unknown row admission",unknownRowInput⟩
Compare ⟨"invalid column admission",invalidColumnInput⟩
Compare ⟨"missing contributors admission",missingContributorsInput⟩
Compare ⟨"combined diagnostic ordering",combinedInvalidInput⟩

•Out ""
•Out "sparse_group_classify_once_envelope probe: complete"
