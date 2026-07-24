# journal_canonical_surface_rewrite.bqn
# Pure whole-Journal candidate builder and semantic equivalence verifier for Canonical Surface 001.

util ← •Import "../src_next/util.bqn"
parser ← •Import "../src_next/journal_profile_stage1.bqn"
stage2a ← •Import "../src_next/journal_posting_ir_stage2a.bqn"
ak ← •Import "../src_next/account_key.bqn"
plan ← •Import "journal_canonical_surface_plan.bqn"

lf ← @+10
cr ← @+13
space ← @+32
tab ← @+9
empty ← ⟨⟩

Diagnostic ← {𝕊 code‿message: {code⇐code, message⇐message}}

JoinLines ← {𝕊 lines:
  result ← ""
  {𝕊 i:
    result ∾↩ >i⊑lines
    {𝕊: result ∾↩ lf}⍟(i<¯1+≠lines) @
  }¨ ↕≠lines
  result
}

MetaPairs ← {𝕊 metadata: {⟨𝕩.key, 𝕩.value⟩}¨ metadata}
WithoutRedundantMeta ← {𝕊 metadata:
  IsRedundant ← {𝕊 m:
    isLayerActual ← (m.key ≡ "layer") ∧ (m.value ≡ "actual")
    isCurrencyJpy ← (m.key ≡ "currency") ∧ (m.value ≡ "JPY")
    isLayerActual ∨ isCurrencyJpy
  }
  ({¬ IsRedundant 𝕩}¨ metadata) / metadata
}

PostingEquivalent ← {𝕊 b‿a:
  ∧´ ⟨b.account_key≡a.account_key, b.delta=a.delta, b.commodity≡a.commodity, b.side≡a.side, b.posting_index=a.posting_index⟩
}

IsStage0LineId ← { (12 ≤ ≠ 𝕩) ∧ ("stage0-line-" ≡ 12 ↑ 𝕩) }
EventIdEquivalent ← {𝕊 b‿a:
  (IsStage0LineId b) ◶ ⟨ { b ≡ a }, { IsStage0LineId a } ⟩ @
}
PostingIdEquivalent ← {𝕊 b‿a:
  (IsStage0LineId b) ◶ ⟨ { b ≡ a }, { IsStage0LineId a } ⟩ @
}

PostingRowEquivalent ← {
  b ← 𝕨
  a ← 𝕩
  sourceIdMatch ← EventIdEquivalent ⟨b.source_id, a.source_id⟩
  postingIdMatch ← PostingIdEquivalent ⟨b.posting_id, a.posting_id⟩
  txIdMatch ← EventIdEquivalent ⟨b.tx_id, a.tx_id⟩
  sourceIdMatch ∧ postingIdMatch ∧ txIdMatch ∧ ∧´ ⟨
    b.source_file ≡ a.source_file,
    b.date ≡ a.date,
    b.day_index = a.day_index,
    b.account_key ≡ a.account_key,
    b.account_key_index = a.account_key_index,
    b.layer_name ≡ a.layer_name,
    b.layer_index = a.layer_index,
    b.side ≡ a.side,
    b.delta = a.delta,
    b.kind ≡ a.kind,
    b.status ≡ a.status,
    b.message ≡ a.message
  ⟩
}

VerifyEquivalent ← {𝕊 beforeRaw‿afterRaw:
  diagnostics ← empty
  Add ← {𝕊 code‿message: diagnostics ∾↩ ⟨Diagnostic ⟨code, message⟩⟩}
  
  beforeParsed ← parser.ParseWithProfile ⟨beforeRaw, "historical_external_plan"⟩
  afterParsed ← parser.ParseWithProfile ⟨afterRaw, "historical_external_plan"⟩
  
  {FB: Add ⟨"before_parse_failed", "before Journal parse failed"⟩}⍟(beforeParsed.state ≢ "ok") @
  {FB: Add ⟨"after_parse_failed", "after Journal parse failed"⟩}⍟(afterParsed.state ≢ "ok") @
  
  {FB:
    beforeTx ← beforeParsed.transactions
    afterTx ← afterParsed.transactions
    
    {FB2: Add ⟨"transaction_count_changed", "transaction count changed"⟩}⍟((≠beforeTx) ≠ ≠afterTx) @
    
    {𝕊 i:
      b ← i ⊑ beforeTx
      a ← i ⊑ afterTx
      
      common ← ∧´ ⟨
        b.date ≡ a.date,
        b.status_marker ≡ a.status_marker,
        b.description ≡ a.description,
        b.layer_name ≡ a.layer_name,
        b.identity_kind ≡ a.identity_kind,
        EventIdEquivalent ⟨b.source_event_id, a.source_event_id⟩,
        b.plan_id ≡ a.plan_id,
        b.txn_id ≡ a.txn_id,
        b.allocation_id ≡ a.allocation_id,
        b.actual_event_id ≡ a.actual_event_id,
        b.execution_envelope ≡ a.execution_envelope,
        (≠b.postings) = ≠a.postings
      ⟩
      
      {FB3: Add ⟨"transaction_header_mismatch", "transaction fields changed"⟩}⍟(¬common) @
      
      {FB4:
        postingsMatch ← ∧´ 1 ∾ b.postings {PostingEquivalent ⟨𝕨, 𝕩⟩}¨ a.postings
        {FB5: Add ⟨"posting_semantics_mismatch", "posting semantics changed"⟩}⍟(¬postingsMatch) @
      }⍟((≠b.postings) = ≠a.postings) @
      
      bFilteredMeta ← WithoutRedundantMeta b.metadata
      aMeta ← a.metadata
      metaMatch ← (MetaPairs bFilteredMeta) ≡ (MetaPairs aMeta)
      {FB6: Add ⟨"metadata_semantics_mismatch", "non-redundant metadata changed"⟩}⍟(¬metaMatch) @
      
    }¨ ↕ ⌊´ ⟨≠beforeTx, ≠afterTx⟩
    
    # Stage 2A Posting IR comparison
    accLines ← { 𝕩.account_key ∾ tab ∾ "role=" ∾ 𝕩.role }¨ beforeParsed.accounts
    resolved ← ak.Resolve accLines
    beforeIr ← stage2a.BuildForSource ⟨beforeTx, resolved, "", "data/actual.journal"⟩
    afterIr ← stage2a.BuildForSource ⟨afterTx, resolved, "", "data/actual.journal"⟩
    
    countMatch ← (≠beforeIr.posting_rows) = ≠afterIr.posting_rows
    rowsMatch ← ∧´ 1 ∾ beforeIr.posting_rows PostingRowEquivalent¨ afterIr.posting_rows
    irMatch ← countMatch ∧ rowsMatch
    {FB7: Add ⟨"stage2a_ir_mismatch", "Stage 2A Posting IR changed"⟩}⍟(¬irMatch) @

  }⍟((beforeParsed.state ≡ "ok") ∧ (afterParsed.state ≡ "ok")) @
  
  {state⇐(0 = ≠ diagnostics) ⊑ "error"‿"ok", diagnostics⇐diagnostics}
}

