#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
util ← •Import "../src_next/util.bqn"
loader ← •Import "../src_next/loader.bqn"

comma ← ⊑ ","
tab ← @+9

# util owns the pure split behavior.
sample ← "a,,b,"
⟨"a", "b"⟩ lib.AssertEq comma util.Split sample
⟨"a", "", "b", ""⟩ lib.AssertEq comma util.SplitKeepEmpty sample

# loader preserves its public split API by delegating to util.
(comma util.Split sample) lib.AssertEq comma loader.Split sample
(comma util.SplitKeepEmpty sample) lib.AssertEq comma loader.SplitKeepEmpty sample

42 lib.AssertEq util.ToNum "42"
¯42 lib.AssertEq util.ToNum "-42"

# Native loader I/O preserves CR stripping, comment/blank filtering, and TSV empties.
lines ← loader.ReadLines "fixtures/loader-util-ownership/source.tsv"
2 lib.AssertEq ≠ lines
("alpha" ∾ tab ∾ "beta") lib.AssertEq 0 ⊑ lines
("gamma" ∾ tab ∾ tab ∾ "delta") lib.AssertEq 1 ⊑ lines
⟨"gamma", "", "delta"⟩ lib.AssertEq loader.SplitTsvKeepEmpty 1 ⊑ lines

•Out "test_src_next_loader_util_ownership.bqn: OK"
