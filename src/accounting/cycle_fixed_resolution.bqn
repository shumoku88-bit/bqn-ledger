# Pure fixed-cycle resolution. No observation, Facts, I/O, or clock is required.

result ← •Import "cycle_result.bqn"

Resolve ← {𝕊 admittedCycle:
  {𝕊: result.Error ⟨"fixed","","cycle_admission_not_ok","cycle definition must be admitted"⟩}⍟(admittedCycle.state≢"ok") @ ⋄
  def ← admittedCycle.definition
  {𝕊: result.Error ⟨def.mode,"","cycle_mode_mismatch","fixed resolver requires fixed mode"⟩}⍟(def.mode≢"fixed") @ ⋄
  result.Success ⟨"fixed","",def.start,def.end_exclusive,⟨⟩,⟨⟩⟩
}

{Resolve⇐Resolve}
