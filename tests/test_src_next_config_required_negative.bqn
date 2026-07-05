#!/usr/bin/env bqn

# Auto-discovered subprocess-level A4 negative test.

lib ← •Import "test_lib.bqn"
Contains ← { needle ← 𝕨 ⋄ 0 < +´ (needle ⍷ 𝕩) }

CheckFailure ← {𝕊 base‿key:
  cmd ← ⟨"bqn", "tests/config_required_probe.bqn", base, key⟩
  result ← •SH cmd
  (1 = 0 ⊑ result) lib.AssertSH ⟨cmd, result⟩
  (("CONFIG ERROR: missing value for " ∾ key) Contains 1 ⊑ result) lib.AssertSH ⟨cmd, result⟩
}

{ CheckFailure ⟨"fixtures/src-next-config-eligible-missing", 𝕩⟩ }¨
  ⟨"HOUSEHOLD_GROUP_LIFE", "HOUSEHOLD_GROUP_RESERVE"⟩

{ CheckFailure ⟨"fixtures/src-next-config-eligible-empty", 𝕩⟩ }¨
  ⟨"HOUSEHOLD_GROUP_LIFE", "HOUSEHOLD_GROUP_RESERVE"⟩

•Out "test_src_next_config_required_negative.bqn: OK"