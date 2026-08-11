#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
amount ← •Import "../src/ledger/amount_text.bqn"

"0" lib.AssertEq amount.Format ⟨0,0⟩
"1234" lib.AssertEq amount.Format ⟨1234,0⟩
"0.00" lib.AssertEq amount.Format ⟨0,2⟩
"12.34" lib.AssertEq amount.Format ⟨1234,2⟩
"0.05" lib.AssertEq amount.Format ⟨5,2⟩
"-0.05" lib.AssertEq amount.Format ⟨¯5,2⟩
"-12.00" lib.AssertEq amount.Format ⟨¯1200,2⟩
"0.0001" lib.AssertEq amount.Format ⟨1,4⟩
"1.0" lib.AssertEq amount.Format ⟨10,1⟩

•Out "test_ledger_amount_text: ok"
