# Pure whole-Journal candidate builder and semantic equivalence verifier.

cleanup ← •Import "journal_cleanup_plan.bqn"
parser ← •Import "../src/editor/journal_profile.bqn"
util ← •Import "../src/text/parse.bqn"

lf ← @+10
cr ← @+13
space ← @+32
empty ← ⟨⟩
Diagnostic ← {𝕊 code‿message: {code⇐code, message⇐message}}
Count ← {𝕊 category‿rows: +´ 0 ∾ {𝕩.classification ≡ category}¨ rows}
Counts ← {𝕊 rows: {
  total⇐≠rows,
  removable⇐Count ⟨"REMOVABLE",rows⟩,
  referenced⇐Count ⟨"REFERENCED",rows⟩,
  plan_linked⇐Count ⟨"PLAN_LINKED",rows⟩,
  other_linked⇐Count ⟨"OTHER_LINKED",rows⟩,
  identity_free⇐Count ⟨"IDENTITY_FREE",rows⟩,
  not_legacy⇐Count ⟨"NOT_LEGACY",rows⟩
}}
JoinLines ← {𝕊 lines:
  LinePiece ← {𝕊 i:((i>0)/⟨lf⟩) ∾ >i⊑lines}
  pieces ← LinePiece¨ ↕≠lines
  ∾ (⟨""⟩ ∾ pieces)
}
TrimIndent ← {𝕊 text:
  line ← text
  {𝕊: line ↩ ¯1↓line}⍟((0<≠line) ∧ cr=¯1⊑line) @
  prefix ← ∧` (line=space)
  (+´prefix)↓line
}
MetaPairs ← {𝕊 metadata: {⟨𝕩.key,𝕩.value⟩}¨ metadata}
WithoutEvent ← {𝕊 metadata: ({𝕩.key≢"event-id"}¨metadata)/metadata}
EventValues ← {𝕊 metadata: {𝕩.value}¨({𝕩.key≡"event-id"}¨metadata)/metadata}
PostingEquivalent ← {𝕊 b‿a:
  ∧´⟨b.account_key≡a.account_key,b.delta=a.delta,b.commodity≡a.commodity,b.side≡a.side,b.posting_index=a.posting_index⟩
}

VerifyEquivalent ← {𝕊 before‿after‿planRows:
  diagnostics ← empty
  Add ← {𝕊 code‿message: diagnostics ∾↩ ⟨Diagnostic ⟨code,message⟩⟩}
  {𝕊: Add ⟨"transaction_count_changed","transaction count changed"⟩}⍟((≠before)≠≠after) @
  {𝕊: Add ⟨"plan_count_mismatch","cleanup plan count does not match before transactions"⟩}⍟((≠planRows)≠≠before) @
  {𝕊 i:
    {𝕊:
      b ← i⊑before ⋄ a ← i⊑after ⋄ row ← i⊑planRows
      target ← row.classification≡"REMOVABLE"
      common ← ∧´⟨
        b.date≡a.date,b.status_marker≡a.status_marker,b.description≡a.description,
        b.layer_name≡a.layer_name,b.plan_id≡a.plan_id,b.txn_id≡a.txn_id,
        b.allocation_id≡a.allocation_id,b.actual_event_id≡a.actual_event_id,
        b.execution_envelope≡a.execution_envelope,(≠b.postings)=≠a.postings
      ⟩
      {𝕊: common ↩ common ∧ ∧´ 1∾b.postings {PostingEquivalent ⟨𝕨,𝕩⟩}¨ a.postings}⍟((≠b.postings)=≠a.postings) @
      {𝕊: Add ⟨"semantic_mismatch","accounting-bearing transaction fields changed"⟩}⍟(¬common) @
      {𝕊:
        exactRemoval ← (b.identity_kind≡"durable") ∧ (a.identity_kind≡"physical_fallback")
        exactRemoval ∧↩ ⟨row.event_id⟩ ≡ (EventValues b.metadata)
        exactRemoval ∧↩ 0=≠EventValues a.metadata
        exactRemoval ∧↩ (MetaPairs (WithoutEvent b.metadata)) ≡ (MetaPairs a.metadata)
        {𝕊: Add ⟨"target_identity_mismatch","target changed by more than one removable event-id"⟩}⍟(¬exactRemoval) @
      }⍟target @
      {𝕊:
        exact ← (b.identity_kind≡a.identity_kind) ∧ (b.source_event_id≡a.source_event_id)
        exact ∧↩ (MetaPairs b.metadata) ≡ (MetaPairs a.metadata)
        {𝕊: Add ⟨"non_target_changed","non-target identity or metadata changed"⟩}⍟(¬exact) @
      }⍟(¬target) @
    }⍟(i<⌊´⟨≠before,≠after,≠planRows⟩) @
  }¨ ↕⌈´⟨≠before,≠after,≠planRows⟩
  {state⇐(0=≠diagnostics)⊑"error"‿"ok", diagnostics⇐diagnostics}
}

BuildCandidate ← {𝕊 raw‿transactions‿planRows:
  diagnostics ← empty
  Add ← {𝕊 code‿message: diagnostics ∾↩ ⟨Diagnostic ⟨code,message⟩⟩}
  lines ← <¨ lf util.SplitKeepEmpty raw
  {𝕊: Add ⟨"plan_count_mismatch","cleanup plan count does not match parsed transactions"⟩}⍟((≠planRows)≠≠transactions) @
  removals ← ({𝕩.classification≡"REMOVABLE"}¨planRows)/planRows
  removalLines ← {𝕩.event_id_line}¨removals
  {𝕊 i:
    row ← i⊑removals
    line ← i⊑removalLines
    validLine ← (line>0) ∧ line≤≠lines
    {𝕊: Add ⟨"event_line_out_of_range","event-id line is outside raw Journal"⟩}⍟(¬validLine) @
    {𝕊:
      txIndex ← row.number-1
      validTx ← (txIndex≥0) ∧ txIndex<≠transactions
      {𝕊: Add ⟨"transaction_out_of_range","cleanup row transaction is outside parsed transactions"⟩}⍟(¬validTx) @
      {𝕊:
        tx ← txIndex⊑transactions
        matching ← ({(𝕩.key≡"event-id") ∧ (𝕩.value≡row.event_id)}¨tx.metadata)/tx.metadata
        validMeta ← (1=≠matching) ∧ ((1=≠matching)∧line=(⊑matching).source_line)
        {𝕊: Add ⟨"metadata_source_mismatch","event-id metadata source line does not match cleanup row"⟩}⍟(¬validMeta) @
      }⍟validTx @
      expected ← "; event-id: "∾row.event_id
      {𝕊: Add ⟨"raw_event_line_mismatch","raw event-id line is not the exact expected metadata"⟩}⍟(expected≢TrimIndent > (line-1)⊑lines) @
      {𝕊: Add ⟨"duplicate_removal_line","one raw line was selected more than once"⟩}⍟(line∊i↑removalLines) @
    }⍟validLine @
    {𝕊: Add ⟨"event_id_not_legacy","cleanup target event-id is not exact legacy shape"⟩}⍟(¬cleanup.IsLegacyEntryId row.event_id) @
  }¨ ↕≠removals

  candidate ← raw
  {𝕊:
    kept ← (¬(1+↕≠lines)∊removalLines)/lines
    candidate ↩ JoinLines kept
  }⍟(0=≠diagnostics) @
  afterParsed ← {state⇐"error",transactions⇐empty,diagnostics⇐empty}
  afterRows ← empty
  {𝕊:
    afterParsed ↩ parser.ParseWithProfile ⟨candidate,"historical_external_plan"⟩
    {𝕊: Add ⟨"candidate_parse_failed","candidate Journal did not parse"⟩}⍟(afterParsed.state≢"ok") @
    {𝕊:
      afterRows ↩ cleanup.Build afterParsed.transactions
      beforeCounts ← Counts planRows ⋄ afterCounts ← Counts afterRows
      countsOk ← ∧´⟨
        afterCounts.total=beforeCounts.total,afterCounts.removable=0,
        afterCounts.identity_free=beforeCounts.identity_free+beforeCounts.removable,
        afterCounts.referenced=beforeCounts.referenced,afterCounts.plan_linked=beforeCounts.plan_linked,
        afterCounts.other_linked=beforeCounts.other_linked,afterCounts.not_legacy=beforeCounts.not_legacy
      ⟩
      {𝕊: Add ⟨"classification_changed","candidate cleanup classifications violate the transition contract"⟩}⍟(¬countsOk) @
      equivalent ← VerifyEquivalent ⟨transactions,afterParsed.transactions,planRows⟩
      diagnostics ∾↩ equivalent.diagnostics
    }⍟(afterParsed.state≡"ok") @
  }⍟(0=≠diagnostics) @
  beforeCounts ← Counts planRows
  afterCounts ← Counts afterRows
  {state⇐(0=≠diagnostics)⊑"error"‿"ok",candidate_raw⇐candidate,removals⇐removals,before_counts⇐beforeCounts,after_counts⇐afterCounts,diagnostics⇐diagnostics}
}

{BuildCandidate⇐BuildCandidate, VerifyEquivalent⇐VerifyEquivalent}
