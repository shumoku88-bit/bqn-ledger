#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
fmt ← •Import "../src_next/format.bqn"

esc ← @+27

fmt.SetColorEnabled 1
1 lib.AssertEq fmt.AnsiColorEnabled @
1 lib.AssertEq ∨´ ((esc ∾ "[32m") ⍷ fmt.Ok "OK")
1 lib.AssertEq ∨´ ((esc ∾ "[35m") ⍷ fmt.Future "future")
1 lib.AssertEq ∨´ ((esc ∾ "[31m") ⍷ fmt.FmtAmt ¯12)

fmt.SetColorEnabled 0
0 lib.AssertEq fmt.AnsiColorEnabled @
"OK" lib.AssertEq fmt.Ok "OK"
"future" lib.AssertEq fmt.Future "future"
"         ¯12" lib.AssertEq fmt.FmtAmt ¯12

fmt.SetColorEnabled 1

•Out "test_src_next_format.bqn: OK"
