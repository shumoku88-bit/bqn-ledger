# journal_canonical_surface_plan_cmd.bqn
# Read-only CLI plan entry point for Canonical Journal Surface 001.

args ← •args
baseDir ← ⊑ args
format ← 1 ⊑ args

plan ← •Import "journal_canonical_surface_plan.bqn"
loader ← •Import "../src/application/source_io.bqn"
canonical ← •Import "../src/application/canonical_household_sources.bqn"

relPath ← canonical.actual
raw ← loader.ReadRaw loader.JoinPath ⟨baseDir,relPath⟩
res ← plan.Build raw

lf ← @+10
tab ← @+9
NumStr ← •Fmt
JoinLines ← {𝕊 lines:
  0=≠lines ? "" ;
  (⊑lines) ∾ (∾{lf∾𝕩}¨1↓lines)
}
Metric ← {𝕊 key‿value:key∾tab∾NumStr value}

{𝕊:
  tsvLines ← ⟨
    "metric" ∾ tab ∾ "value",
    Metric ⟨"transactions",res.transactions⟩,
    Metric ⟨"postings",res.postings⟩,
    Metric ⟨"single_space_postings",res.single_space_postings⟩,
    Metric ⟨"multi_space_postings",res.multi_space_postings⟩,
    Metric ⟨"layer_actual_metadata",res.layer_actual_metadata⟩,
    Metric ⟨"currency_jpy_metadata",res.currency_jpy_metadata⟩,
    Metric ⟨"canonical_transactions",res.canonical_transactions⟩,
    Metric ⟨"spacing_only_transactions",res.spacing_only_transactions⟩,
    Metric ⟨"redundant_metadata_only_transactions",res.redundant_metadata_only_transactions⟩,
    Metric ⟨"spacing_and_redundant_metadata_transactions",res.spacing_and_redundant_metadata_transactions⟩,
    Metric ⟨"unsupported_transactions",res.unsupported_transactions⟩
  ⟩
  textLines ← ⟨
    "Canonical Journal Surface 001 Plan",
    "Source: " ∾ relPath,
    "Status: " ∾ res.state,
    "Transactions: " ∾ NumStr res.transactions,
    "Postings: " ∾ NumStr res.postings,
    "Single-space postings: " ∾ NumStr res.single_space_postings,
    "Multi-space postings: " ∾ NumStr res.multi_space_postings,
    "Layer:actual metadata: " ∾ NumStr res.layer_actual_metadata,
    "Currency:JPY metadata: " ∾ NumStr res.currency_jpy_metadata,
    "Transactions breakdown:",
    "  Canonical: " ∾ NumStr res.canonical_transactions,
    "  Spacing-only: " ∾ NumStr res.spacing_only_transactions,
    "  Redundant-metadata-only: " ∾ NumStr res.redundant_metadata_only_transactions,
    "  Spacing-and-redundant-metadata: " ∾ NumStr res.spacing_and_redundant_metadata_transactions,
    "  Unsupported: " ∾ NumStr res.unsupported_transactions
  ⟩
  •Out JoinLines ((format≡"tsv")⊑⟨textLines,tsvLines⟩)
}⍟(res.state ≡ "ok") @

{𝕊:
  •Out "ERROR: plan classification failed"
  •Exit 1
}⍟(res.state ≢ "ok") @