# journal_canonical_surface_plan.bqn
# Pure classification and plan builder for Canonical Journal Surface 001.

util ← •Import "../src/text/parse.bqn"
parser ← •Import "../src/editor/journal_profile.bqn"

lf ← @+10
cr ← @+13
space ← @+32
empty ← ⟨⟩

TrimIndent ← {𝕊 line:
  hasCr ← (0<≠line) ∧ cr=¯1⊑(line ∾ " ")
  l ← line
  {𝕊: l ↩ ¯1↓l}⍟hasCr @
  prefix ← ∧` (l=space)
  indentCount ← +´prefix
  trimmed ← indentCount↓l
  {indent_count⇐indentCount, trimmed⇐trimmed, has_cr⇐hasCr}
}

AnalyzePostingLine ← {𝕊 line:
  parsed ← TrimIndent line
  indentCount ← parsed.indent_count
  trimmed ← parsed.trimmed
  isPosting ← (indentCount > 0) ∧ (0 < ≠trimmed) ∧ (';' ≠ ⊑ (trimmed ∾ " "))

  spaceIndices ← (space = trimmed) / ↕≠trimmed
  hasSpace ← isPosting ∧ (0 < ≠spaceIndices)
  separatorIndex ← ⊑ (spaceIndices ∾ ⟨0⟩)
  separatorTail ← separatorIndex ↓ trimmed
  spaceLen ← +´ ∧` (space = separatorTail)

  isSingleSpace ← isPosting ∧ hasSpace ∧ (1 = spaceLen)
  isMultiSpace ← isPosting ∧ hasSpace ∧ (1 < spaceLen)
  isCanonical ← isPosting ∧ hasSpace ∧ (4 = indentCount) ∧ (4 = spaceLen)
  account ← separatorIndex ↑ trimmed
  amountPart ← (separatorIndex + spaceLen) ↓ trimmed

  {
    is_posting⇐isPosting,
    indent_count⇐indentCount,
    separator_index⇐separatorIndex,
    space_len⇐spaceLen,
    is_canonical⇐isCanonical,
    is_single_space⇐isSingleSpace,
    is_multi_space⇐isMultiSpace,
    account⇐account,
    amount_part⇐amountPart,
    has_cr⇐parsed.has_cr
  }
}

AnalyzeMetaLine ← {𝕊 line:
  parsed ← TrimIndent line
  indentCount ← parsed.indent_count
  trimmed ← parsed.trimmed
  isMeta ← (indentCount > 0) ∧ (0 < ≠trimmed) ∧ (';' = ⊑ (trimmed ∾ " "))
  isLayerActual ← isMeta ∧ (trimmed ≡ "; layer: actual")
  isCurrencyJpy ← isMeta ∧ (trimmed ≡ "; currency: JPY")
  {
    is_meta⇐isMeta,
    is_layer_actual⇐isLayerActual,
    is_currency_jpy⇐isCurrencyJpy,
    is_redundant⇐isLayerActual ∨ isCurrencyJpy
  }
}

