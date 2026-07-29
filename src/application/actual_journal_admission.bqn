# Pure admission for the configured native Actual Journal basename.

rows ← •Import "config_rows.bqn"
key ← "ACTUAL_JOURNAL_FILE"
Validate ← {𝕊 file:
  code ← ""
  {𝕊:code↩"actual_journal_empty"}⍟(0=≠file) @
  hasSeparator ← ∨´('/'=file) ∨ ((@+92)=file)
  hasControl ← ∨´file∊(@+9)‿(@+13)
  validSuffix ← (8≤≠file) ∧ ".journal"≡¯8↑file
  {𝕊:code↩"actual_journal_basename_invalid"}⍟((0=≠code) ∧ (hasSeparator ∨ hasControl ∨ ¬validSuffix)) @
  {state⇐(0=≠code)⊑"error"‿"ok",code⇐code,file⇐file}
}
AdmitExplicit ← {𝕊 lines:
  matches ← (rows.Build lines).Matches key
  result ← {state⇐"error",code⇐"actual_journal_missing_or_duplicate",file⇐""}
  {𝕊:result↩Validate 1⊑⊑matches}⍟(1=≠matches) @
  result
}
AdmitWithRepositoryDefault ← {𝕊 localLines‿repositoryLines:
  local ← (rows.Build localLines).Matches key
  repository ← (rows.Build repositoryLines).Matches key
  result ← {state⇐"error",code⇐"actual_journal_repository_default_invalid",file⇐""}
  {𝕊:
    result↩{state⇐"error",code⇐"actual_journal_duplicate",file⇐""}
    {𝕊:
      file ← 1⊑⊑repository
      {𝕊:file↩1⊑⊑local}⍟(1=≠local) @
      result↩Validate file
    }⍟(1≥≠local) @
  }⍟(1=≠repository) @
  result
}

{AdmitExplicit⇐AdmitExplicit,AdmitWithRepositoryDefault⇐AdmitWithRepositoryDefault}
