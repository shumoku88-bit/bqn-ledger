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
    monthDays ← ⟨31,28+IsLeap y,31,30,31,30,31,31,30,31,30,31⟩
    monthIndex ← ⊑((1+↕12)⊐⟨m⟩)
    maxDay ← monthIndex⊑(monthDays∾0)
    valid ↩ (monthIndex<≠monthDays) ∧ (1 ≤ d) ∧ d ≤ maxDay
  }⍟digitsOk @
  valid
}

FromParts ← {𝕊 y‿m‿d:
  Pad ← {𝕊 width‿value: text←•Fmt value ⋄ ((0⌈width-≠text)⥊'0')∾text}
  (Pad ⟨4,y⟩)∾"-"∾(Pad ⟨2,m⟩)∾"-"∾Pad ⟨2,d⟩
}

Ordinal ← {𝕊 text:
  y‿m‿d ← Parts text
  y2 ← y - m ≤ 2
  era ← ⌊ y2 ÷ 400
  yoe ← y2 - 400 × era
  mp ← m + (m ≤ 2) ⊑ ⟨¯3,9⟩
  doy ← (⌊ (2 + 153 × mp) ÷ 5) + d - 1
  doe ← ((doy + 365 × yoe) + ⌊ yoe ÷ 4) - ⌊ yoe ÷ 100
  doe + 146097 × era
}

# Exact inverse of Ordinal for nonnegative supported civil-date coordinates.
FromOrdinal ← {𝕊 ordinal:
  era ← ⌊ordinal÷146097
  doe ← ordinal-146097×era
  adjusted ← ((doe-⌊doe÷1460)+(⌊doe÷36524))-⌊doe÷146096
  yoe ← ⌊adjusted÷365
  y ← yoe+400×era
  yearDays ← ((365×yoe)+(⌊yoe÷4))-⌊yoe÷100
  doy ← doe-yearDays
  mp ← ⌊(2+5×doy)÷153
  d ← 1+doy-⌊(2+153×mp)÷5
  m ← mp+(mp<10)⊑⟨¯9,3⟩
  FromParts ⟨y+(m≤2),m,d⟩
}
AddDays ← {𝕊 text‿delta: FromOrdinal delta+Ordinal text}

# Shift an exact Gregorian coordinate by whole calendar months. Preserve the
# day-of-month when the target month has it; otherwise clip to that month end.
# This is date-coordinate meaning, not terminal/UI policy.
MonthIndex ← {𝕊 y‿m: (12×y)+m-1}
MonthParts ← {𝕊 index: ⟨⌊index÷12,1+12|index⟩}
AddMonths ← {𝕊 text‿delta:
  y‿m‿d ← Parts text
  targetIndex ← delta+MonthIndex ⟨y,m⟩
  targetYear‿targetMonth ← MonthParts targetIndex
  nextYear‿nextMonth ← MonthParts 1+targetIndex
  targetStart ← FromParts ⟨targetYear,targetMonth,1⟩
  nextStart ← FromParts ⟨nextYear,nextMonth,1⟩
  maxDay ← (Ordinal nextStart)-Ordinal targetStart
  FromParts ⟨targetYear,targetMonth,d⌊maxDay⟩
}

{IsValid⇐IsValid,Ordinal⇐Ordinal,FromOrdinal⇐FromOrdinal,AddDays⇐AddDays,AddMonths⇐AddMonths,Parts⇐Parts,FromParts⇐FromParts}
