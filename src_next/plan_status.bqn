# plan_status.bqn
# Pure temporal status projection for plan rows.
#
# Input:
#   completed‿plan_date‿as_of
#
# Output vocabulary is intentionally compatible with planned_payments:
#   future / due / overdue / completed
#
# No formatting, envelope logic, source mutation, or wall-clock reads.

date ← •Import "date.bqn"

Classify ← {𝕊 completed‿planDate‿asOf:
  planDn ← date.DaysFromEpoch planDate
  asOfDn ← date.DaysFromEpoch asOf
  openIdx ← (planDn = asOfDn) + (2 × planDn > asOfDn)
  openStatus ← openIdx ⊑ ⟨"overdue", "due", "future"⟩
  completed ⊑ ⟨openStatus, "completed"⟩
}

{ Classify ⇐ Classify }
