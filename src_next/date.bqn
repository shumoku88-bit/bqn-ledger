# date.bqn
# Small date helpers for report/outlook logic (not accounting core).
# Migrated from old src/core/date.bqn.

lib ← •Import "util.bqn"

digits ← "0123456789"
IsDigits ← { (0 < ≠ 𝕩) ∧ ∧´ (𝕩 ∊ digits) }
IsLeap ← {𝕊 y: ((0 = 4 | y) ∧ (0 ≠ 100 | y)) ∨ (0 = 400 | y) }

ShOut ← { ¯1 ↓ 1 ⊑ •SH 𝕩 }
Today ← { 𝕊 ⋄ ShOut ⟨"date", "+%Y-%m-%d"⟩ }

# YYYY-MM-DD -> ⟨year, month, day⟩
Parts ← {
  s ← 𝕩
  ⟨ lib.ToNum 4 ↑ s, lib.ToNum 2 ↑ 5 ↓ s, lib.ToNum 2 ↑ 8 ↓ s ⟩
}

# Strict YYYY-MM-DD shape and Gregorian calendar validation.
IsValidDateText ← {𝕊 s:
  okShape ← 0
  {𝕊: okShape ↩ ('-' = 4⊑s) ∧ ('-' = 7⊑s) }⍟(10 = ≠ s) @
  okDigits ← 0
  {𝕊: okDigits ↩ (IsDigits 4↑s) ∧ (IsDigits 2↑5↓s) ∧ (IsDigits 2↑8↓s) }⍟okShape @
  r ← 0
  {𝕊:
    y‿m‿d ← Parts s
    monthOk ← (1 ≤ m) ∧ (m ≤ 12)
    maxDay ← 0
    {𝕊:
      mdays ← ⟨31, 28 + IsLeap y, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31⟩
      maxDay ↩ (m-1)⊑mdays
    }⍟monthOk @
    r ↩ monthOk ∧ (1 ≤ d) ∧ (d ≤ maxDay)
  }⍟okDigits @
  r
}

# Proleptic Gregorian day number. Absolute origin is arbitrary; differences are meaningful.
# Based on the standard days-from-civil formula.
Ordinal ← {
  y ‿ m ‿ d ← Parts 𝕩
  y2 ← y - m ≤ 2
  era ← ⌊ y2 ÷ 400
  yoe ← y2 - 400 × era
  mp ← m + (m ≤ 2) ⊑ ⟨ ¯3, 9 ⟩
  doy ← (⌊ (2 + 153 × mp) ÷ 5) + d - 1
  doe ← doy + (365 × yoe) + (⌊ yoe ÷ 4) - (⌊ yoe ÷ 100)
  doe + 146097 × era
}

# ⟨start_date, end_date⟩ -> end ordinal - start ordinal
DaysBetween ← {
  s ‿ e ← 𝕩
  (Ordinal e) - Ordinal s
}

# Legacy projection day number: days since year 0-01-01.
# Keep this here as the single implementation for cube/TBDS day arithmetic.
DaysFromEpoch ← {𝕊 s:
  y‿m‿d ← Parts s
  leaps ← (⌊y÷4) - (⌊y÷100) + (⌊y÷400)
  yearDays ← (y × 365) + leaps
  moOffs ← ⟨0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334⟩
  moDays ← (m-1) ⊑ moOffs
  leapCorr ← ((IsLeap y) ∧ m > 2) ⊑ ⟨0, 1⟩
  yearDays + moDays + leapCorr + d - 1
}

# Inverse of DaysFromEpoch.
FromDaysFromEpoch ← {𝕊 tdn:
  YearLen ← {𝕊 yy: (IsLeap yy) ⊑ 365‿366 }
  Leaps ← {𝕊 yy: (⌊yy÷4) - (⌊yy÷100) + (⌊yy÷400) }
  y0 ← ⌊ tdn ÷ 365
  days_to_y0 ← (y0 × 365) + (Leaps y0)
  y ← y0 - (days_to_y0 > tdn)
  cum ← (y × 365) + (Leaps y)
  {𝕊:
    yl ← YearLen y
    cum2 ← cum + yl
    {𝕊: y ↩ y + 1 ⋄ cum ↩ cum2 }⍟(cum2 ≤ tdn) @
  }⍟((cum + (YearLen y)) ≤ tdn) @
  rem ← tdn - cum
  mdays ← ⟨31, 28 + IsLeap y, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31⟩
  cum_m ← +` (0 ∾ mdays)
  m_idx ← ⊑ (cum_m > rem) ⊐ ⟨1⟩
  m ← m_idx
  r ← rem - (m_idx - 1) ⊑ cum_m
  d ← r + 1
  Pad2 ← { ss ← •Fmt 𝕩 ⋄ ((0 ⌈ 2 - ≠ ss) ⥊ "0") ∾ ss }
  (•Fmt y) ∾ "-" ∾ (Pad2 m) ∾ "-" ∾ (Pad2 d)
}

AddDays ← {𝕊 date‿n:
  result ← "unavailable"
  {𝕊: result ↩ FromDaysFromEpoch (n + DaysFromEpoch date) }⍟(date ≢ "unavailable") @
  result
}

# Convert proleptic Gregorian ordinal number back to YYYY-MM-DD
FromOrdinal ← {
  z ← 𝕩
  z ↩ z - 0
  era ← ⌊ (z - (z < 0)) ÷ 146097
  doe ← z - era × 146097
  yoe ← ⌊ ((doe - (⌊ doe ÷ 1460) + (⌊ doe ÷ 36524) - (⌊ doe ÷ 146096)) ÷ 365)
  y ← yoe + (era × 400)
  doy ← doe - ((365 × yoe) + (⌊ yoe ÷ 4) - (⌊ yoe ÷ 100))
  mp ← ⌊ (((5 × doy) + 2) ÷ 153)
  d ← (doy - (⌊ (((153 × mp) + 2) ÷ 5))) + 1
  m ← mp + ((mp < 10) ⊑ ⟨ ¯9, 3 ⟩)
  y ↩ y + (m ≤ 2)
  
  Pad ← { s ← •Fmt 𝕩 ⋄ ((0 ⌈ 2-≠s)⥊'0') ∾ s }
  (•Fmt y) ∾ "-" ∾ (Pad m) ∾ "-" ∾ (Pad d)
}

{ Today ⇐ Today, Parts ⇐ Parts, IsDigits ⇐ IsDigits, IsLeap ⇐ IsLeap, IsValidDateText ⇐ IsValidDateText, Ordinal ⇐ Ordinal, DaysBetween ⇐ DaysBetween, DaysFromEpoch ⇐ DaysFromEpoch, FromDaysFromEpoch ⇐ FromDaysFromEpoch, AddDays ⇐ AddDays, FromOrdinal ⇐ FromOrdinal }
