# Load explicit report request-manifest basenames from one required config file.
# This source is separate from ledger config.tsv; no base/default discovery occurs.

io ← •Import "source_io.bqn"
admission ← •Import "report_manifest_admission.bqn"

Load ← {𝕊 configSource:
  {𝕊:•Out "CONFIG ERROR: report manifest config path is required" ⋄ •Exit 1}⍟(0=≠configSource) @
  resolved ← io.ResolvePath configSource
  {𝕊:•Out "CONFIG ERROR: report manifest config source is not readable" ⋄ •Exit 1}⍟(¬•file.Exists resolved) @
  result ← admission.Admit io.ReadLines configSource
  {𝕊:
    •Out "CONFIG ERROR: "∾result.code
    •Exit 1
  }⍟(result.state≢"ok") @
  {human_file⇐result.human_file,compact_file⇐result.compact_file}
}

{Load⇐Load}
