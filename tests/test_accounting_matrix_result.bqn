#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
matrix ← •Import "../src/accounting/matrix_result.bqn"

result ← matrix.Build ⟨
  ⟨"r0","r1"⟩,⟨"c0","c1"⟩,1,
  ⟨⟨10,0⟩,⟨¯5,2⟩⟩,
  ⟨⟨⟨0⟩,⟨⟩⟩,⟨⟨1⟩,⟨2,3⟩⟩⟩
⟩
"ok" lib.AssertEq result.state
2 lib.AssertEq result.matrix.row_count
2 lib.AssertEq result.matrix.column_count
1 lib.AssertEq result.matrix.scale
⟨⟨10,0⟩,⟨¯5,2⟩⟩ lib.AssertEq result.matrix.values
⟨⟨⟨0⟩,⟨⟩⟩,⟨⟨1⟩,⟨2,3⟩⟩⟩ lib.AssertEq result.matrix.contributors

emptyResult ← matrix.Build ⟨⟨⟩,⟨⟩,0,⟨⟩,⟨⟩⟩
"ok" lib.AssertEq emptyResult.state
0 lib.AssertEq emptyResult.matrix.row_count
0 lib.AssertEq emptyResult.matrix.column_count

HasCode ← {𝕊 code‿diagnostics: ∨´0∾code⊸≡¨{𝕩.code}¨diagnostics}
CheckRejected ← {𝕊 input‿code:
  rejected ← matrix.Build input
  "error" lib.AssertEq rejected.state
  0 lib.AssertEq rejected.matrix.row_count
  0 lib.AssertEq rejected.matrix.column_count
  1 lib.AssertEq HasCode ⟨code,rejected.diagnostics⟩
}
CheckRejected ⟨⟨⟨"r","r"⟩,⟨"c"⟩,0,⟨⟨0⟩,⟨0⟩⟩,⟨⟨⟨⟩⟩,⟨⟨⟩⟩⟩⟩,"matrix_row_axis_duplicate"⟩
nestedDuplicate ← ⟨
  ⟨⟨"r",0⟩,⟨"s",1⟩,⟨"r",0⟩⟩,⟨⟨"c",0⟩⟩,0,
  ⟨⟨0⟩,⟨0⟩,⟨0⟩⟩,⟨⟨⟨⟩⟩,⟨⟨⟩⟩,⟨⟨⟩⟩⟩
⟩
CheckRejected ⟨nestedDuplicate,"matrix_row_axis_duplicate"⟩
CheckRejected ⟨⟨⟨"r"⟩,⟨"c","c"⟩,0,⟨⟨0,0⟩⟩,⟨⟨⟨⟩,⟨⟩⟩⟩⟩,"matrix_column_axis_duplicate"⟩
CheckRejected ⟨⟨⟨"r"⟩,⟨"c"⟩,0.5,⟨⟨0⟩⟩,⟨⟨⟨⟩⟩⟩⟩,"matrix_scale_invalid"⟩
CheckRejected ⟨⟨⟨"r"⟩,⟨"c"⟩,0,⟨⟩,⟨⟩⟩,"matrix_rows_misaligned"⟩
CheckRejected ⟨⟨⟨"r"⟩,⟨"c"⟩,0,⟨⟨0,1⟩⟩,⟨⟨⟨⟩⟩⟩⟩,"matrix_value_columns_misaligned"⟩
CheckRejected ⟨⟨⟨"r"⟩,⟨"c"⟩,0,⟨⟨0⟩⟩,⟨⟨⟨⟩,⟨⟩⟩⟩⟩,"matrix_contributor_columns_misaligned"⟩

•Out "test_accounting_matrix_result: ok"
