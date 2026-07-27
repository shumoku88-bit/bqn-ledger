# exact_decimal.bqn
# Pure exact-decimal source parser for Currency Stage 2 Slice A.
#
# Accepted grammar:
#   digits+
#   digits+ "." digits+
#
# The source decimal text is never parsed directly as a generic decimal Number.
# Instead, validated digit text is canonicalized to coefficient + scale, then
# the digit-only coefficient is converted and admitted only when the current
# BQN runtime formats it back to the identical canonical integer text.

digits ← "0123456789"
dot ← ⊑ "."
zero ← ⊑ "0"

IsDigits ← { (0 < ≠ 𝕩) ∧ ∧´ (𝕩 ∊ digits) }

TrimLeadingZeros ← {𝕊 xs:
  zeroPrefix ← ∧` (xs = zero)
  dropCount ← +´ zeroPrefix
  trimmed ← dropCount ↓ xs
  (0 = ≠ trimmed) ◶ ⟨{𝕩}, {𝕩 ⋄ "0"}⟩ trimmed
}

TrimTrailingZeros ← {𝕊 xs:
  zeroSuffix ← ∧` ((⌽ xs) = zero)
  keepCount ← (≠ xs) - +´ zeroSuffix
  keepCount ↑ xs
}

Failure ← {𝕊 sourceText‿stateText‿messageText:
  empty ← ⟨⟩
  {
    state ⇐ stateText,
    coefficient ⇐ empty,
    scale ⇐ empty,
    source_text ⇐ sourceText,
    message ⇐ messageText
  }
}

TryInteger ← {𝕩 ⋄ parsedValue ← •BQN 𝕩 ⋄ {ok⇐1, value⇐parsedValue}}⎊{𝕩 ⋄ {ok⇐0, value⇐0}}

ConvertExactInteger ← {𝕊 coefficientText:
  parsed ← TryInteger coefficientText
  exact ← parsed.ok ∧ (coefficientText ≡ •Fmt parsed.value)
  parsedValue ← parsed.value
  {ok⇐exact, value⇐parsedValue}
}

InvalidSyntax ← {𝕊 s:
  Failure ⟨s, "invalid_syntax", "invalid_decimal_syntax"⟩
}

OutOfRangeResult ← {𝕊 s‿scale‿conv:
  Failure ⟨s, "out_of_exact_range", "amount_out_of_exact_range"⟩
}

SuccessResult ← {𝕊 s‿scale‿conv:
  coefficientValue ← conv.value
  {
    state ⇐ "ok",
    coefficient ⇐ coefficientValue,
    scale ⇐ scale,
    source_text ⇐ s,
    message ⇐ ""
  }
}

ParseValid ← {𝕊 s:
  dotMask ← s = dot
  prefixDots ← +` dotMask
  intMask ← (prefixDots = 0) ∧ (¬ dotMask)
  fracMask ← (prefixDots = 1) ∧ (¬ dotMask)
  intText ← intMask / s
  fracText ← fracMask / s
  fracCanonical ← TrimTrailingZeros fracText
  coefficientText ← TrimLeadingZeros (intText ∾ fracCanonical)
  scale ← ≠ fracCanonical
  conv ← ConvertExactInteger coefficientText
  conv.ok ◶ ⟨OutOfRangeResult, SuccessResult⟩ ⟨s, scale, conv⟩
}

Parse ← {𝕊 s:
  n ← ≠ s
  dotMask ← s = dot
  dotCount ← +´ dotMask
  allowed ← ∧´ ((s ∊ digits) ∨ dotMask)
  firstIsDot ← dot = ⊑ (s ∾ ".")
  lastIsDot ← dot = ¯1 ⊑ ("." ∾ s)
  oneDotOk ← (dotCount = 1) ∧ (¬ firstIsDot) ∧ (¬ lastIsDot)
  shapeOk ← (dotCount = 0) ∨ oneDotOk
  syntaxOk ← (0 < n) ∧ allowed ∧ shapeOk
  syntaxOk ◶ ⟨InvalidSyntax, ParseValid⟩ s
}

{
  Parse ⇐ Parse
}
