# journal_source_check.bqn
# CLI owner for mixed-currency-safe journal source integrity lint.

loader ← •Import "../src_next/loader.bqn"
util ← •Import "../src_next/util.bqn"
config ← •Import "../src_next/config.bqn"
integrity ← •Import "journal_source_integrity.bqn"

args ← •args
tab ← @+9
{𝕊⋄•Out "ERROR"∾tab∾"usage"⋄•Exit 2}⍟(1≠≠args) @
base ← ⊑args
sys ← config.LoadSystemDefaults @
ReadAllLines ← {𝕊 path:
  raw ← loader.ReadRaw path
  clean ← ((@+13)≠raw)/raw
  (@+10) util.SplitKeepEmpty clean
}
accountLines ← ReadAllLines (base∾"/"∾sys.DefaultAccountsFile @)
journalLines ← ReadAllLines (base∾"/"∾sys.DefaultJournalFile @)
result ← integrity.Check {account_lines⇐accountLines, journal_lines⇐journalLines}
{𝕊:
  {•Out "ERROR"∾tab∾𝕩.code∾tab∾•Fmt 𝕩.source_row∾tab∾𝕩.message}¨result.diagnostics
  •Exit 1
}⍟(result.state≢"ok") @
•Out "OK"∾tab∾"JOURNAL_SOURCE"∾tab∾•Fmt result.row_count
