# Pure strict ISO Gregorian date coordinate used by canonical ledger facts.
# No clock, formatting policy, source I/O, or compatibility date shape lives here.

digits ← "0123456789"
IsDigits ← { (0 < ≠𝕩) ∧ ∧´ 𝕩 ∊ digits }
ToNum ← { +´ (𝕩 - ⊑"0") × 10 ⋆ ⌽ ↕ ≠𝕩 }
IsLeap ← {𝕊 y: ((0 = 4 | y) ∧ (0 ≠ 100 | y)) ∨ 0 = 400 | y }

Parts ← {𝕊 text:
  ⟨ToNum 4↑text, ToNum 2↑5↓text, ToNum 2↑8↓text⟩
}

IsValid ← {𝕊 text:
  shapeOk ← (10 = ≠text) ∧ ('-' = 4⊑text∾11⥊' ') ∧ ('-' = 7⊑text∾11⥊' ')
  digitsOk ← 0
  {𝕊: digitsOk ↩ (IsDigits 4↑text) ∧ (IsDigits 2↑5↓text) ∧ IsDigits 2↑8↓text}⍟shapeOk @
  valid ← 0
  {𝕊:
    y‿m‿d ← Parts text
    monthOk ← (1 ≤ m) ∧ m ≤ 12
    maxDay ← 0
    {𝕊: maxDay ↩ (m-1)⊑⟨31,28+IsLeap y,31,30,31,30,31,31,30,31,30,31⟩}⍟monthOk @
    valid ↩ monthOk ∧ (1 ≤ d) ∧ d ≤ maxDay
  }⍟digitsOk @
  valid
}

FromParts ← {𝕊 y‿m‿d:
  Pad2 ← {𝕊 value: text←•Fmt value ⋄ ((0⌈2-≠text)⥊'0')∾text}
  (•Fmt y)∾"-"∾(Pad2 m)∾"-"∾Pad2 d
}

Ordinal ← {𝕊 text:
  y‿m‿d ← Parts text
  y2 ← y - m ≤ 2
  era ← ⌊ y2 ÷ 400
  yoe ← y2 - 400 × era
  mp ← m + (m ≤ 2) ⊑ ⟨¯3,9⟩
  doy ← (⌊ (2 + 153 × mp) ÷ 5) + d - 1
  doe ← doy + 365 × yoe + (⌊ yoe ÷ 4) - ⌊ yoe ÷ 100
  doe + 146097 × era
}

{IsValid⇐IsValid,Ordinal⇐Ordinal,Parts⇐Parts,FromParts⇐FromParts}
