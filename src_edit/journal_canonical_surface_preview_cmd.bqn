# journal_canonical_surface_preview_cmd.bqn
# CLI preview entry point for Canonical Journal Surface 001.

args ← •args
baseDir ← ⊑ args
outputPath ← 1 ⊑ args

rewrite ← •Import "journal_canonical_surface_rewrite.bqn"
loader ← •Import "../src/application/source_io.bqn"
canonical ← •Import "../src/application/canonical_household_sources.bqn"

relPath ← canonical.actual
sourcePath ← loader.JoinPath ⟨baseDir,relPath⟩

# The public shell owns filesystem alias/symlink rejection. Keep the exact-text
# equality check as a local fail-closed defense for direct internal invocation.
{𝕊:
  •Out "ERROR: output path matches source path"
  •Exit 1
}⍟(sourcePath ≡ outputPath) @

raw ← loader.ReadRaw sourcePath
res ← rewrite.BuildCandidate raw

tab ← @+9
Join ← {𝕊 fields:1↓∾(tab⊸∾)¨fields}

{FB:
  outputPath •FChars res.candidate_raw
  {𝕊:
    •Out "ERROR: canonical preview write mismatch"
    •Exit 1
  }⍟((loader.ReadRaw outputPath) ≢ res.candidate_raw) @
  •Out Join ⟨"OK","CANONICAL_PREVIEW",relPath,outputPath⟩
}⍟(res.state ≡ "ok") @

{𝕊:
  •Out "ERROR: candidate generation or semantic verification failed"
  •Exit 1
}⍟(res.state ≢ "ok") @