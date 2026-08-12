#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
text ← •Import "../src/report/text.bqn"

1 lib.AssertEq text.VWidth "a"
2 lib.AssertEq text.VWidth "円"
"ab " lib.AssertEq text.PadRight ⟨3,"ab"⟩
" ab" lib.AssertEq text.PadLeft ⟨3,"ab"⟩
"-12.30" lib.AssertEq text.FormatAmount ⟨¯1230,2,"minus"⟩
"(12.30)" lib.AssertEq text.FormatAmount ⟨¯1230,2,"parentheses"⟩
"12.30" lib.AssertEq text.FormatAmount ⟨1230,2,"parentheses"⟩
•Out "test_report_text: ok"
