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
  prefixes ← +` 0∾coefficients
  previous ← ¯1↓prefixes
  candidates ← 1↓prefixes
  exactAdds ← ((candidates-previous)=coefficients) ∧ ((candidates-coefficients)=previous)
  allExact ← ∧´1∾exactAdds
  total ← ¯1⊑prefixes
  {
    state⇐allExact⊑"error"‿"ok",
    coefficient⇐allExact⊑⟨empty,total⟩,
    code⇐allExact⊑"coefficient_sum_out_of_exact_range"‿""
  }
}

{Normalize⇐Normalize,Sum⇐Sum}
