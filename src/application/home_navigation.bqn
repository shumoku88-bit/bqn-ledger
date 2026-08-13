# Pure Home logical movement over an admitted selected Gregorian date.
# Physical keys, mouse events, rendering coordinates, and Household I/O remain
# outside this owner.

dates ← •Import "../ledger/date_ordinal.bqn"

moves ← ⟨"day-prev","day-next","week-prev","week-next","month-prev","month-next"⟩
deltas ← ⟨¯1,1,¯7,7,¯1,1⟩

ValidMove ← {𝕊 move: ∨´move⊸≡¨moves}

# Inputs are admitted by the application boundary. Day/week moves are continuous
# Gregorian date movement; month moves retain date_ordinal.AddMonths clipping.
MoveDate ← {𝕊 date‿move:
  i ← ⊑(move⊸≡¨moves)⊐1
  delta ← i⊑deltas
  result ← dates.AddDays ⟨date,delta⟩
  {𝕊:result↩dates.AddMonths ⟨date,delta⟩}⍟(i≥4) @
  result
}

{ValidMove⇐ValidMove,MoveDate⇐MoveDate}
