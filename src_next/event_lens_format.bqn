# event_lens_format.bqn
# Pure deterministic TSV formatter for read-only Event Lens results.

Tab ← @+9
Lf ← @+10

FormatTsv ← {𝕊 lensResult:
  { state ⇐ lensResult.state, text ⇐ "", message ⇐ "" }
}

{
  FormatTsv ⇐ FormatTsv
}
