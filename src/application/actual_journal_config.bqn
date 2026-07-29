# Resolve the configured native Actual Journal basename at the application boundary.

io ← •Import "source_io.bqn"
rows ← •Import "config_rows.bqn"
configPath ← •Import "editor_config_path.bqn"
repoConfig ← "config/default_config.tsv"
Resolve ← {𝕊 base:
  local ← rows.Build io.ReadLines configPath.Resolve base
  repository ← rows.Build io.ReadLines repoConfig
  key ← "ACTUAL_JOURNAL_FILE"
  localMatches ← local.Matches key
  repositoryMatches ← repository.Matches key
  {𝕊:•Out "CONFIG ERROR: duplicate value for "∾key ⋄ •Exit 1}⍟(1<≠localMatches) @
  {𝕊:•Out "CONFIG ERROR: repository default missing or duplicate for "∾key ⋄ •Exit 1}⍟(1≠≠repositoryMatches) @
  file ← 1⊑⊑repositoryMatches
  {𝕊:file↩1⊑⊑localMatches}⍟(1=≠localMatches) @
  {𝕊:•Out "CONFIG ERROR: empty value for "∾key ⋄ •Exit 1}⍟(0=≠file) @
  hasSeparator ← ∨´('/'=file) ∨ ((@+92)=file)
  hasControl ← ∨´file∊(@+9)‿(@+13)
  validSuffix ← (8≤≠file) ∧ ".journal"≡¯8↑file
  {𝕊:•Out "CONFIG ERROR: "∾key∾" must be a safe .journal basename" ⋄ •Exit 1}⍟(hasSeparator ∨ hasControl ∨ ¬validSuffix) @
  {file⇐file}
}

{Resolve⇐Resolve}
