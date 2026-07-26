# source_fields.bqn
# Pure bounded access to already-split source-row fields.
#
# This owner does not read files, split TSV text, parse scalar values, or know
# Posting IR, Layer, cycle, report, or household policy.

FieldOrEmpty ← {𝕊 flds‿i:
  (i < ≠ flds) ? (i ⊑ flds) ; ""
}

{
  FieldOrEmpty ⇐ FieldOrEmpty
}
