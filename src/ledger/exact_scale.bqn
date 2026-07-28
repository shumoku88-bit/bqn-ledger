# Pure exact coefficient scale normalization and checked summation.
# Inputs are already-admitted signed integer coefficients and nonnegative scales.

exact ← •Import "exact_decimal.bqn"
empty ← ⟨⟩

Failure ← {𝕊 codeText: {state⇐"error",coefficient⇐empty,code⇐codeText} }
Success ← {𝕊 coefficientValue: {state⇐"ok",coefficient⇐coefficientValue,code⇐""} }

Normalize ← {𝕊 coefficient‿sourceScale‿targetScale:
  result ← Failure "scale_invalid"
  {𝕊:
    zeroCount ← targetScale-sourceScale
    magnitudeText ← (•Fmt |coefficient)∾zeroCount⥊'0'
    parsed ← exact.Parse magnitudeText
    result ↩ Failure "normalized_coefficient_out_of_exact_range"
    {𝕊:
      normalized ← (coefficient<0)⊑⟨parsed.coefficient,-parsed.coefficient⟩
      result↩Success normalized
    }⍟(parsed.state≡"ok") @
  }⍟((0≤sourceScale) ∧ sourceScale≤targetScale) @
  result
}

Sum ← {𝕊 coefficients:
  state ← "ok" ⋄ code ← "" ⋄ total ← 0
  {𝕊 value:
    {𝕊:
      candidate ← total+value
      exactAdd ← ((candidate-total)=value) ∧ ((candidate-value)=total)
      {𝕊: total↩candidate}⍟exactAdd @
      {𝕊: state↩"error" ⋄ code↩"coefficient_sum_out_of_exact_range"}⍟(¬exactAdd) @
    }⍟(state≡"ok") @
  }¨coefficients
  {state⇐state,coefficient⇐(state≡"ok")⊑⟨empty,total⟩,code⇐code}
}

{Normalize⇐Normalize,Sum⇐Sum}
