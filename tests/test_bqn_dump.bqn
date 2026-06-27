# tests/test_bqn_dump.bqn
# Unit tests for tools/bqn-dump.bqn (Phase 2: explicit value dumper helper)
#
# Tests the introspection functions: Kind, IsStr, IsNum, IsBoxedScalar,
# HasBoxedEls, and the full Dump output.
#
# Run: bqn tests/test_bqn_dump.bqn

lib ← •Import "test_lib.bqn"
dump ← •Import "../tools/bqn-dump.bqn"

# ── Kind classification ──

"number" lib.AssertEq dump.Kind 5
"string" lib.AssertEq dump.Kind "OK"
"string" lib.AssertEq dump.Kind "hello world"
"list" lib.AssertEq dump.Kind ⟨1,2,3⟩
"list" lib.AssertEq dump.Kind ⟨⟩
"boxed" lib.AssertEq dump.Kind <5
"boxed" lib.AssertEq dump.Kind <"OK"
"list_boxed" lib.AssertEq dump.Kind ⟨<"OK", <"WARN"⟩
"list" lib.AssertEq dump.Kind ⟨5, "hello", <"boxed"⟩
"string" lib.AssertEq dump.Kind "OK"∾"WARN"
"number" lib.AssertEq dump.Kind ¯5
"number" lib.AssertEq dump.Kind 0

# ── IsStr detection ──

1 lib.AssertEq dump.IsStr "OK"
1 lib.AssertEq dump.IsStr "hello"
0 lib.AssertEq dump.IsStr ⟨1,2,3⟩
0 lib.AssertEq dump.IsStr ⟨⟩
0 lib.AssertEq dump.IsStr 5
0 lib.AssertEq dump.IsStr <"OK"
0 lib.AssertEq dump.IsStr ⟨"a","b"⟩

# ── IsNum detection ──

1 lib.AssertEq dump.IsNum 5
1 lib.AssertEq dump.IsNum 0
1 lib.AssertEq dump.IsNum ¯1
0 lib.AssertEq dump.IsNum "5"
0 lib.AssertEq dump.IsNum ⟨5⟩

# ── IsBoxedScalar detection ──

0 lib.AssertEq dump.IsBoxedScalar 5
1 lib.AssertEq dump.IsBoxedScalar <5
1 lib.AssertEq dump.IsBoxedScalar <"OK"
0 lib.AssertEq dump.IsBoxedScalar "OK"
0 lib.AssertEq dump.IsBoxedScalar ⟨1,2,3⟩
0 lib.AssertEq dump.IsBoxedScalar ⟨<"OK", <"WARN"⟩

# ── HasBoxedEls detection ──

0 lib.AssertEq dump.HasBoxedEls ⟨1,2,3⟩
1 lib.AssertEq dump.HasBoxedEls ⟨<"OK", <"WARN"⟩
0 lib.AssertEq dump.HasBoxedEls ⟨"OK", "WARN"⟩
0 lib.AssertEq dump.HasBoxedEls 5
0 lib.AssertEq dump.HasBoxedEls "OK"
0 lib.AssertEq dump.HasBoxedEls ⟨⟩
1 lib.AssertEq dump.HasBoxedEls ⟨<1,<2⟩

# ── Homogenization / Enclose / Disclose distinction ──
# (The pain points that motivated this tool)

"string" lib.AssertEq dump.Kind "OK"∾"OK"        # concatenation → string
"string" lib.AssertEq dump.Kind "WARN"∾"OK"       # concatenation → string  
"list" lib.AssertEq dump.Kind ⟨"OK","OK"⟩         # plain list
"list_boxed" lib.AssertEq dump.Kind ⟨<"OK",<"OK"⟩ # boxed list: AI can see difference
"boxed" lib.AssertEq dump.Kind <"OK"              # boxed scalar
"boxed" lib.AssertEq dump.Kind 0⊏⟨"a","b","c"⟩   # single-element extraction → boxed

# ── Common BQN debugging scenarios ──

# Shape distinction: number vs length-1 list
"number" lib.AssertEq dump.Kind 42
"list" lib.AssertEq dump.Kind ⟨42⟩

# Empty array
"list" lib.AssertEq dump.Kind ⟨⟩
0 lib.AssertEq dump.IsStr ⟨⟩

# Rank distinction
"number" lib.AssertEq dump.Kind ¯1
"list" lib.AssertEq dump.Kind 1‿2‿3  # strand → list
"string" lib.AssertEq dump.Kind "123"

# ── Full Dump output (smoke test: Dump writes to •Out) ──
# Dump should produce output without erroring on each value type.
dump.Dump 5
dump.Dump "OK"
dump.Dump ⟨1,2,3⟩
dump.Dump ⟨<"OK", <"WARN"⟩
dump.Dump <5
dump.Dump ⟨5, "hello", <"boxed"⟩

•Out "All bqn-dump tests passed."
