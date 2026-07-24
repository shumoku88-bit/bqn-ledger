#!/usr/bin/env bqn
# Read-only Journal identity inventory CLI command.
# Args: base directory, format (summary|tsv|private-tsv)

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

{𝕊: Fail ⟨"ERROR", "usage", "journal_identity_inventory_cmd.bqn <baseDir> <format: summary|tsv|private-tsv>"⟩}⍟(2 ≠ ≠ args) @
baseDir ← 0 ⊑ args
format ← 1 ⊑ args
validFormats ← "summary" ‿ "tsv" ‿ "private-tsv"
{𝕊: Fail ⟨"ERROR", "invalid_format", format⟩}⍟(¬ ∨´ format⊸≡¨ validFormats) @

route ← actual_source.Resolve baseDir
raw ← loader.ReadRaw (baseDir ∾ "/" ∾ route.file)
parsed ← parser.ParseWithProfile ⟨raw, "historical_external_plan"⟩
{𝕊:
  first ← ⊑ parsed.diagnostics
  Fail ⟨"ERROR", "journal_invalid", first.code, •Fmt first.line⟩
}⍟(parsed.state ≢ "ok") @

rows ← inv.BuildInventory parsed.transactions

(format ≡ "summary") ◶ ⟨
  {𝕊:
    (format ≡ "tsv") ◶ ⟨
      {𝕊:
        •Out "# PRIVATE DATA EXPORT - LOCAL USE ONLY - DO NOT COMMIT OR EXPOSE"
        header ← tab Join ⟨
          "ordinal", "presence", "event_id", "lexical_family", "incoming_reference_count",
          "has_plan_id", "has_txn_id", "has_allocation_id", "has_actual_event_id",
          "has_execution_envelope", "has_series", "has_recur", "has_income_budget",
          "provenance", "reconstructibility", "disposition", "date", "description"
        ⟩
        •Out header
        {𝕊 row:
          •Out tab Join ⟨
            •Fmt row.ordinal, row.presence, row.event_id, row.lexical_family,
            •Fmt row.incoming_reference_count, •Fmt row.has_plan_id, •Fmt row.has_txn_id,
            •Fmt row.has_allocation_id, •Fmt row.has_actual_event_id,
            •Fmt row.has_execution_envelope, •Fmt row.has_series, •Fmt row.has_recur,
            •Fmt row.has_income_budget, row.provenance, row.reconstructibility,
            row.disposition, row.date, row.description
          ⟩
        }¨ rows
      },
      {𝕊: •Out inv.FormatTsv rows}
    ⟩ @
  },
  {𝕊:
    s ← inv.Summarize rows
    •Out inv.FormatSummary s
  }
⟩ @
