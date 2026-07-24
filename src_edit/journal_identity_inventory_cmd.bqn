#!/usr/bin/env bqn
# Read-only Journal identity inventory CLI command.
# Args: base directory, format (summary|tsv)

loader ← •Import "../src_next/loader.bqn"
actual_source ← •Import "../src_next/actual_source.bqn"
parser ← •Import "../src_next/journal_profile_stage1.bqn"
inv ← •Import "journal_identity_inventory.bqn"

args ← •args
tab ← @+9

Join ← {
  sep ← 𝕨
  list ← 𝕩
  (0 = ≠ list) ◶ ⟨{𝕊: 1 ↓ ∾ (sep⊸∾)¨ list}, {𝕊: ""}⟩ @
}

Fail ← {𝕊 fields:
  •Out tab Join fields
  •Exit 1
}

{𝕊: Fail ⟨"ERROR", "usage", "journal_identity_inventory_cmd.bqn <baseDir> <format: summary|tsv>"⟩}⍟(2 ≠ ≠ args) @
baseDir ← 0 ⊑ args
format ← 1 ⊑ args
validFormats ← "summary" ‿ "tsv"
{𝕊: Fail ⟨"ERROR", "invalid_format", format⟩}⍟(¬ ∨´ format⊸≡¨ validFormats) @

route ← actual_source.Resolve baseDir
raw ← loader.ReadRaw (baseDir ∾ "/" ∾ route.file)
parsed ← parser.ParseWithProfile ⟨raw, "historical_external_plan"⟩
{𝕊:
  first ← ⊑ parsed.diagnostics
  Fail ⟨"ERROR", "journal_invalid", first.code, •Fmt first.line⟩
}⍟(parsed.state ≢ "ok") @

inventory ← inv.BuildInventory parsed.transactions

(format ≡ "summary") ◶ ⟨
  {𝕊: •Out inv.FormatTsv inventory},
  {𝕊:
    s ← inv.Summarize inventory
    •Out inv.FormatSummary s
  }
⟩ @
