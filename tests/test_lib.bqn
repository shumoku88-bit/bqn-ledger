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

  AssertSH ⇐ {
    𝕨 ? 1;
    cmd‿result ← 𝕩
    code‿stdout‿stderr ← result
    •Out "Subprocess assertion failed!"
    •Out "command: " ∾ •Fmt cmd
    •Out "exit code: " ∾ •Fmt code
    •Out "stdout:"
    •Out stdout
    •Out "stderr:"
    •Out stderr
    •Exit 1
  }
}