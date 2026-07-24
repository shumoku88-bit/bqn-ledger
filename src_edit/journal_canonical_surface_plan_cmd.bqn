# journal_canonical_surface_plan_cmd.bqn
# Read-only CLI plan entry point for Canonical Journal Surface 001.

args ← •args
baseDir ← ⊑ args
format ← 1 ⊑ args

plan ← •Import "journal_canonical_surface_plan.bqn"
loader ← •Import "../src_next/loader.bqn"
config ← •Import "../src_next/config.bqn"

resolved ← config.LoadActualJournal baseDir
relPath ← resolved.file
{𝕊: relPath ↩ "data/" ∾ resolved.file}⍟(0 = ⊑ •SH ⟨"test", "-f", baseDir ∾ "/data/" ∾ resolved.file⟩) @
absPath ← baseDir ∾ "/" ∾ relPath
raw ← loader.ReadRaw absPath

res ← plan.Build raw

lf ← @+10
tab ← @+9
NumStr ← •Fmt

{𝕊:
  {𝕊:
    out ← "metric" ∾ tab ∾ "value"
    out ∾↩ lf ∾ "transactions" ∾ tab ∾ NumStr res.transactions
    out ∾↩ lf ∾ "postings" ∾ tab ∾ NumStr res.postings
    out ∾↩ lf ∾ "single_space_postings" ∾ tab ∾ NumStr res.single_space_postings
    out ∾↩ lf ∾ "multi_space_postings" ∾ tab ∾ NumStr res.multi_space_postings
    out ∾↩ lf ∾ "layer_actual_metadata" ∾ tab ∾ NumStr res.layer_actual_metadata
    out ∾↩ lf ∾ "currency_jpy_metadata" ∾ tab ∾ NumStr res.currency_jpy_metadata
    out ∾↩ lf ∾ "canonical_transactions" ∾ tab ∾ NumStr res.canonical_transactions
    out ∾↩ lf ∾ "spacing_only_transactions" ∾ tab ∾ NumStr res.spacing_only_transactions
    out ∾↩ lf ∾ "redundant_metadata_only_transactions" ∾ tab ∾ NumStr res.redundant_metadata_only_transactions
    out ∾↩ lf ∾ "spacing_and_redundant_metadata_transactions" ∾ tab ∾ NumStr res.spacing_and_redundant_metadata_transactions
    out ∾↩ lf ∾ "unsupported_transactions" ∾ tab ∾ NumStr res.unsupported_transactions
    •Out out
  }⍟(format ≡ "tsv") @
  
  {𝕊:
    out ← "Canonical Journal Surface 001 Plan"
    out ∾↩ lf ∾ "Source: " ∾ relPath
    out ∾↩ lf ∾ "Status: " ∾ res.state
    out ∾↩ lf ∾ "Transactions: " ∾ NumStr res.transactions
    out ∾↩ lf ∾ "Postings: " ∾ NumStr res.postings
    out ∾↩ lf ∾ "Single-space postings: " ∾ NumStr res.single_space_postings
    out ∾↩ lf ∾ "Multi-space postings: " ∾ NumStr res.multi_space_postings
    out ∾↩ lf ∾ "Layer:actual metadata: " ∾ NumStr res.layer_actual_metadata
    out ∾↩ lf ∾ "Currency:JPY metadata: " ∾ NumStr res.currency_jpy_metadata
    out ∾↩ lf ∾ "Transactions breakdown:"
    out ∾↩ lf ∾ "  Canonical: " ∾ NumStr res.canonical_transactions
    out ∾↩ lf ∾ "  Spacing-only: " ∾ NumStr res.spacing_only_transactions
    out ∾↩ lf ∾ "  Redundant-metadata-only: " ∾ NumStr res.redundant_metadata_only_transactions
    out ∾↩ lf ∾ "  Spacing-and-redundant-metadata: " ∾ NumStr res.spacing_and_redundant_metadata_transactions
    out ∾↩ lf ∾ "  Unsupported: " ∾ NumStr res.unsupported_transactions
    •Out out
  }⍟(format ≡ "text") @
}⍟(res.state ≡ "ok") @

{𝕊:
  •Out "ERROR: plan classification failed"
  •Exit 1
}⍟(res.state ≢ "ok") @
