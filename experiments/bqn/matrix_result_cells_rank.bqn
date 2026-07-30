#!/usr/bin/env bqn

# Analysis-only probe for src/accounting/matrix_result.bqn.
# It compares element mapping over nested rows with cell mapping over true arrays.

Show ← {𝕊 name‿value:
  •Out name∾": "∾•Repr value
}
All ← {𝕊 values: ∧´1∾values}
HasTwoColumns ← {𝕊 row: 2=≠row}

ShowNested ← {𝕊 name‿rows:
  •Out ""
  •Out name
  Show ⟨"outer shape",≢rows⟩
  Show ⟨"outer rank",=rows⟩
  eachResult ← HasTwoColumns¨rows
  cellsResult ← HasTwoColumns˘rows
  rankZeroResult ← HasTwoColumns⎉0 rows
  Show ⟨"Each predicate",eachResult⟩
  Show ⟨"Cells predicate",cellsResult⟩
  Show ⟨"Rank 0 predicate",rankZeroResult⟩
  Show ⟨"Each all",All eachResult⟩
  Show ⟨"Cells all",All cellsResult⟩
  Show ⟨"Rank 0 all",All rankZeroResult⟩
}

ShowRectangular ← {𝕊 name‿table:
  •Out ""
  •Out name
  Show ⟨"table shape",≢table⟩
  Show ⟨"table rank",=table⟩
  eachResult ← HasTwoColumns¨table
  cellsResult ← HasTwoColumns˘table
  rankOneResult ← HasTwoColumns⎉1 table
  rankNegativeOneResult ← HasTwoColumns⎉¯1 table
  Show ⟨"Each predicate",eachResult⟩
  Show ⟨"Cells predicate",cellsResult⟩
  Show ⟨"Rank 1 predicate",rankOneResult⟩
  Show ⟨"Rank ¯1 predicate",rankNegativeOneResult⟩
  Show ⟨"Cells all",All cellsResult⟩
  Show ⟨"Rank 1 all",All rankOneResult⟩
}

nestedRectangular ← ⟨⟨10,0⟩,⟨¯5,2⟩⟩
nestedRagged ← ⟨⟨10⟩,⟨¯5,2⟩⟩
nestedEmpty ← ⟨⟩
trueRectangular ← >nestedRectangular
trueEmptyTwoColumns ← 0‿2⥊0

ShowNested ⟨"nested rows with equal lengths",nestedRectangular⟩
ShowNested ⟨"nested rows with unequal lengths",nestedRagged⟩
ShowNested ⟨"empty nested row sequence",nestedEmpty⟩
ShowRectangular ⟨"true 2×2 array",trueRectangular⟩
ShowRectangular ⟨"true 0×2 array",trueEmptyTwoColumns⟩

•Out ""
•Out "matrix_result_cells_rank probe: complete"
