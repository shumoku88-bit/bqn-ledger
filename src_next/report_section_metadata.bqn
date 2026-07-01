# report_section_metadata.bqn — structured report section metadata export
#
# This is a UI-facing metadata surface. It does not read source TSV and does not
# build report ViewModels. Human report output remains owned by report.bqn.
#
# Output format: TSV
# Fields: key, label, category, owner, human_output, structured_output

labels ← •Import "report_labels.bqn"
L ← labels.Text

tab ← @+9
quote ← @+34
backslash ← @+92

HasArg ← {𝕊 args‿flag: 0 < +´ flag⊸≡¨ args }
ArgValue ← {𝕊 args‿flag:
  idx ← ⊑ ((flag⊸≡¨ args) ⊐ ⟨1⟩)
  next_idx ← 1 + idx
  (next_idx < ≠args) ? (next_idx ⊑ args) ; ""
}

EscapeJsonChar ← {𝕊 c:
  (c=quote) ⊑ ⟨((c=backslash) ⊑ ⟨⟨c⟩, backslash∾backslash⟩), backslash∾quote⟩
}

JsonString ← {𝕊 s: quote ∾ (∾ EscapeJsonChar¨ s) ∾ quote }
JsonField ← {𝕊 key‿value: (JsonString key) ∾ ": " ∾ (JsonString value) }

TrimReportHeading ← {𝕊 s:
  out ← s
  out ↩ {2↓𝕩}⍟((2 ≤ ≠out) ∧ ("==" ≡ 2↑out)) out
  out ↩ {1↓𝕩}⍟((1 ≤ ≠out) ∧ (' ' = ⊑out)) out
  out ↩ {¯2↓𝕩}⍟((2 ≤ ≠out) ∧ ("==" ≡ ¯2↑out)) out
  out ↩ {¯1↓𝕩}⍟((1 ≤ ≠out) ∧ (' ' = ⊑¯1↑out)) out
  out
}

TrimLeadingOrdinal ← {𝕊 s:
  out ← s
  out ↩ {3↓𝕩}⍟((3 ≤ ≠out) ∧ ('.' = 1⊑out) ∧ (' ' = 2⊑out)) out
  out ↩ {4↓𝕩}⍟((4 ≤ ≠out) ∧ ('.' = 2⊑out) ∧ (' ' = 3⊑out)) out
  out
}

DisplayLabel ← {𝕊 s: TrimLeadingOrdinal TrimReportHeading s }

FormatRow ← {𝕊 row:
  key ← 0⊑row
  label ← DisplayLabel 1⊑row
  category ← 2⊑row
  owner ← 3⊑row
  human ← 4⊑row
  structured ← 5⊑row
  key∾tab∾label∾tab∾category∾tab∾owner∾tab∾human∾tab∾structured
}

FormatJsonRow ← {𝕊 row:
  fields ← ⟨
    ⟨"key", 0⊑row⟩
    ⟨"label", DisplayLabel 1⊑row⟩
    ⟨"category", 2⊑row⟩
    ⟨"owner", 3⊑row⟩
    ⟨"human_output", 4⊑row⟩
    ⟨"structured_output", 5⊑row⟩
  ⟩
  "  {" ∾ (∾ {𝕊 i:
    prefix ← (i=0) ⊑ ⟨", ", ""⟩
    prefix ∾ JsonField (i⊑fields)
  }¨ ↕≠fields) ∾ "}"
}

rows ← ⟨
    ⟨"snapshot", L "snapshot.section_title", "overview", "src_next/snapshot.bqn", "yes", "metadata"⟩
    ⟨"issues", L "report.issues_title", "operations", "src_next/issues.bqn", "yes", "metadata"⟩
    ⟨"ytd", L "ytd.section_title", "accounting", "src_next/ytd_summary.bqn", "yes", "metadata"⟩
    ⟨"balances", L "balances.section_title", "accounting", "src_next/balances.bqn", "yes", "metadata"⟩
    ⟨"cycle", L "cycle.section_title", "household", "src_next/cycle_summary.bqn", "yes", "metadata"⟩
    ⟨"trial-balance", (L "trial_balance.section_title_prefix")∾"actual"∾(L "trial_balance.section_title_suffix"), "accounting", "src_next/trial_balance.bqn", "yes", "metadata"⟩
    ⟨"envelopes", L "report.envelope_section_title", "household", "src_next/envelope_computation.bqn", "yes", "metadata"⟩
    ⟨"planned", L "planned.section_title", "operations", "src_next/planned_payments.bqn", "yes", "metadata"⟩
    ⟨"recent", L "recent.section_title", "operations", "src_next/recent_journal.bqn", "yes", "metadata"⟩
    ⟨"check", L "readiness.section_title", "diagnostics", "src_next/readiness_check.bqn", "yes", "metadata"⟩
    ⟨"outlook", L "outlook.section_title", "household", "src_next/outlook.bqn", "yes", "metadata"⟩
    ⟨"daily-trend", L "daily.section_title", "household", "src_next/daily_trend.bqn", "yes", "metadata"⟩
    ⟨"daily-flow", "== Daily Flow ==", "household", "src_next/daily_flow.bqn", "yes", "metadata"⟩
    ⟨"actual-comparison", L "actual.section_title", "household", "src_next/actual_comparison.bqn", "yes", "metadata"⟩
    ⟨"debug", L "report.debug_title", "diagnostics", "src_next/report.bqn", "yes", "metadata"⟩
  ⟩

PrintTsv ← {𝕊:
  •Out "key"∾tab∾"label"∾tab∾"category"∾tab∾"owner"∾tab∾"human_output"∾tab∾"structured_output"
  {𝕊 row: •Out FormatRow row}¨ rows
}

PrintJson ← {𝕊:
  •Out "["
  {𝕊 i:
    suffix ← (i = (≠rows)-1) ⊑ ⟨",", ""⟩
    •Out (FormatJsonRow (i⊑rows)) ∾ suffix
  }¨ ↕≠rows
  •Out "]"
}

Main ← {𝕊 args:
  fmtname ← ArgValue ⟨args, "--format"⟩
  (fmtname ≡ "json") ? (PrintJson @) ; (PrintTsv @)
}

Main •args
