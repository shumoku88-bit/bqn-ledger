# src_edit/render.bqn
# Render validated edit inputs into TSV row strings.
# Replicates Go editor's buildJournalLikeRow + appendRowContent behavior.
#
# This module only produces string output. It does not write files.

lib ← •Import "../src_next/util.bqn"

# Join list of strings with a separator.
Join ← {
  sep ← 𝕨
  list ← 𝕩
  (0 = ≠ list) ◶ ⟨ { 𝕊 ⋄ 1↓ ∾ (sep ⊸ ∾) ¨ list }, { 𝕊 ⋄ ""} ⟩ @
}

# Build a TSV row string from add options.
# 𝕩: namespace with date, memo, from, to, amount, meta
# Returns: tab-separated string (no trailing newline)
RenderJournalRow ⇐ {
  fields ← 𝕩.date‿𝕩.memo‿𝕩.from‿𝕩.to‿𝕩.amount
  allFields ← fields ∾ 𝕩.meta
  tab ← @+9
  tab Join allFields
}

# Build a TSV row for an issue add.
# 𝕩: namespace with date, status, title, amount, memo
# Returns: tab-separated string (no trailing newline)
RenderIssueRow ⇐ {
  fields ← 𝕩.date‿𝕩.status‿𝕩.title‿𝕩.amount‿𝕩.memo
  tab ← @+9
  tab Join fields
}
