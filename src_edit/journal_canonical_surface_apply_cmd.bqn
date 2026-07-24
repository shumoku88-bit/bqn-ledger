# journal_canonical_surface_apply_cmd.bqn
# Prepare rewrite candidate and manifest for Canonical Surface 001 safe apply.

args ← •args
baseDir ← ⊑ args
candidateFilePath ← 1 ⊑ args

rewrite ← •Import "journal_canonical_surface_rewrite.bqn"
loader ← •Import "../src_next/loader.bqn"
config ← •Import "../src_next/config.bqn"

resolved ← config.LoadActualJournal baseDir
relPath ← resolved.file
{𝕊: relPath ↩ "data/" ∾ resolved.file}⍟(0 = ⊑ •SH ⟨"test", "-f", baseDir ∾ "/data/" ∾ resolved.file⟩) @
sourcePath ← baseDir ∾ "/" ∾ relPath

raw ← loader.ReadRaw sourcePath
res ← rewrite.BuildCandidate raw

tab ← @+9
NumStr ← •Fmt

{FB:
  isNoop ← res.candidate_raw ≡ raw
  {𝕊:
    •Out "OK" ∾ tab ∾ "CANONICAL_NOOP" ∾ tab ∾ relPath
  }⍟isNoop @
  {FB2:
    candidateFilePath •FChars res.candidate_raw
    out ← "OK" ∾ tab ∾ "CANONICAL_REWRITE" ∾ tab ∾ relPath
    spacingFixCount ← res.plan_before.spacing_only_transactions + res.plan_before.spacing_and_redundant_metadata_transactions
    redundantMetaCount ← res.plan_before.layer_actual_metadata + res.plan_before.currency_jpy_metadata
    out ∾↩ tab ∾ NumStr spacingFixCount
    out ∾↩ tab ∾ NumStr redundantMetaCount
    out ∾↩ tab ∾ NumStr res.plan_before.transactions
    •Out out
  }⍟(¬isNoop) @
}⍟(res.state ≡ "ok") @

{𝕊:
  •Out "ERROR: canonical surface apply preparation failed"
  •Exit 1
}⍟(res.state ≢ "ok") @
