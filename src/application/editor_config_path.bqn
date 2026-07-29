# Resolve an explicit editor base/config path. No repository fallback discovery.

io ← •Import "source_io.bqn"
defaults ← •Import "system_defaults.bqn"
Resolve ← {𝕊 baseOrPath:
  {𝕊:•Out "CONFIG ERROR: editor base/config path is required" ⋄ •Exit 1}⍟(0=≠baseOrPath) @
  system ← defaults.Load @
  isTsv ← (4≤≠baseOrPath) ∧ (".tsv"≡¯4↑baseOrPath)
  candidate ← isTsv⊑⟨baseOrPath∾"/"∾system.DefaultConfigFile @, baseOrPath⟩
  {𝕊:•Out "CONFIG ERROR: config source is not readable: "∾candidate ⋄ •Exit 1}⍟(¬•file.Exists io.ResolvePath candidate) @
  candidate
}

{Resolve⇐Resolve}
