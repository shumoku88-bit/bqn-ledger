# journal_canonical_surface_rewrite.bqn
# Pure whole-Journal candidate builder and semantic equivalence verifier for Canonical Surface 001.

util ← •Import "../src/text/parse.bqn"
parser ← •Import "../src/editor/journal_profile.bqn"
plan ← •Import "journal_canonical_surface_plan.bqn"

lf ← @+10
cr ← @+13
empty ← ⟨⟩

Diagnostic ← {𝕊 code‿message: {code⇐code, message⇐message}}

JoinLines ← {𝕊 lines:
  0=≠lines ? "" ;
  continuation ← {lf∾𝕩}¨ 1↓lines
  (⊑lines) ∾ (∾continuation)
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
AccountSignatures ← {𝕊 accounts:
  {⟨𝕩.account_key,𝕩.role,𝕩.kind,𝕩.default_envelope,MetaPairs 𝕩.metadata⟩}¨accounts
}
CommoditySignatures ← {𝕊 commodities: {𝕩.commodity}¨commodities}

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

    accountsMatch ← (AccountSignatures beforeParsed.accounts) ≡ AccountSignatures afterParsed.accounts
    commoditiesMatch ← (CommoditySignatures beforeParsed.commodities) ≡ CommoditySignatures afterParsed.commodities
    {FB7: Add ⟨"declaration_semantics_mismatch", "Account or commodity declarations changed"⟩}⍟(¬accountsMatch ∨ ¬commoditiesMatch) @

  }⍟((beforeParsed.state ≡ "ok") ∧ (afterParsed.state ≡ "ok")) @

  {state⇐(0 = ≠ diagnostics) ⊑ "error"‿"ok", diagnostics⇐diagnostics}
}

RewriteSingleLine ← {𝕊 line:
  pInfo ← plan.AnalyzePostingLine line
  mInfo ← plan.AnalyzeMetaLine line

  canonicalPosting ← "    " ∾ pInfo.account ∾ "    " ∾ pInfo.amount_part
  canonicalPosting ← pInfo.has_cr ⊑ ⟨canonicalPosting,canonicalPosting∾cr⟩
  rewrittenLine ← pInfo.is_posting ⊑ ⟨line,canonicalPosting⟩

  {is_remove⇐mInfo.is_redundant, line⇐rewrittenLine}
}

BuildCandidate ← {𝕊 raw:
  diagnostics ← empty
  Add ← {𝕊 code‿message: diagnostics ∾↩ ⟨Diagnostic ⟨code, message⟩⟩}

  planResult ← plan.Build raw
  {FB: Add ⟨"source_parse_failed", "source Journal failed to parse"⟩}⍟(planResult.state ≢ "ok") @
  {FB: Add ⟨"unsupported_transactions_present", "source contains unsupported transactions"⟩}⍟(0 < planResult.unsupported_transactions) @

  cleaned ← (cr ≠ raw) / raw
  lines ← lf util.SplitKeepEmpty cleaned
  rewritten ← RewriteSingleLine¨ lines
  keep ← ¬ {𝕩.is_remove}¨ rewritten
  newLines ← keep / {𝕩.line}¨ rewritten

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

{BuildCandidate⇐BuildCandidate,VerifyEquivalent⇐VerifyEquivalent,RewriteSingleLine⇐RewriteSingleLine}