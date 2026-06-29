# src_edit/plan_id.bqn
# Plan ID generation and validation logic.

loader ← •Import "../src_next/loader.bqn"
validate ← •Import "validate.bqn"

# ToLower: convert characters A-Z to a-z.
ToLower ⇐ { ((𝕩 ≥ 'A') ∧ (𝕩 ≤ 'Z')) ? 𝕩 + 32 ; 𝕩 } ¨

# IsSlugChar: check if character is a-z or 0-9.
IsSlugChar ⇐ { ((𝕩 ≥ 'a') ∧ (𝕩 ≤ 'z')) ∨ ((𝕩 ≥ '0') ∧ (𝕩 ≤ '9')) }

# ReplaceNonSlug: replace non-slug characters with '-'.
ReplaceNonSlug ⇐ { (IsSlugChar 𝕩) ? 𝕩 ; '-' } ¨

# CollapseHyphens: collapse consecutive hyphens.
CollapseHyphens ⇐ { (0 = ≠𝕩) ? 𝕩 ; mask ← ('-' = 𝕩) ∧ ⟨0⟩ ∾ ¯1↓ ('-' = 𝕩) ⋄ (¬mask) / 𝕩 }

# TrimStart: trim leading hyphen.
TrimStart ⇐ { (0 = ≠𝕩) ? 𝕩 ; ('-' = ⊑𝕩) ? 1↓𝕩 ; 𝕩 }

# TrimEnd: trim trailing hyphen.
TrimEnd ⇐ { (0 = ≠𝕩) ? 𝕩 ; ('-' = ⊑⌽𝕩) ? 1↓⌽𝕩 ; ⌽𝕩 }

# TrimHyphens: trim leading and trailing hyphens.
TrimHyphens ⇐ { ⌽ TrimEnd TrimStart 𝕩 }

# Slugify: convert string to slug.
Slugify ⇐ {
  lowered ← ToLower 𝕩
  replaced ← ReplaceNonSlug lowered
  collapsed ← CollapseHyphens replaced
  trimmed ← TrimHyphens collapsed
  { (0 = ≠trimmed) ? "plan" ; trimmed }
}

# StartsWith helper.
StartsWith ⇐ { 𝕨 ≡ (≠ 𝕨) ↑ 𝕩 }

# Join list of strings with a separator.
Join ⇐ {
  sep ← 𝕨
  list ← 𝕩
  (0 = ≠ list) ◶ ⟨ { 𝕊 ⋄ 1↓ ∾ (sep ⊸ ∾) ¨ list }, { 𝕊 ⋄ ""} ⟩ @
}

# ValidatePlanIDFormat: validate plan-YYYY-MM-DD-series format.
# Returns ⟨1, ""⟩ or ⟨0, "error"⟩.
ValidatePlanIDFormat ⇐ {
  planID ← 𝕩
  prefixOk ← "plan-" StartsWith planID
  parts ← prefixOk ◶ ⟨ { 𝕊 ⋄ ⟨⟩ }, { 𝕊 ⋄ '-' loader.SplitKeepEmpty planID } ⟩ @
  lenOk ← prefixOk ◶ ⟨ { 𝕊 ⋄ 0 }, { 𝕊 ⋄ 5 ≤ ≠ parts } ⟩ @
  
  dateStr ← lenOk ◶ ⟨ { 𝕊 ⋄ "" }, { 𝕊 ⋄ (1⊑parts) ∾ "-" ∾ (2⊑parts) ∾ "-" ∾ (3⊑parts) } ⟩ @
  dateCheck ← lenOk ◶ ⟨ { 𝕊 ⋄ ⟨0, ""⟩ }, { 𝕊 ⋄ validate.ValidateDate dateStr } ⟩ @
  dateOk ← lenOk ◶ ⟨ { 𝕊 ⋄ 0 }, { 𝕊 ⋄ 0 ⊑ dateCheck } ⟩ @
  
  seriesParts ← lenOk ◶ ⟨ { 𝕊 ⋄ ⟨⟩ }, { 𝕊 ⋄ 4 ↓ parts } ⟩ @
  series ← lenOk ◶ ⟨ { 𝕊 ⋄ "" }, { 𝕊 ⋄ "-" Join seriesParts } ⟩ @
  seriesOk ← lenOk ◶ ⟨ { 𝕊 ⋄ 0 }, { 𝕊 ⋄ 0 < ≠ series } ⟩ @
  
  {
    (¬ prefixOk) ? ⟨0, "plan_id must start with 'plan-': " ∾ planID⟩ ;
    (¬ lenOk) ? ⟨0, "plan_id must have format plan-YYYY-MM-DD-series: " ∾ planID⟩ ;
    (¬ dateOk) ? ⟨0, "plan_id contains invalid date: " ∾ planID⟩ ;
    (¬ seriesOk) ? ⟨0, "plan_id must have non-empty series: " ∾ planID⟩ ;
    ⟨1, ""⟩
  }
}

