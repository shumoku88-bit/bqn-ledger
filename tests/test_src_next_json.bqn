#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
json ← •Import "../src_next/json.bqn"

quote ← @+34
backslash ← @+92
newline ← @+10
tab ← @+9

"-12" lib.AssertEq json.Serialize ¯12

quoted_input ← "a" ∾ quote ∾ "b"
quoted_expected ← quote ∾ "a" ∾ backslash ∾ quote ∾ "b" ∾ quote
quoted_expected lib.AssertEq json.Serialize quoted_input

newline_input ← "a" ∾ newline ∾ "b"
newline_expected ← quote ∾ "a" ∾ backslash ∾ "n" ∾ "b" ∾ quote
newline_expected lib.AssertEq json.Serialize newline_input

tab_input ← "a" ∾ tab ∾ "b"
tab_expected ← quote ∾ "a" ∾ backslash ∾ "t" ∾ "b" ∾ quote
tab_expected lib.AssertEq json.Serialize tab_input

obj ← ⟨
  ⟨"amount", ¯12⟩,
  ⟨"memo", quoted_input⟩
⟩
obj_expected ← "{" ∾ quote ∾ "amount" ∾ quote ∾ ": -12, " ∾ quote ∾ "memo" ∾ quote ∾ ": " ∾ quoted_expected ∾ "}"
obj_expected lib.AssertEq json.Serialize obj

"null" lib.AssertEq json.Serialize @

obj_with_null ← ⟨
  ⟨"val", @⟩
⟩
obj_with_null_expected ← "{" ∾ quote ∾ "val" ∾ quote ∾ ": null}"
obj_with_null_expected lib.AssertEq json.Serialize obj_with_null

•Out "test_src_next_json.bqn: OK"
