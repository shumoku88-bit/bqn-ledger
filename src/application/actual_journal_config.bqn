# Resolve one explicit configured native Actual Journal basename for editor routes.

io ← •Import "source_io.bqn"
configPath ← •Import "editor_config_path.bqn"
admission ← •Import "actual_journal_admission.bqn"
Resolve ← {𝕊 base:
  result ← admission.AdmitExplicit io.ReadLines configPath.Resolve base
  {𝕊:
    {𝕊:•Out "CONFIG ERROR: missing or duplicate value for ACTUAL_JOURNAL_FILE"}⍟(result.code≡"actual_journal_missing_or_duplicate") @
    {𝕊:•Out "CONFIG ERROR: empty value for ACTUAL_JOURNAL_FILE"}⍟(result.code≡"actual_journal_empty") @
    {𝕊:•Out "CONFIG ERROR: ACTUAL_JOURNAL_FILE must be a safe .journal basename"}⍟(result.code≡"actual_journal_basename_invalid") @
    •Exit 1
  }⍟(result.state≢"ok") @
  {file⇐result.file}
}

{Resolve⇐Resolve}
