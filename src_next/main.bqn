# main.bqn — src_next developer inspection entrypoint
#
# This is not the production report path. `tools/report` → `src_next/report.bqn`
# is the daily-use entrypoint. This file keeps a compact developer surface for
# AccountKey, checked Posting IR, Cube sanity, and policy diagnostics.
#
# Usage:
#   bqn src_next/main.bqn fixtures/basic
#   bqn src_next/main.bqn fixtures/generalization-moko
#   bqn src_next/main.bqn data

loader ← •Import "loader.bqn"
ak ← •Import "account_key.bqn"
proj ← •Import "projection.bqn"
context ← •Import "context.bqn"
cycle ← •Import "cycle.bqn"
cube ← •Import "cube.bqn"
household_policy ← •Import "household_policy.bqn"
household_metadata ← •Import "household_metadata.bqn"

# ── Developer-only Posting IR presentation ───────────────────
# These helpers intentionally live beside their sole runtime consumer. They do
# not define Posting IR semantics and are not exported by projection.bqn.

ProjCols ← ⟨
  "source_file",
  "source_row",
  "source_id",
  "tx_id",
  "posting_id",
  "date",
  "side",
  "day_index",
  "account_key",
  "account_key_index",
  "layer_name",
  "layer_index",
  "delta",
  "kind",
  "status",
  "message"
⟩

Sum0 ← { 0 < ≠𝕩 ? +´𝕩 ; 0 }

BalanceBySourceOk ← {𝕊 rows:
  ok ← 1
  {𝕊:
    ids ← {𝕩.source_id}¨ rows
    deltas ← {𝕩.delta}¨ rows
    SumForId ← {𝕊 id: Sum0 ((id⊸≡¨ ids) / deltas)}
    sums ← SumForId¨ ids
    ok ↩ ∧´ sums = 0
  }⍟(0 < ≠ rows) @
  ok
}

FormatBalanceCheck ← {𝕊 rows:
  ok ← BalanceBySourceOk rows
  "projection_balance_by_source: " ∾ (ok ⊑ "FAIL"‿"ok")
}

FormatProjTable ← {𝕊 rows:
  FmtOne ← {𝕊 xs: ∾ (•Fmt¨xs) ∾¨ (@+9)}
  hdr ← FmtOne ProjCols

  ToRow ← {𝕊 r:
    ⟨ r.source_file, •Fmt r.source_row, r.source_id, r.tx_id, r.posting_id, r.date, r.side,
      •Fmt r.day_index, r.account_key, •Fmt r.account_key_index, r.layer_name, •Fmt r.layer_index,
      •Fmt r.delta, r.kind, r.status, r.message ⟩
  }

  data ← FmtOne¨ (ToRow¨ rows)
  hdr ∾ (@+10) ∾ ∾ (data ∾¨ (@+10))
}

# ── AccountKey inspection ────────────────────────────────────

PrintAccountKey ← {𝕊 base2:
  lines ← loader.ReadLines (base2 ∾ "/accounts.tsv")
  resolved ← ak.Resolve lines

  •Out "--- AccountKey Table ---"
  •Out "base: " ∾ base2
  •Out "accounts: " ∾ (•Fmt resolved.count)
  •Out ""
  •Out ak.FormatTable resolved
  •Out ""
  •Out "Legend:"
  •Out "  AccountKey = account + / + currency"
  •Out "  Default currency: JPY (when no currency=XXX in accounts.tsv metadata)"
  •Out "  Currency conversion: out of scope for Phase 1"

  resolved
}

# ── Posting IR inspection ────────────────────────────────────

PrintProjHeader ← {𝕊 𝕩:
  •Out ""
  •Out "--- Projection Row Structure ---"
  •Out ""
  # Keep the historical visible label byte-stable for the current developer
  # fixture contract. The canonical row contract is docs/POSTING_IR_CONTRACT.md.
  •Out "Concept (PROJECTION_CONTRACT.md §3):"
  •Out ""
  {•Out 𝕩∾"  "}¨ ProjCols
  •Out ""
  •Out "Layer mapping:"
  •Out "  selected actual source -> actual (layer_index=0)"
  •Out "  plan.tsv         -> plan     (layer_index=1)"
  •Out "  budget_alloc.tsv -> budget   (layer_index=2)"
  •Out "  (forecast)       -> forecast (layer_index=3, reserved)"
  •Out ""
  •Out "Ledger-like: one source row normally emits debit and credit projection rows."
  •Out "Skeleton: no final report section."
}

RowsForSourceFile ← {𝕊 rows‿srcFile:
  (({𝕩.source_file}¨ rows) ≡¨ <srcFile) / rows
}

PrintRowsForFile ← {𝕊 rows‿srcFile‿title:
  selected ← RowsForSourceFile ⟨rows, srcFile⟩
  •Out ""
  •Out "--- Sample Projection Rows (" ∾ title ∾ ") ---"
  •Out ""
  {𝕊: •Out FormatProjTable selected}⍟(0 < ≠ selected) @
  {𝕊: •Out "(none)"}⍟(0 = ≠ selected) @
  selected
}

PrintSampleRows ← {𝕊 rows‿actualFile:
  jrows ← PrintRowsForFile ⟨rows, actualFile, actualFile⟩
  prows ← PrintRowsForFile ⟨rows, "plan.tsv", "plan.tsv"⟩
  jrows ∾ prows
}

# ── Main ─────────────────────────────────────────────────────

Main ← {𝕊 base:
  base2 ← (0 < ≠ base) ⊑ ⟨ ".", base ⟩

  ctx ← context.BuildContext base2
  cy ← ctx.cy
  •Out cycle.FormatCycleInfo cy

  resolved ← PrintAccountKey base2

  PrintProjHeader 0
  rows ← PrintSampleRows ⟨ctx.posting_rows,ctx.actual_source_file⟩
  •Out ""
  •Out FormatBalanceCheck rows

  result ← cube.Materialize ⟨rows, cy.day_count, resolved.count⟩
  •Out cube.FormatCubeSanity ⟨result, resolved.account_keys, cy.day_count, resolved.count⟩

  •Out ""
  •Out cube.FormatMinimalReportSummary ⟨result, resolved.account_keys, cy.start, cy.end_exclusive⟩

  policy_summary ← household_policy.BuildSummary ⟨base2, resolved, result.valid_rows⟩
  policy_text ← household_policy.FormatSummary policy_summary
  {𝕊: •Out policy_text}⍟(0 < ≠ policy_text) @

  hm ← household_metadata.Build { resolved ⇐ resolved }
  hm_text ← household_metadata.Format hm
  {𝕊: •Out hm_text}⍟(0 < ≠ hm_text) @

  •Out ""
  •Out cube.VerifyNumeric ⟨result, resolved.account_keys⟩
}

Main ⊑•args