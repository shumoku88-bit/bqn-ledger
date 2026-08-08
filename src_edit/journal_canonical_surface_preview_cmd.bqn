# journal_canonical_surface_preview_cmd.bqn
# CLI preview entry point for Canonical Journal Surface 001.

args ← •args
baseDir ← ⊑ args
outputPath ← 1 ⊑ args

rewrite ← •Import "journal_canonical_surface_rewrite.bqn"
loader ← •Import "../src/application/source_io.bqn"
canonical ← •Import "../src/application/canonical_household_sources.bqn"

relPath ← canonical.actual
sourcePath ← baseDir ∾ "/" ∾ relPath

# Reject if source path and output path resolve to the exact same string
{𝕊:
  •Out "ERROR: output path matches source path"
  •Exit 1
}⍟(sourcePath ≡ outputPath) @

raw ← loader.ReadRaw sourcePath
res ← rewrite.BuildCandidate raw

tab ← @+9

{FB:
  outputPath •FChars res.candidate_raw
  •Out "OK" ∾ tab ∾ "CANONICAL_PREVIEW" ∾ tab ∾ relPath ∾ tab ∾ outputPath
}⍟(res.state ≡ "ok") @

{𝕊:
  •Out "ERROR: candidate generation or semantic verification failed"
  •Exit 1
}⍟(res.state ≢ "ok") @
