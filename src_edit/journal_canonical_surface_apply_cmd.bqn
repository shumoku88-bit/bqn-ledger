# journal_canonical_surface_apply_cmd.bqn
# Prepare rewrite candidate and manifest for Canonical Surface 001 safe apply.

args ← •args
baseDir ← ⊑ args
candidateFilePath ← 1 ⊑ args

rewrite ← •Import "journal_canonical_surface_rewrite.bqn"
loader ← •Import "../src/application/source_io.bqn"
canonical ← •Import "../src/application/canonical_household_sources.bqn"

relPath ← canonical.actual
sourcePath ← loader.JoinPath ⟨baseDir,relPath⟩
raw ← loader.ReadRaw sourcePath
res ← rewrite.BuildCandidate raw

tab ← @+9
Join ← {𝕊 fields:1↓∾(tab⊸∾)¨fields}

{FB:
  isNoop ← res.candidate_raw ≡ raw
  {𝕊:•Out Join ⟨"OK","CANONICAL_NOOP",relPath⟩}⍟isNoop @
  {FB2:
    candidateFilePath •FChars res.candidate_raw
    {𝕊:
      •Out "ERROR: canonical candidate write mismatch"
      •Exit 1
    }⍟((loader.ReadRaw candidateFilePath) ≢ res.candidate_raw) @
    spacingFixCount ← res.plan_before.spacing_only_transactions + res.plan_before.spacing_and_redundant_metadata_transactions
    redundantMetaCount ← res.plan_before.layer_actual_metadata + res.plan_before.currency_jpy_metadata
    •Out Join ⟨
      "OK","CANONICAL_REWRITE",relPath,
      •Fmt spacingFixCount,•Fmt redundantMetaCount,•Fmt res.plan_before.transactions
    ⟩
  }⍟(¬isNoop) @
}⍟(res.state ≡ "ok") @

{𝕊:
  •Out "ERROR: canonical surface apply preparation failed"
  •Exit 1
}⍟(res.state ≢ "ok") @