# ExtractPlanId: extract plan_id from metadata or return "".
ExtractPlanId ⇐ {𝕊 line:
  flds ← loader.SplitTsvKeepEmpty line
  lenOk ← 5 < ≠ flds
  meta ← lenOk ◶ ⟨ { 𝕊 ⋄ ⟨⟩ }, { 𝕊 ⋄ 5 ↓ flds } ⟩ @
  IsPlanId ← { (8 ≤ ≠ 𝕩) ? "plan_id=" StartsWith 𝕩 ; 0 }
  cand ← lenOk ◶ ⟨ { 𝕊 ⋄ ⟨⟩ }, { 𝕊 ⋄ IsPlanId¨ meta } ⟩ @
  has ← lenOk ◶ ⟨ { 𝕊 ⋄ 0 }, { 𝕊 ⋄ ∨´ cand } ⟩ @
  val ← has ◶ ⟨ { 𝕊 ⋄ "" }, { 𝕊 ⋄ 8 ↓ (⊑ (cand / ↕ ≠ meta)) ⊑ meta } ⟩ @
  has ◶ ⟨ { 𝕊 ⋄ "" }, { 𝕊 ⋄ val } ⟩ @
}

# LoadExistingPlanIDs: load all plan IDs from plan.tsv and journal.tsv.
# Args: 𝕩 is namespace with plan_path and journal_path
# Returns: list of plan ID strings
LoadExistingPlanIDs ⇐ {
  planLines ← loader.ReadLinesOptional 𝕩.plan_path
  journalLines ← loader.ReadLinesOptional 𝕩.journal_path
  planIDs ← ExtractPlanId¨ planLines
  journalIDs ← ExtractPlanId¨ journalLines
  # Filter out empty IDs and de-duplicate
  allIDs ← planIDs ∾ journalIDs
  nonEmpty ← (0 < ≠¨ allIDs) / allIDs
  (0 = ≠ nonEmpty) ◶ ⟨ { 𝕊 ⋄ ((nonEmpty ⊐ nonEmpty) = ↕ ≠ nonEmpty) / nonEmpty}, { 𝕊 ⋄ ⟨⟩ } ⟩ @
}

# GeneratePlanID: generate a unique plan ID.
# Args: 𝕩 is namespace with date, memo, meta, existing_ids (list of strings)
# Returns: generated plan ID string
GeneratePlanID ⇐ {
  opts ← 𝕩
  IsSeries ← { (7 ≤ ≠ 𝕩) ? "series=" StartsWith 𝕩 ; 0 }
  cand ← IsSeries¨ opts.meta
  has ← ∨´ cand
  series ← has ◶ ⟨ { 𝕊 ⋄ "" }, { 𝕊 ⋄ 7 ↓ (⊑ (cand / ↕ ≠ opts.meta)) ⊑ opts.meta } ⟩ @
  source ← (0 < ≠ series) ◶ ⟨ { 𝕊 ⋄ opts.memo }, { 𝕊 ⋄ series } ⟩ @
  slug ← Slugify source
  base ← "plan-" ∾ opts.date ∾ "-" ∾ slug
  
  exists ← ∨´ base ⊸ ≡¨ opts.existing_ids
  
  # Find next non-colliding index
  FindNext ← {𝕊 i:
    Pad2 ← { s ← •Fmt 𝕩 ⋄ ((0 ⌈ 2-≠s)⥊'0') ∾ s }
    candidate ← base ∾ "-" ∾ Pad2 i
    (¬ (∨´ candidate ⊸ ≡¨ opts.existing_ids)) ◶ ⟨ { 𝕊 ⋄ FindNext i+1 }, { 𝕊 ⋄ candidate } ⟩ @
  }
  
  exists ◶ ⟨ { 𝕊 ⋄ base }, { 𝕊 ⋄ FindNext 2 } ⟩ @
}
