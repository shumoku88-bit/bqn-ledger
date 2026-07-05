#!/usr/bin/env bqn

# Temporary A4 observation harness. Remove after recording experiment results.

lib ← •Import "test_lib.bqn"
result ← •SH ⟨"bash", "checks/check-policy-income-cadence-observation.sh"⟩
code ← 0 ⊑ result

{𝕊:
  •Out 1 ⊑ result
  •Out 2 ⊑ result
}⍟(0 ≠ code) @

0 lib.AssertEq code
•Out "test_policy_income_cadence_observation.bqn: OK"
