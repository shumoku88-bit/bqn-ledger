# src_edit/render.bqn
# Live Issue TSV renderers used by Issue Add.
# This module only produces string output. It does not write files.

# Join list of strings with a separator.
Join ← {
  sep ← 𝕨
  list ← 𝕩
  (0 = ≠ list) ◶ ⟨ { 𝕊 ⋄ 1↓ ∾ (sep ⊸ ∾) ¨ list }, { 𝕊 ⋄ ""} ⟩ @
}

# Build one retained legacy eight-column Issues row.
RenderIssueRow ⇐ {
  fields ← 𝕩.issue_id‿𝕩.status‿𝕩.date‿𝕩.category‿𝕩.title‿𝕩.amount‿𝕩.currency‿𝕩.details
  (@+9) Join fields
}

# Build one bounded nine-column Issues row with an explicit due coordinate.
RenderIssueRowWithDue ⇐ {
  fields ← 𝕩.issue_id‿𝕩.status‿𝕩.date‿𝕩.due‿𝕩.category‿𝕩.title‿𝕩.amount‿𝕩.currency‿𝕩.details
  (@+9) Join fields
}

# Build one current ten-column Issues row with explicit due and close lifecycle.
RenderIssueRowWithClosed ⇐ {
  fields ← 𝕩.issue_id‿𝕩.status‿𝕩.date‿𝕩.due‿𝕩.closed‿𝕩.category‿𝕩.title‿𝕩.amount‿𝕩.currency‿𝕩.details
  (@+9) Join fields
}
