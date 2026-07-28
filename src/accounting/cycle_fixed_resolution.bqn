# Pure fixed-cycle resolution. No observation, Facts, I/O, or clock is required.

result ← •Import "cycle_result.bqn"

Resolve ← {𝕊 admittedCycle:
  resolved ← result.Error ⟨"fixed","","cycle_admission_not_ok","cycle definition must be admitted"⟩
  {𝕊:
    definition ← admittedCycle.definition
    resolved↩result.Error ⟨definition.mode,"","cycle_mode_mismatch","fixed resolver requires fixed mode"⟩
    {𝕊: resolved↩result.Success ⟨"fixed","",definition.start,definition.end_exclusive,⟨⟩,⟨⟩⟩}⍟(definition.mode≡"fixed") @
  }⍟(admittedCycle.state≡"ok") @
  resolved
}

{Resolve⇐Resolve}
