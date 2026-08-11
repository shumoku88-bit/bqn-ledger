#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
group ← •Import "../src/accounting/sparse_group.bqn"

result ← group.Build ⟨
  ⟨"a","b"⟩,2,
  ⟨"a","a","b"⟩,⟨0,0,1⟩,⟨10,¯10,5⟩,⟨⟨0⟩,⟨1,2⟩,⟨3⟩⟩
⟩
"ok" lib.AssertEq result.state
2 lib.AssertEq result.groups.count
⟨0,1⟩ lib.AssertEq result.groups.row_index
⟨0,1⟩ lib.AssertEq result.groups.column_index
⟨0,5⟩ lib.AssertEq result.groups.coefficient
⟨⟨0,1,2⟩,⟨3⟩⟩ lib.AssertEq result.groups.contributors

# Opaque nested row coordinates classify directly onto the explicit row axis.
nestedRows ← ⟨⟨"a",0⟩,⟨"b",1⟩⟩
nestedResult ← group.Build ⟨
  nestedRows,2,
  ⟨⟨"b",1⟩,⟨"a",0⟩,⟨"b",1⟩⟩,⟨1,0,1⟩,⟨3,4,5⟩,⟨⟨3⟩,⟨4⟩,⟨5⟩⟩
⟩
"ok" lib.AssertEq nestedResult.state
⟨0,1⟩ lib.AssertEq nestedResult.groups.row_index
⟨0,1⟩ lib.AssertEq nestedResult.groups.column_index
⟨4,8⟩ lib.AssertEq nestedResult.groups.coefficient
⟨⟨4⟩,⟨3,5⟩⟩ lib.AssertEq nestedResult.groups.contributors

emptyResult ← group.Build ⟨⟨"a"⟩,2,⟨⟩,⟨⟩,⟨⟩,⟨⟩⟩
"ok" lib.AssertEq emptyResult.state
0 lib.AssertEq emptyResult.groups.count

emptyRowsResult ← group.Build ⟨⟨⟩,3,⟨⟩,⟨⟩,⟨⟩,⟨⟩⟩
"ok" lib.AssertEq emptyRowsResult.state
0 lib.AssertEq emptyRowsResult.groups.count

zeroColumnsResult ← group.Build ⟨⟨"a","b"⟩,0,⟨⟩,⟨⟩,⟨⟩,⟨⟩⟩
"ok" lib.AssertEq zeroColumnsResult.state
0 lib.AssertEq zeroColumnsResult.groups.count

HasCode ← {𝕊 code‿diagnostics: ∨´0∾code⊸≡¨{𝕩.code}¨diagnostics}
CheckRejected ← {𝕊 input‿code:
  rejected ← group.Build input
  "error" lib.AssertEq rejected.state
  0 lib.AssertEq rejected.groups.count
  1 lib.AssertEq HasCode ⟨code,rejected.diagnostics⟩
}
CheckRejected ⟨⟨⟨"a"⟩,1,⟨"a"⟩,⟨0,0⟩,⟨1⟩,⟨⟨0⟩⟩⟩,"group_columns_misaligned"⟩
CheckRejected ⟨⟨⟨"a","a"⟩,1,⟨⟩,⟨⟩,⟨⟩,⟨⟩⟩,"group_row_axis_duplicate"⟩
nestedDuplicateAxis ← ⟨⟨"a",0⟩,⟨"b",1⟩,⟨"a",0⟩⟩
CheckRejected ⟨⟨nestedDuplicateAxis,1,⟨⟩,⟨⟩,⟨⟩,⟨⟩⟩,"group_row_axis_duplicate"⟩
CheckRejected ⟨⟨⟨"a"⟩,¯1,⟨⟩,⟨⟩,⟨⟩,⟨⟩⟩,"group_column_count_invalid"⟩
CheckRejected ⟨⟨⟨"a"⟩,1,⟨"b"⟩,⟨0⟩,⟨1⟩,⟨⟨0⟩⟩⟩,"group_row_coordinate_unknown"⟩
CheckRejected ⟨⟨⟨"a"⟩,1,⟨"a"⟩,⟨1⟩,⟨1⟩,⟨⟨0⟩⟩⟩,"group_column_index_invalid"⟩
CheckRejected ⟨⟨⟨"a"⟩,1,⟨"a"⟩,⟨0.5⟩,⟨1⟩,⟨⟨0⟩⟩⟩,"group_column_index_invalid"⟩
CheckRejected ⟨⟨⟨"a"⟩,1,⟨"a"⟩,⟨0⟩,⟨1⟩,⟨⟨⟩⟩⟩,"group_contributors_missing"⟩
CheckRejected ⟨⟨⟨"a"⟩,1,⟨"a","a"⟩,⟨0,0⟩,⟨9007199254740991,2⟩,⟨⟨0⟩,⟨1⟩⟩⟩,"group_sum_failed"⟩

# Independent admission failures remain ordered and publication remains fail-closed.
combinedRejected ← group.Build ⟨
  ⟨"a","a"⟩,¯1,
  ⟨"missing"⟩,⟨0⟩,⟨1⟩,⟨⟨⟩⟩
⟩
"error" lib.AssertEq combinedRejected.state
0 lib.AssertEq combinedRejected.groups.count
⟨
  "group_row_axis_duplicate",
  "group_column_count_invalid",
  "group_row_coordinate_unknown",
  "group_column_index_invalid",
  "group_contributors_missing"
⟩ lib.AssertEq {𝕩.code}¨combinedRejected.diagnostics

•Out "test_accounting_sparse_group: ok"
