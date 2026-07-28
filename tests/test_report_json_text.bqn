#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
json ← •Import "../src/report/json_text.bqn"
quote ← @+34 ⋄ slash ← @+92 ⋄ lf ← @+10
(quote∾"a"∾slash∾quote∾"b"∾slash∾slash∾"c"∾slash∾"n"∾"d"∾quote) lib.AssertEq json.String ("a"∾quote∾"b"∾slash∾"c"∾lf∾"d")
"-12.30" lib.AssertEq json.ExactNumber ⟨¯1230,2⟩
"true" lib.AssertEq json.Boolean 1
"[1, 2]" lib.AssertEq json.Array ⟨"1","2"⟩
("{"∾quote∾"amount"∾quote∾": 12.30}") lib.AssertEq json.Object ⟨json.Pair ⟨"amount",json.ExactNumber ⟨1230,2⟩⟩⟩
•Out "test_report_json_text: ok"
