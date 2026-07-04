# json.bqn — JSON serialization helper for BQN report ViewModels
# Supports numbers, characters, strings, arrays, and objects (lists of key-value pairs).
# Unsupported values fail closed instead of silently becoming JSON null.

quote ← @+34
backslash ← @+92
backspace ← @+8
tab ← @+9
newline ← @+10
formfeed ← @+12
carriage_return ← @+13
space ← @+32

Fail ← {𝕊 msg:
  •Out "ERROR: json serialization failed: " ∾ msg
  •Exit 1
}

EscapeChar ← {𝕊 c:
  (c=quote) ? backslash∾quote ;
  (c=backslash) ? backslash∾backslash ;
  (c=backspace) ? backslash∾"b" ;
  (c=tab) ? backslash∾"t" ;
  (c=newline) ? backslash∾"n" ;
  (c=formfeed) ? backslash∾"f" ;
  (c=carriage_return) ? backslash∾"r" ;
  (c < space) ? Fail "unsupported control character" ;
  ⟨c⟩
}

# String formats string with double quotes and JSON escaping.
String ← {
  quote ∾ (∾ EscapeChar¨ 𝕩) ∾ quote
}

# Number formats BQN negative glyph ¯ as JSON minus -.
Number ← {
  s ← •Fmt 𝕩
  { 𝕩 ≡ '¯' ? '-' ; 𝕩 }¨ s
}

IsString ← {
  val ← 𝕩
  (0 = •Type val) ∧ (1 = ≡val) ∧ {𝕊: (0 = ≠val) ? ({ 2 = •Type (⊑ (1 ↑ val)) } ⎊ { 0 } val) ; 2 = •Type (⊑val) } @
}

IsScalarArray ← {
  (0 = •Type 𝕩) ∧ (0 = ≠≢𝕩)
}

DiscloseIfScalar ← {
  IsScalarArray 𝕩 ? ⊑𝕩 ; 𝕩
}

IsKvPair ← {
  (0 = •Type DiscloseIfScalar 𝕩) ∧ (2 = ≠DiscloseIfScalar 𝕩) ∧ (IsString DiscloseIfScalar ⊑DiscloseIfScalar 𝕩)
}

Serialize_inner ← {
  arr ← 𝕩
  t ← •Type arr
  is_arr ← 0 = t
  is_obj ← {𝕊: is_arr ? ∧´ IsKvPair¨ arr ; 0 } @

  {𝕊:
    (1 = t) ? Number arr ;
    (2 = t) ? String ⟨arr⟩ ; # Single char to string
    (IsString arr) ? String arr ;

    # Array cases
    (is_arr ∧ (0 = ≠arr)) ? "[]" ;

    is_obj ? "{" ∾ (∾ {
      idx ← 𝕩
      pair ← DiscloseIfScalar (idx ⊑ arr)
      k ← DiscloseIfScalar (⊑pair)
      v ← DiscloseIfScalar (1⊑pair)
      delim ← (idx = 0) ⊑ ⟨", ", ""⟩
      delim ∾ (String k) ∾ ": " ∾ (Serialize v)
    }¨ ↕≠arr) ∾ "}" ;

    is_arr ? "[" ∾ (∾ {
      idx ← 𝕩
      v ← DiscloseIfScalar (idx ⊑ arr)
      delim ← (idx = 0) ⊑ ⟨", ", ""⟩
      delim ∾ Serialize v
    }¨ ↕≠arr) ∾ "]" ;

    Fail "unsupported value type"
  } @
}

# Entrypoint that automatically unwraps outer enclosed values.
Serialize ← {
  val ← DiscloseIfScalar 𝕩
  Serialize_inner val
}

{ Serialize ⇐ Serialize }
