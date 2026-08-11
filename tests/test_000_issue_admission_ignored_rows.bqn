#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
line ← ""
ignored ← (0=≠line) ? 1 ; (⊑line)∊"#\\"
lib.Assert ignored

•Out "temporary Issue predicate gate: ok"
