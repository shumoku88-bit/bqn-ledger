# event_lens_format.bqn
# Pure deterministic TSV formatter for read-only Event Lens results.

tab_char ← @+9
lf_char ← @+10

FormatTsv ← {𝕊 lensResult:
  { state ⇐ lensResult.state, text ⇐ "", message ⇐ "" }
}

{
  FormatTsv ⇐ FormatTsv
}