RewriteSingleLine ← {𝕊 line:
  pInfo ← plan.AnalyzePostingLine line
  mInfo ← plan.AnalyzeMetaLine line
  
  isRemove ← mInfo.is_redundant
  newLine ← line
  
  {FB:
    hasCr ← (0 < ≠line) ∧ (cr = ¯1⊑(line ∾ " "))
    l ← line
    {FB2: l ↩ ¯1↓l}⍟hasCr @
    parsed ← plan.TrimIndent l
    trimmed ← parsed.trimmed
    
    spaceIndices ← (space = trimmed) / ↕≠trimmed
    p1 ← 0
    {FB3: p1 ↩ ⊑ spaceIndices}⍟(0 < ≠spaceIndices) @
    rem ← p1 ↓ trimmed
    spaceLen ← 0
    {FB4: spaceLen ↩ +´ ∧` (space = rem)}⍟(0 < ≠spaceIndices) @
    
    account ← p1 ↑ trimmed
    amountPart ← (p1 + spaceLen) ↓ trimmed
    
    newLine ↩ "    " ∾ account ∾ "    " ∾ amountPart
    {FB5: newLine ∾↩ cr}⍟hasCr @
  }⍟(pInfo.is_posting) @
  
  {is_remove⇐isRemove, line⇐newLine}
}

BuildCandidate ← {𝕊 raw:
  diagnostics ← empty
  Add ← {𝕊 code‿message: diagnostics ∾↩ ⟨Diagnostic ⟨code, message⟩⟩}
  
  planResult ← plan.Build raw
  {FB: Add ⟨"source_parse_failed", "source Journal failed to parse"⟩}⍟(planResult.state ≢ "ok") @
  {FB: Add ⟨"unsupported_transactions_present", "source contains unsupported transactions"⟩}⍟(0 < planResult.unsupported_transactions) @
  
  cleaned ← (cr ≠ raw) / raw
  lines ← lf util.SplitKeepEmpty cleaned
  
  newLines ← empty
  {𝕊 line:
    res ← RewriteSingleLine line
    {FB: newLines ∾↩ ⟨res.line⟩}⍟(¬ res.is_remove) @
  }¨ lines
  
  candidateRaw ← JoinLines newLines
  hasFinalLf ← (0 < ≠raw) ∧ (lf = ¯1⊑raw)
  {FB:
    {FB2: candidateRaw ∾↩ lf}⍟((0 = ≠candidateRaw) ∨ (lf ≠ ¯1⊑candidateRaw)) @
  }⍟hasFinalLf @
  {FB:
    {FB2: candidateRaw ↩ ¯1↓candidateRaw}⍟((0 < ≠candidateRaw) ∧ (lf = ¯1⊑candidateRaw)) @
  }⍟(¬hasFinalLf) @
  
  eqResult ← VerifyEquivalent ⟨raw, candidateRaw⟩
  diagnostics ∾↩ eqResult.diagnostics
  
  candPlanResult ← plan.Build candidateRaw
  
  {
    state⇐(0 = ≠ diagnostics) ⊑ "error"‿"ok",
    candidate_raw⇐candidateRaw,
    plan_before⇐planResult,
    plan_after⇐candPlanResult,
    diagnostics⇐diagnostics
  }
}

{BuildCandidate⇐BuildCandidate, VerifyEquivalent⇐VerifyEquivalent, RewriteSingleLine⇐RewriteSingleLine, PostingRowEquivalent⇐PostingRowEquivalent}
