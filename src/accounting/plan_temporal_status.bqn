# plan_temporal_status.bqn
# Pure temporal status projection for plan rows.
#
# Input:
#   completed‿plan_date‿as_of
#
# Output vocabulary is intentionally compatible with planned_payments:
#   future / due / overdue / completed
#
# No formatting, envelope logic, source mutation, or wall-clock reads.

date ← •Import "../ledger/date_ordinal.bqn"

Classify ← {𝕊 completed‿planDate‿asOf:
  planDn ← date.Ordinal planDate
  asOfDn ← date.Ordinal asOf
  openIdx ← (planDn = asOfDn) + (2 × planDn > asOfDn)
  openStatus ← openIdx ⊑ ⟨"overdue", "due", "future"⟩
  completed ⊑ ⟨openStatus, "completed"⟩
}

{ Classify ⇐ Classify }
