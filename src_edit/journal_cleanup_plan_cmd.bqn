#!/usr/bin/env bqn
# Read-only legacy Journal event-id cleanup-plan command.
# Args: base directory, format (tsv|text)

loader ← •Import "../src/application/source_io.bqn"
canonical ← •Import "../src/application/canonical_household_sources.bqn"
parser ← •Import "../src/editor/journal_profile.bqn"
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

raw ← loader.ReadRaw (loader.JoinPath ⟨baseDir,canonical.actual⟩)
parsed ← parser.ParseWithProfile ⟨raw, "historical_external_plan"⟩
{𝕊:
  first ← ⊑ parsed.diagnostics
  Fail ⟨"ERROR", "journal_invalid", first.code, •Fmt first.line⟩
}⍟(parsed.state ≢ "ok") @

rows ← cleanup.Build parsed.transactions
Dash ← {𝕊 text:(0=≠text)⊑⟨text,"-"⟩}

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
  •Out ∾ ⟨
    "#",•Fmt row.number," ",row.classification,
    " reason=",row.reason,
    " event-line=",•Fmt row.event_id_line,
    " refs=",•Fmt row.incoming_reference_count,
    " date=",row.date,
    " id=",Dash row.event_id,
    " plan=",Dash row.plan_id,
    " ",row.description
  ⟩
}

Count ← {𝕊 category: +´ 0 ∾ {𝕩.classification ≡ category}¨ rows}
Summary ← {𝕊:
  ∾ ⟨
    "Summary total=",•Fmt ≠rows,
    " removable=",•Fmt Count "REMOVABLE",
    " referenced=",•Fmt Count "REFERENCED",
    " plan-linked=",•Fmt Count "PLAN_LINKED",
    " other-linked=",•Fmt Count "OTHER_LINKED",
    " identity-free=",•Fmt Count "IDENTITY_FREE",
    " not-legacy=",•Fmt Count "NOT_LEGACY"
  ⟩
}

(format ≡ "tsv") ◶ ⟨
  {𝕊:
    •Out "Journal legacy entry-id cleanup plan"
    PrintText¨ rows
    •Out Summary @
  },
  {𝕊: PrintTsv¨ rows}
⟩ @
