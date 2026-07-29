#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
parse ← •Import "../src/text/parse.bqn"
io ← •Import "../src/application/source_io.bqn"

comma ← ⊑ ","
tab ← @+9

# The neutral parser owns pure split behavior, including edge empty fields.
sample ← ",a,,b,"
⟨"a", "b"⟩ lib.AssertEq comma parse.Split sample
⟨"", "a", "", "b", ""⟩ lib.AssertEq comma parse.SplitKeepEmpty sample

# Source I/O delegates split behavior to the neutral parser.
(comma parse.Split sample) lib.AssertEq comma io.Split sample
(comma parse.SplitKeepEmpty sample) lib.AssertEq comma io.SplitKeepEmpty sample

42 lib.AssertEq parse.ToNum "42"
¯42 lib.AssertEq parse.ToNum "-42"

# Native source I/O preserves CR stripping, comment/blank filtering, and TSV empties.
lines ← io.ReadLines "fixtures/source-io-ownership/source.tsv"
2 lib.AssertEq ≠ lines
("alpha" ∾ tab ∾ "beta") lib.AssertEq 0 ⊑ lines
("gamma" ∾ tab ∾ tab ∾ "delta") lib.AssertEq 1 ⊑ lines
⟨"gamma", "", "delta"⟩ lib.AssertEq io.SplitTsvKeepEmpty 1 ⊑ lines

•Out "test_source_io_ownership.bqn: OK"
