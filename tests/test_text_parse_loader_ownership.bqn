#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
parse ← •Import "../src/text/parse.bqn"
loader ← •Import "../src_next/loader.bqn"

comma ← ⊑ ","
tab ← @+9

# The neutral parser owns pure split behavior, including edge empty fields.
sample ← ",a,,b,"
⟨"a", "b"⟩ lib.AssertEq comma parse.Split sample
⟨"", "a", "", "b", ""⟩ lib.AssertEq comma parse.SplitKeepEmpty sample

# The old loader preserves its split API by delegating to the neutral parser.
(comma parse.Split sample) lib.AssertEq comma loader.Split sample
(comma parse.SplitKeepEmpty sample) lib.AssertEq comma loader.SplitKeepEmpty sample

42 lib.AssertEq parse.ToNum "42"
¯42 lib.AssertEq parse.ToNum "-42"

# Native loader I/O preserves CR stripping, comment/blank filtering, and TSV empties.
lines ← loader.ReadLines "fixtures/loader-util-ownership/source.tsv"
2 lib.AssertEq ≠ lines
("alpha" ∾ tab ∾ "beta") lib.AssertEq 0 ⊑ lines
("gamma" ∾ tab ∾ tab ∾ "delta") lib.AssertEq 1 ⊑ lines
⟨"gamma", "", "delta"⟩ lib.AssertEq loader.SplitTsvKeepEmpty 1 ⊑ lines

•Out "test_text_parse_loader_ownership.bqn: OK"
