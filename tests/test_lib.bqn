# tests/test_lib.bqn
# Minimal testing framework

{
  Assert ⇐ {
    𝕩 ? 1;
    •Out "Assertion failed!"
    •Exit 1
  }

  AssertEq ⇐ {
    𝕨 ≡ 𝕩 ? 1;
    •Out "Assertion failed: expected " ∾ (•Fmt 𝕨) ∾ " but got " ∾ (•Fmt 𝕩)
    •Exit 1
  }
}
