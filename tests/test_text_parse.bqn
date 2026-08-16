# Direct laws for the shared text parser primitives.

t ← •Import "test_lib.bqn"
parse ← •Import "../src/text/parse.bqn"

•Out "Running shared text parse tests..."

⟨⟩ t.AssertEq ',' parse.SplitKeepEmpty ""
⟨"a"⟩ t.AssertEq ',' parse.SplitKeepEmpty "a"
⟨"a","b"⟩ t.AssertEq ',' parse.SplitKeepEmpty "a,b"
⟨"a","","b",""⟩ t.AssertEq ',' parse.SplitKeepEmpty "a,,b,"
⟨"","a"⟩ t.AssertEq ',' parse.SplitKeepEmpty ",a"

0 t.AssertEq parse.ToNum "0"
42 t.AssertEq parse.ToNum "42"
¯7 t.AssertEq parse.ToNum "-7"

•Out "Shared text parse tests passed!"
