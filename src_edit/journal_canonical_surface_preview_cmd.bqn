# journal_canonical_surface_preview_cmd.bqn
# CLI preview entry point for Canonical Journal Surface 001.

args ← •args
baseDir ← ⊑ args
outputPath ← 1 ⊑ args

rewrite ← •Import "journal_canonical_surface_rewrite.bqn"
loader ← •Import "../src_next/loader.bqn"
config ← •Import "../src_next/config.bqn"

resolved ← config.LoadActualJournal baseDir
relPath ← resolved.file
{𝕊: relPath ↩ "data/" ∾ resolved.file}⍟(0 = ⊑ •SH ⟨"test", "-f", baseDir ∾ "/data/" ∾ resolved.file⟩) @
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
  # Output file write
  outputPath •FChars res.candidate_raw
  •Out "OK" ∾ tab ∾ "CANONICAL_PREVIEW" ∾ tab ∾ relPath ∾ tab ∾ outputPath
}⍟(res.state ≡ "ok") @

{𝕊:
  •Out "ERROR: candidate generation or semantic verification failed"
  •Exit 1
}⍟(res.state ≢ "ok") @
