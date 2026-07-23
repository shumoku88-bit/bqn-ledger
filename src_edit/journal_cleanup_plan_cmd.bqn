#!/usr/bin/env bqn
# Read-only legacy Journal event-id cleanup-plan command.
# Args: base directory, format (tsv|text)

loader ← •Import "../src_next/loader.bqn"
actual_source ← •Import "../src_next/actual_source.bqn"
parser ← •Import "../src_next/journal_profile_stage1.bqn"
cleanup ← •Import "journal_cleanup_plan.bqn"

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

{𝕊: Fail ⟨"ERROR", "usage", "journal_cleanup_plan_cmd.bqn <baseDir> <format: tsv|text>"⟩}⍟(2 ≠ ≠ args) @
baseDir ← 0 ⊑ args
format ← 1 ⊑ args
{𝕊: Fail ⟨"ERROR", "invalid_format", format⟩}⍟(¬ ∨´ format⊸≡¨ "tsv"‿"text") @

route ← actual_source.Resolve baseDir
raw ← loader.ReadRaw (baseDir ∾ "/" ∾ route.file)
parsed ← parser.ParseWithProfile ⟨raw, "historical_external_plan"⟩
{𝕊:
  first ← ⊑ parsed.diagnostics
  Fail ⟨"ERROR", "journal_invalid", first.code, •Fmt first.line⟩
}⍟(parsed.state ≢ "ok") @

rows ← cleanup.Build parsed.transactions
Dash ← {𝕊 text:
  result ← text
  {𝕊: result ↩ "-"}⍟(0 = ≠ text) @
  result
}

PrintTsv ← {𝕊 row:
  •Out tab Join ⟨
    •Fmt row.number,
    row.classification,
    row.reason,
    row.date,
    row.description,
    Dash row.event_id,
    •Fmt row.event_id_line,
    •Fmt row.source_start_line,
    •Fmt row.incoming_reference_count,
    Dash row.plan_id
  ⟩
}

PrintText ← {𝕊 row:
  out ← "#" ∾ (•Fmt row.number) ∾ " " ∾ row.classification
  out ∾↩ " reason=" ∾ row.reason
  out ∾↩ " event-line=" ∾ (•Fmt row.event_id_line)
  out ∾↩ " refs=" ∾ (•Fmt row.incoming_reference_count)
  out ∾↩ " date=" ∾ row.date
  out ∾↩ " id=" ∾ (Dash row.event_id)
  out ∾↩ " plan=" ∾ (Dash row.plan_id)
  out ∾↩ " " ∾ row.description
  •Out out
}

Count ← {𝕊 category: +´ 0 ∾ {𝕩.classification ≡ category}¨ rows}

(format ≡ "tsv") ◶ ⟨
  {𝕊:
    •Out "Journal legacy entry-id cleanup plan"
    PrintText¨ rows
    summary ← "Summary total=" ∾ •Fmt (≠ rows)
    summary ∾↩ " removable=" ∾ (•Fmt Count "REMOVABLE")
    summary ∾↩ " referenced=" ∾ (•Fmt Count "REFERENCED")
    summary ∾↩ " plan-linked=" ∾ (•Fmt Count "PLAN_LINKED")
    summary ∾↩ " other-linked=" ∾ (•Fmt Count "OTHER_LINKED")
    summary ∾↩ " identity-free=" ∾ (•Fmt Count "IDENTITY_FREE")
    summary ∾↩ " not-legacy=" ∾ (•Fmt Count "NOT_LEGACY")
    •Out summary
  },
  {𝕊: PrintTsv¨ rows}
⟩ @
