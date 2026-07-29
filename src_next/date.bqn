# date.bqn
# Shared Gregorian date text, validation, arithmetic, and clock helpers.
# Migrated from old src/core/date.bqn.

lib ← •Import "../src/text/parse.bqn"

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

# Convert proleptic Gregorian ordinal number back to YYYY-MM-DD.
# Intermediate assignments make the standard 400-year formula explicit under
# BQN's right-to-left evaluation.
FromOrdinal ← {
  z ← 𝕩
  z ↩ z - 0
  era ← ⌊ (z - (z < 0)) ÷ 146097
  doe ← z - era × 146097
  yoeNumerator ← (doe - (⌊ doe ÷ 1460)) + (⌊ doe ÷ 36524)
  yoeNumerator ↩ yoeNumerator - (⌊ doe ÷ 146096)
  yoe ← ⌊ yoeNumerator ÷ 365
  y ← yoe + (era × 400)
  doy ← doe - ((365 × yoe) + (⌊ yoe ÷ 4) - (⌊ yoe ÷ 100))
  mp ← ⌊ (((5 × doy) + 2) ÷ 153)
  d ← (doy - (⌊ (((153 × mp) + 2) ÷ 5))) + 1
  m ← mp + ((mp < 10) ⊑ ⟨ ¯9, 3 ⟩)
  y ↩ y + (m ≤ 2)
  
  Pad ← { s ← •Fmt 𝕩 ⋄ ((0 ⌈ 2-≠s)⥊'0') ∾ s }
  (•Fmt y) ∾ "-" ∾ (Pad m) ∾ "-" ∾ (Pad d)
}

# Number of leap days represented before January 1 of year y in the legacy
# epoch coordinate. Explicit grouping keeps the 400-year term additive.
LeapsBeforeYear ← {𝕊 y:
  (((⌊y÷4) - (⌊y÷100)) + (⌊y÷400)) - ((0 < y) ∧ IsLeap y)
}

# Legacy projection day number: days since year 0-01-01.
# Keep the existing month indexing and malformed-source failure behavior.
DaysFromEpoch ← {𝕊 s:
  y‿m‿d ← Parts s
  yearDays ← (y × 365) + LeapsBeforeYear y
  moOffs ← ⟨0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334⟩
  moDays ← (m-1) ⊑ moOffs
  leapCorr ← ((IsLeap y) ∧ m > 2) ⊑ ⟨0, 1⟩
  yearDays + moDays + leapCorr + d - 1
}

# Inverse of DaysFromEpoch. Positive years use the stable offset between the
# corrected legacy epoch coordinate and the Gregorian ordinal coordinate.
FromDaysFromEpoch ← {𝕊 tdn:
  offset ← (tdn < 365) ⊑ 59‿60
  FromOrdinal (tdn - offset)
}

AddDays ← {𝕊 date‿n:
  result ← "unavailable"
  {𝕊: result ↩ FromDaysFromEpoch (n + DaysFromEpoch date) }⍟(date ≢ "unavailable") @
  result
}

{ Today ⇐ Today, Parts ⇐ Parts, IsDigits ⇐ IsDigits, IsLeap ⇐ IsLeap, IsValidDateText ⇐ IsValidDateText, Ordinal ⇐ Ordinal, DaysBetween ⇐ DaysBetween, DaysFromEpoch ⇐ DaysFromEpoch, FromDaysFromEpoch ⇐ FromDaysFromEpoch, AddDays ⇐ AddDays, FromOrdinal ⇐ FromOrdinal }
