# src_edit/render.bqn
# Render validated edit inputs into TSV row strings.
#
# This module only produces string output. It does not write files.

lib ← •Import "../src_next/util.bqn"

# Join list of strings with a separator.
Join ← {
  sep ← 𝕨
  list ← 𝕩
  (0 = ≠ list) ◶ ⟨ { 𝕊 ⋄ 1↓ ∾ (sep ⊸ ∾) ¨ list }, { 𝕊 ⋄ ""} ⟩ @
}

# Build a validated accounts.tsv row. role and currency are always explicit;
# type is an optional controlled asset classification. Currency is appended after
# the pre-M2 role/type order so existing editor presentation remains stable.
RenderAccountRow ⇐ {
  fields ← ⟨𝕩.name, "role=" ∾ 𝕩.role⟩
  fields ∾↩ (0 < ≠𝕩.type) / ⟨"type=" ∾ 𝕩.type⟩
  fields ∾↩ ⟨"currency=" ∾ 𝕩.currency⟩
  (@+9) Join fields
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
RenderIssueRow ⇐ {
  fields ← 𝕩.date‿𝕩.status‿𝕩.title‿𝕩.amount‿𝕩.memo
  tab ← @+9
  tab Join fields
}
