#!/usr/bin/env bqn

# Focused regression test for failure-only subprocess evidence.

lib ← •Import "test_lib.bqn"
Contains ← { needle ← 𝕨 ⋄ 0 < +´ (needle ⍷ 𝕩) }

Probe ← {𝕊:
  cmd ← ⟨"probe-command", "arg"⟩
  result ← ⟨7, "probe stdout", "probe stderr"⟩
  0 lib.AssertSH ⟨cmd, result⟩
}

Test ← {𝕊:
  result ← •SH ⟨"bqn", "tests/test_test_lib_subprocess_visibility.bqn", "probe"⟩
  stdout ← 1 ⊑ result
  1 lib.AssertEq 0 ⊑ result
  1 lib.AssertEq ("Subprocess assertion failed!" Contains stdout)
  1 lib.AssertEq ("command:" Contains stdout)
  1 lib.AssertEq ("probe-command" Contains stdout)
  1 lib.AssertEq ("exit code: 7" Contains stdout)
  1 lib.AssertEq ("stdout:" Contains stdout)
  1 lib.AssertEq ("probe stdout" Contains stdout)
  1 lib.AssertEq ("stderr:" Contains stdout)
  1 lib.AssertEq ("probe stderr" Contains stdout)
  •Out "test_test_lib_subprocess_visibility.bqn: OK"
}

(0 = ≠ •args) ◶ ⟨Probe, Test⟩ @