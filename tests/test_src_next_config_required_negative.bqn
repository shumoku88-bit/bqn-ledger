#!/usr/bin/env bqn

# Auto-discovered subprocess-level A4 negative test.

lib ← •Import "test_lib.bqn"
Contains ← { needle ← 𝕨 ⋄ 0 < +´ (needle ⍷ 𝕩) }

CheckFailure ← {𝕊 base‿key:
  result ← •SH ⟨"bqn", "tests/config_required_probe.bqn", base, key⟩
  1 lib.AssertEq 0 ⊑ result
  1 lib.AssertEq (("CONFIG ERROR: missing value for " ∾ key) Contains 1 ⊑ result)
}

{ CheckFailure ⟨"fixtures/src-next-config-eligible-missing", 𝕩⟩ }¨
  ⟨"HOUSEHOLD_GROUP_LIFE", "HOUSEHOLD_GROUP_RESERVE"⟩

{ CheckFailure ⟨"fixtures/src-next-config-eligible-empty", 𝕩⟩ }¨
  ⟨"HOUSEHOLD_GROUP_LIFE", "HOUSEHOLD_GROUP_RESERVE"⟩

•Out "test_src_next_config_required_negative.bqn: OK"
