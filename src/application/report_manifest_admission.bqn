# Pure admission for explicit human/compact report request-manifest basenames.
# No path discovery, source I/O, report calculation, or default filename.

rows ← •Import "config_rows.bqn"
humanKey ← "REPORT_HUMAN_MANIFEST"
compactKey ← "REPORT_COMPACT_MANIFEST"

Validate ← {𝕊 value‿missingCode‿emptyCode‿invalidCode:
  result ← {state⇐"error",code⇐missingCode,file⇐""}
  {𝕊:
    code ← ""
    {𝕊:code↩emptyCode}⍟(0=≠value) @
    hasSeparator ← ∨´('/'=value) ∨ ((@+92)=value)
    hasControl ← ∨´value∊(@+9)‿(@+10)‿(@+13)
    validSuffix ← (4≤≠value) ∧ ".tsv"≡¯4↑value
    {𝕊:code↩invalidCode}⍟((0=≠code) ∧ (hasSeparator ∨ hasControl ∨ ¬validSuffix)) @
    result↩{state⇐(0=≠code)⊑"error"‿"ok",code⇐code,file⇐value}
  } @
  result
}

One ← {𝕊 table‿key‿missingCode‿emptyCode‿invalidCode:
  matches ← table.Matches key
  result ← {state⇐"error",code⇐missingCode,file⇐""}
  {𝕊:result↩Validate ⟨1⊑⊑matches,missingCode,emptyCode,invalidCode⟩}⍟(1=≠matches) @
  result
}

Admit ← {𝕊 lines:
  table ← rows.Build lines
  human ← One ⟨table,humanKey,"report_human_manifest_missing_or_duplicate","report_human_manifest_empty","report_human_manifest_basename_invalid"⟩
  compact ← One ⟨table,compactKey,"report_compact_manifest_missing_or_duplicate","report_compact_manifest_empty","report_compact_manifest_basename_invalid"⟩
  state ← "ok" ⋄ code ← ""
  {𝕊:state↩"error" ⋄ code↩human.code}⍟(human.state≢"ok") @
  {𝕊:state↩"error" ⋄ code↩compact.code}⍟((state≡"ok") ∧ compact.state≢"ok") @
  {𝕊:state↩"error" ⋄ code↩"report_manifests_must_differ"}⍟((state≡"ok") ∧ human.file≡compact.file) @
  {
    state⇐state,code⇐code,
    human_file⇐(state≡"ok")⊑""‿human.file,
    compact_file⇐(state≡"ok")⊑""‿compact.file
  }
}

{Admit⇐Admit}
