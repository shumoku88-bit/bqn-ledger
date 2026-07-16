#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
fmt ← •Import "../src_next/format.bqn"

esc ← 1 + @+26

fmt.SetColorEnabled 1
1 lib.AssertEq fmt.AnsiColorEnabled @
"OK" lib.AssertEq fmt.Ok "OK"
"future" lib.AssertEq fmt.Future "future"
"         -12" lib.AssertEq fmt.FmtAmt ¯12
"-12" lib.AssertEq fmt.HumanNumber ¯12
"  食費" lib.AssertEq fmt.PadLV ⟨6, "食費"⟩
expected_table ← "Name | Amount" ∾ (@+10) ∾ "-----+-------" ∾ (@+10) ∾ "食費 |    -12" ∾ (@+10) ∾ "Cash |      7" ∾ (@+10)
rows ← ⟨⟨"食費", "-12"⟩, ⟨"Cash", "7"⟩⟩
expected_table lib.AssertEq fmt.RenderTable ⟨⟨"Name", "Amount"⟩, rows, ⟨0, 1⟩⟩
empty_table ← "Name | Amount" ∾ (@+10) ∾ "-----+-------" ∾ (@+10)
empty_table lib.AssertEq fmt.RenderTable ⟨⟨"Name", "Amount"⟩, ⟨⟩, ⟨0, 1⟩⟩

fmt.SetColorEnabled 0
0 lib.AssertEq fmt.AnsiColorEnabled @
"OK" lib.AssertEq fmt.Ok "OK"
"future" lib.AssertEq fmt.Future "future"
"         -12" lib.AssertEq fmt.FmtAmt ¯12

fmt.SetColorEnabled 1

•Out "test_src_next_format.bqn: OK"

