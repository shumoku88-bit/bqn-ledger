#!/usr/bin/env bqn

# Analysis-only probe for src/accounting/sparse_group.bqn.
# It compares row×column rescanning with one coordinate classification plus Group.

scale ← •Import "../../src/ledger/exact_scale.bqn"
empty ← ⟨⟩

Show ← {𝕊 name‿value:
  •Out name∾": "∾•Repr value
}
AssertEq ← {
  𝕨≡𝕩 ? 1;
  •Out "Assertion failed"
  •Out "expected: "∾•Repr 𝕨
  •Out "actual:   "∾•Repr 𝕩
  •Exit 1
}
IndexOf ← {𝕊 item‿items: ⊑(item⊸≡¨items)⊐1}
All ← {𝕊 values: ∧´1∾values}

Validate ← {𝕊 rowAxis‿columnCount‿rowCoordinates‿columnIndices‿coefficients‿contributors:
  lengths ← ≠¨⟨rowCoordinates,columnIndices,coefficients,contributors⟩
  aligned ← All (≠rowCoordinates)=lengths
  countValid ← (0≤columnCount) ∧ columnCount=⌊columnCount
  rowIndices ← {IndexOf ⟨𝕩,rowAxis⟩}¨rowCoordinates
  rowsKnown ← All rowIndices<≠rowAxis
  columnsValid ← countValid ∧ All {(0≤𝕩) ∧ (𝕩<columnCount) ∧ 𝕩=⌊𝕩}¨columnIndices
  contributorsPresent ← All {0<≠𝕩}¨contributors
  ⟨aligned,countValid,rowsKnown,columnsValid,contributorsPresent⟩
}

# View: row indices / column indices / coefficient groups / flattened contributors.
Rescan ← {𝕊 rowAxis‿columnCount‿rowCoordinates‿columnIndices‿coefficients‿contributors:
  rows ← empty ⋄ columns ← empty ⋄ coefficientGroups ← empty ⋄ contributorGroups ← empty
  {𝕊 rowIndex:
    coordinate ← rowIndex⊑rowAxis
    {𝕊 columnIndex:
      mask ← (coordinate⊸≡¨rowCoordinates) ∧ columnIndex=columnIndices
      selected ← mask/coefficients
      {𝕊:
        rows∾↩rowIndex
        columns∾↩columnIndex
        coefficientGroups∾↩⟨selected⟩
        contributorGroups∾↩⟨∾mask/contributors⟩
      }⍟(0<≠selected) @
    }¨↕columnCount
  }¨↕≠rowAxis
  ⟨rows,columns,coefficientGroups,contributorGroups⟩
}

ClassifyOnce ← {𝕊 rowAxis‿columnCount‿rowCoordinates‿columnIndices‿coefficients‿contributors:
  rowIndices ← {IndexOf ⟨𝕩,rowAxis⟩}¨rowCoordinates
  cellCount ← columnCount×≠rowAxis
  cellIndices ← (columnCount×rowIndices)+columnIndices
  groupIndices ← cellIndices∾cellCount
  coefficientGroups ← groupIndices⊔coefficients
  nestedContributorGroups ← groupIndices⊔contributors
  occupied ← 0<≠¨coefficientGroups
  occupiedCells ← occupied/↕cellCount
  rows ← {⌊𝕩÷columnCount}¨occupiedCells
  columns ← columnCount|occupiedCells
  ⟨rows,columns,occupied/coefficientGroups,∾¨occupied/nestedContributorGroups⟩
}

SumView ← {𝕊 grouped:
  results ← scale.Sum¨2⊑grouped
  ⟨{𝕩.state}¨results,{𝕩.coefficient}¨results,{𝕩.code}¨results⟩
}

Compare ← {𝕊 name‿input:
  validation ← Validate input
  Show ⟨name∾" validation",validation⟩
  expected ← Rescan input
  actual ← ClassifyOnce input
  expected AssertEq actual
  expectedSums ← SumView expected
  actualSums ← SumView actual
  expectedSums AssertEq actualSums
  itemCount ← ≠2⊑input
  rowCount ← ≠⊑input
  columnCount ← 1⊑input
  Show ⟨name∾" rescan mask comparisons",rowCount×columnCount×itemCount⟩
  Show ⟨name∾" classify assignments",itemCount⟩
  Show ⟨name∾" grouped view",actual⟩
  Show ⟨name∾" sum view",actualSums⟩
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

Compare ⟨"sparse with exact-zero and multiple contributors",sparseInput⟩
Compare ⟨"dense interleaved input",denseInput⟩
Compare ⟨"empty row axis",emptyRowsInput⟩
Compare ⟨"zero column axis",zeroColumnsInput⟩
Compare ⟨"exact-sum overflow",overflowInput⟩

⟨1,1,0,0,1⟩ AssertEq Validate ⟨⟨"r0"⟩,2,⟨"missing"⟩,⟨0⟩,⟨1⟩,⟨⟨"x"⟩⟩⟩
⟨1,1,1,0,1⟩ AssertEq Validate ⟨⟨"r0"⟩,2,⟨"r0"⟩,⟨2⟩,⟨1⟩,⟨⟨"x"⟩⟩⟩
⟨0,1,1,1,1⟩ AssertEq Validate ⟨⟨"r0"⟩,2,⟨"r0"⟩,empty,⟨1⟩,⟨⟨"x"⟩⟩⟩

•Out ""
•Out "sparse_group_classify_once probe: complete"
