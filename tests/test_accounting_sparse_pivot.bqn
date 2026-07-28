#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
pivot ← •Import "../src/accounting/sparse_pivot.bqn"

MakeGroups ← {𝕊 rows‿columns‿values‿contributors:
  {count⇐≠rows,index⇐↕≠rows,row_index⇐rows,column_index⇐columns,coefficient⇐values,contributors⇐contributors}
}
groups ← MakeGroups ⟨⟨0,1⟩,⟨0,1⟩,⟨0,5⟩,⟨⟨3,4⟩,⟨8⟩⟩⟩
result ← pivot.Build ⟨⟨"r0","r1"⟩,⟨"c0","c1"⟩,2,groups⟩
"ok" lib.AssertEq result.state
2 lib.AssertEq result.matrix.row_count
2 lib.AssertEq result.matrix.column_count
4 lib.AssertEq result.matrix.cell_count
2 lib.AssertEq result.matrix.scale
⟨⟨0,0⟩,⟨0,5⟩⟩ lib.AssertEq result.matrix.values
⟨⟨⟨3,4⟩,⟨⟩⟩,⟨⟨⟩,⟨8⟩⟩⟩ lib.AssertEq result.matrix.contributors

emptyGroups ← MakeGroups ⟨⟨⟩,⟨⟩,⟨⟩,⟨⟩⟩
emptyResult ← pivot.Build ⟨⟨⟩,⟨⟩,0,emptyGroups⟩
"ok" lib.AssertEq emptyResult.state
0 lib.AssertEq emptyResult.matrix.cell_count

HasCode ← {𝕊 code‿diagnostics: ∨´0∾code⊸≡¨{𝕩.code}¨diagnostics}
CheckRejected ← {𝕊 rows‿columns‿valueScale‿sourceGroups‿code:
  rejected ← pivot.Build ⟨rows,columns,valueScale,sourceGroups⟩
  "error" lib.AssertEq rejected.state
  0 lib.AssertEq rejected.matrix.cell_count
  1 lib.AssertEq HasCode ⟨code,rejected.diagnostics⟩
}
CheckRejected ⟨⟨"r","r"⟩,⟨"c"⟩,0,emptyGroups,"matrix_row_axis_duplicate"⟩
CheckRejected ⟨⟨"r"⟩,⟨"c","c"⟩,0,emptyGroups,"matrix_column_axis_duplicate"⟩
CheckRejected ⟨⟨"r"⟩,⟨"c"⟩,0.5,emptyGroups,"matrix_scale_invalid"⟩
misaligned ← {count⇐1,index⇐⟨0⟩,row_index⇐⟨0⟩,column_index⇐⟨0,0⟩,coefficient⇐⟨1⟩,contributors⇐⟨⟨0⟩⟩}
CheckRejected ⟨⟨"r"⟩,⟨"c"⟩,0,misaligned,"pivot_group_columns_misaligned"⟩
CheckRejected ⟨⟨"r"⟩,⟨"c"⟩,0,MakeGroups ⟨⟨1⟩,⟨0⟩,⟨1⟩,⟨⟨0⟩⟩⟩,"pivot_row_index_invalid"⟩
CheckRejected ⟨⟨"r"⟩,⟨"c"⟩,0,MakeGroups ⟨⟨0⟩,⟨1⟩,⟨1⟩,⟨⟨0⟩⟩⟩,"pivot_column_index_invalid"⟩
duplicate ← MakeGroups ⟨⟨0,0⟩,⟨0,0⟩,⟨1,2⟩,⟨⟨0⟩,⟨1⟩⟩⟩
CheckRejected ⟨⟨"r"⟩,⟨"c"⟩,0,duplicate,"pivot_coordinate_duplicate"⟩

•Out "test_accounting_sparse_pivot: ok"