ClassifyTransaction ← {
  rawLines‿tx ← 𝕩
  startLine ← tx.source_start_line
  endLine ← tx.source_end_line
  len ← 1 + (endLine - startLine)
  offset ← startLine - 1
  txLines ← len ↑ (offset ↓ rawLines)

  pInfos ← AnalyzePostingLine¨ txLines
  mInfos ← AnalyzeMetaLine¨ txLines

  isPostingList ← {𝕩.is_posting}¨ pInfos
  isSingleList ← {𝕩.is_single_space}¨ pInfos
  isMultiList ← {𝕩.is_multi_space}¨ pInfos
  isCanonList ← {𝕩.is_canonical}¨ pInfos

  postingCount ← +´ 0 ∾ isPostingList
  singleSpaceCount ← +´ 0 ∾ isSingleList
  multiSpaceCount ← +´ 0 ∾ isMultiList
  spacingFixCount ← +´ 0 ∾ (isPostingList ∧ ¬isCanonList)

  isLayerActualList ← {𝕩.is_layer_actual}¨ mInfos
  isCurrencyJpyList ← {𝕩.is_currency_jpy}¨ mInfos
  isRedundantList ← {𝕩.is_redundant}¨ mInfos

  layerActualCount ← +´ 0 ∾ isLayerActualList
  currencyJpyCount ← +´ 0 ∾ isCurrencyJpyList
  redundantMetaCount ← +´ 0 ∾ isRedundantList
  unsupportedCount ← 0

  hasSpacingFix ← 0 < spacingFixCount
  hasRedundantMeta ← 0 < redundantMetaCount
  classificationIndex ← hasSpacingFix + 2 × hasRedundantMeta
  classification ← classificationIndex ⊑ ⟨
    "canonical",
    "spacing_only",
    "redundant_metadata_only",
    "spacing_and_redundant_metadata"
  ⟩

  {
    classification⇐classification,
    posting_count⇐postingCount,
    single_space_count⇐singleSpaceCount,
    multi_space_count⇐multiSpaceCount,
    spacing_fix_count⇐spacingFixCount,
    layer_actual_count⇐layerActualCount,
    currency_jpy_count⇐currencyJpyCount,
    redundant_meta_count⇐redundantMetaCount,
    unsupported_count⇐unsupportedCount
  }
}

Build ← {𝕊 raw:
  cleaned ← (cr ≠ raw) / raw
  rawLines ← lf util.SplitKeepEmpty cleaned
  parsed ← parser.ParseWithProfile ⟨raw, "historical_external_plan"⟩

  diagnostics ← parsed.diagnostics
  transactions ← parsed.transactions

  txResults ← {ClassifyTransaction ⟨rawLines, 𝕩⟩}¨ transactions

  txCount ← ≠ transactions
  postingCount ← +´ 0 ∾ {𝕩.posting_count}¨ txResults
  singleSpaceCount ← +´ 0 ∾ {𝕩.single_space_count}¨ txResults
  multiSpaceCount ← +´ 0 ∾ {𝕩.multi_space_count}¨ txResults
  layerActualCount ← +´ 0 ∾ {𝕩.layer_actual_count}¨ txResults
  currencyJpyCount ← +´ 0 ∾ {𝕩.currency_jpy_count}¨ txResults

  canonicalCount ← +´ 0 ∾ {𝕩.classification ≡ "canonical"}¨ txResults
  spacingOnlyCount ← +´ 0 ∾ {𝕩.classification ≡ "spacing_only"}¨ txResults
  redundantMetaOnlyCount ← +´ 0 ∾ {𝕩.classification ≡ "redundant_metadata_only"}¨ txResults
  spacingAndRedundantCount ← +´ 0 ∾ {𝕩.classification ≡ "spacing_and_redundant_metadata"}¨ txResults
  unsupportedCount ← +´ 0 ∾ {𝕩.classification ≡ "unsupported"}¨ txResults

  {
    state⇐parsed.state,
    transactions⇐txCount,
    postings⇐postingCount,
    single_space_postings⇐singleSpaceCount,
    multi_space_postings⇐multiSpaceCount,
    layer_actual_metadata⇐layerActualCount,
    currency_jpy_metadata⇐currencyJpyCount,
    canonical_transactions⇐canonicalCount,
    spacing_only_transactions⇐spacingOnlyCount,
    redundant_metadata_only_transactions⇐redundantMetaOnlyCount,
    spacing_and_redundant_metadata_transactions⇐spacingAndRedundantCount,
    unsupported_transactions⇐unsupportedCount,
    tx_results⇐txResults,
    diagnostics⇐diagnostics
  }
}

{Build⇐Build, AnalyzePostingLine⇐AnalyzePostingLine, AnalyzeMetaLine⇐AnalyzeMetaLine, ClassifyTransaction⇐ClassifyTransaction, TrimIndent⇐TrimIndent}