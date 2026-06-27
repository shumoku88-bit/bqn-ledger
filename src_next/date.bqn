# date.bqn
# Small date helpers for report/outlook logic (not accounting core).
# Migrated from old src/core/date.bqn.

lib ← •Import "util.bqn"

ShOut ← { ¯1 ↓ 1 ⊑ •SH 𝕩 }
Today ← { 𝕊 ⋄ ShOut ⟨"date", "+%Y-%m-%d"⟩ }

# YYYY-MM-DD -> ⟨year, month, day⟩
Parts ← {
  s ← 𝕩
  ⟨ lib.ToNum 4 ↑ s, lib.ToNum 2 ↑ 5 ↓ s, lib.ToNum 2 ↑ 8 ↓ s ⟩
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

{ Today ⇐ Today, Parts ⇐ Parts, Ordinal ⇐ Ordinal, DaysBetween ⇐ DaysBetween, FromOrdinal ⇐ FromOrdinal }
