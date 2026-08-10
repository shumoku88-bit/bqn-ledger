# plan_temporal_status.bqn
# Pure temporal status projection for open Plan rows.
#
# Input:
#   plan_date‿as_of
#
# Output vocabulary:
#   future / due / overdue
#
# Completion belongs to the Plan Completion Join. No formatting, envelope logic,
# source mutation, observation defaulting, or wall-clock reads live here.

date ← •Import "../ledger/date_ordinal.bqn"

Classify ← {𝕊 planDate‿asOf:
  planDn ← date.Ordinal planDate
  asOfDn ← date.Ordinal asOf
  openIdx ← (planDn = asOfDn) + (2 × planDn > asOfDn)
  openIdx ⊑ ⟨"overdue", "due", "future"⟩
}

{ Classify ⇐ Classify }
