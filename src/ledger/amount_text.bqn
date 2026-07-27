# Exact coefficient/scale text formatting for canonical ledger consumers.
# No currency symbol, grouping, rounding, color, or report policy.

Format ← {𝕊 coefficient‿scale:
  negative ← coefficient<0
  digits ← •Fmt |coefficient
  needed ← (scale+1)-≠digits
  padded ← ((0⌈needed)⥊'0')∾digits
  body ← padded
  {𝕊:
    split ← (≠padded)-scale
    body↩(split↑padded)∾"."∾split↓padded
  }⍟(0<scale) @
  ((negative)/"-")∾body
}

{Format⇐Format}
