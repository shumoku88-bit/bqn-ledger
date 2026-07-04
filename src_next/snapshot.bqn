# snapshot.bqn
# Minimal Snapshot observation screen for src_next Stage 4a.
#
# Boundaries:
#   - calculation inputs: existing src_next cycle/cube/readiness/cycle summary values
#   - view model: Build
#   - status label: StatusLabel
#   - text rendering: Format
#   - ASCII art: SelectArt placeholder, rendering-only and not used by checks/calculation
#
# This is an opt-in observation surface, not a production replacement for
# current engine section 1.

loader ← •Import "loader.bqn"
proj ← •Import "projection.bqn"
tbds ← •Import "tbds.bqn"
cube ← •Import "cube.bqn"
fmt ← •Import "format.bqn"
labels ← •Import "report_labels.bqn"
L ← labels.Text
unav ← •Import "unavailable.bqn"
json ← •Import "json.bqn"

fallback_current ← "fallback/current-engine"

# Latest in-cycle actual journal date. src_next has no CLI --as-of yet, so this
# is a conservative observation date derived from source journal rows.
LatestActualDateInCycle ← {𝕊 base‿cy:
  lines ← loader.ReadLinesOptional (base ∾ "/journal.tsv")
  available_cycle ← (cy.start ≢ "unavailable") ∧ (cy.end_exclusive ≢ "unavailable") ∧ (cy.day_count > 0)
  out ← "unavailable/no_data"
  {𝕊:
    start_dn ← proj.DaysFromEpoch cy.start
    end_dn ← proj.DaysFromEpoch cy.end_exclusive
    dates ← {⊑ loader.SplitTsvKeepEmpty 𝕩}¨ lines
    DateInCycle ← {𝕊 d:
      dn ← proj.DaysFromEpoch d
      (dn ≥ start_dn) ∧ (dn < end_dn)
    }
    in_dates ← (DateInCycle¨ dates) / dates
    {𝕊: out ↩ ¯1 ⊑ (∧ in_dates)}⍟(0 < ≠ in_dates) @
  }⍟(available_cycle ∧ (0 < ≠ lines)) @
  out ↩ (¬ available_cycle) ⊑ out‿"unavailable/no_cycle"
  out
}

RemainingDaysText ← {𝕊 asOf‿cy:
  (unav.IsUnavailable asOf) ⊑ (•Fmt ((proj.DaysFromEpoch cy.end_exclusive) - proj.DaysFromEpoch asOf))‿asOf
}

DaysElapsed ← {𝕊 asOf‿cy:
  (unav.IsUnavailable asOf) ⊑ ((proj.DaysFromEpoch asOf) - proj.DaysFromEpoch cy.start)‿¯1
}

StatusLabel ← {𝕊 vm:
  label ← "stable"
  label ↩ ((vm.days_elapsed ≥ 0) ∧ (vm.days_elapsed ≤ 1)) ⊑ label‿"reset"
  label ↩ ((vm.readiness.skipped_rows > 0) ∨ (vm.readiness.unknown_account_count > 0) ∨ (vm.readiness.out_of_cycle_skipped_count > 0)) ⊑ label‿"caution"
  label ↩ ((¬ vm.cycle_available) ∨ unav.IsUnavailable vm.as_of) ⊑ label‿"unknown"
  label
}

# Build: construct snapshot view model from context using TBDS closing balances.
# No longer reads journal.tsv directly (previously used actual_snapshot).
Build ← {𝕊 ctx:
  rows ← ctx.tbds
  resolved ← ctx.resolved
  cy ← ctx.cy

  # Derive cycle_summary directly from tbds
  income_actual ← tbds.ActualIncomeAmount rows
  expense_actual ← tbds.ActualExpenseAmount rows
  net_actual ← income_actual - expense_actual
  plan_expense ← tbds.PlanExpenseAmount rows
  cs ← {
    income_actual ⇐ income_actual,
    expense_actual ⇐ expense_actual,
    net_actual ⇐ net_actual,
    plan_expense ⇐ plan_expense
  }

  # Derive readiness values directly from ctx.cube
  rd ← {
    valid_rows ⇐ ctx.cube.valid_count,
    skipped_rows ⇐ ctx.cube.skipped_count,
    unknown_account_count ⇐ 0,
    out_of_cycle_skipped_count ⇐ ctx.cube.skipped_summary.out_of_period_count
  }

  # Account balances from TBDS actual layer closing
  actualRows ← (cube.layer_actual = {𝕩.layer_index}¨ rows) / rows
  akIndices ← {𝕩.account_key_index}¨ actualRows
  closings ← {𝕩.closing}¨ actualRows
  closingVec ← { cube.Sum0 ((akIndices = 𝕩) / closings) }¨ ↕ resolved.count

  # Account classification (same as actual_snapshot semantics)
  roles ← resolved.roles
  types ← resolved.types
  accounts ← resolved.accounts

  isAsset ← "asset"⊸≡¨ roles
  isLiability ← "liability"⊸≡¨ roles
  isLiquid ← isAsset ∧ ("liquid"⊸≡¨ types)
  isSavings ← isAsset ∧ ("savings"⊸≡¨ types)
  isInvest ← isAsset ∧ ("invest"⊸≡¨ types)

  liq_total ← cube.Sum0 (isLiquid / closingVec)
  sav_total ← cube.Sum0 (isSavings / closingVec)
  inv_total ← cube.Sum0 (isInvest / closingVec)
  assets_total ← liq_total + sav_total + inv_total
  liabilities_total ← cube.Sum0 (isLiability / closingVec)
  net_worth ← assets_total + liabilities_total

  # Nonzero entries for display
  nzMask ← closingVec ≠ 0
  nzIndices ← nzMask / ↕ resolved.count
  entries ← { ⟨𝕩 ⊑ resolved.account_keys, 𝕩 ⊑ closingVec⟩ }¨ nzIndices

  # Liquid breakdown for FormatHuman
  liqActiveMask ← isLiquid ∧ nzMask
  liqIndices ← liqActiveMask / ↕ resolved.count
  liqKeys ← liqIndices ⊏ resolved.account_keys
  liqAmounts ← liqIndices ⊏ closingVec
  liqSorted ← ⌽⍋liqAmounts
  liq_breakdown ← { ⟨ 𝕩 ⊑ liqKeys, 𝕩 ⊑ liqAmounts ⟩ }¨ liqSorted

  # as_of from TBDS period end
  asOf ← cy.end_exclusive
  remaining_days ← RemainingDaysText ⟨asOf, cy⟩
  days_elapsed ← DaysElapsed ⟨asOf, cy⟩
  cycleAvail ← (cy.start ≢ "unavailable") ∧ (cy.end_exclusive ≢ "unavailable") ∧ (cy.day_count > 0)

  vm ← {
    as_of ⇐ asOf,
    cycle_start ⇐ cy.start,
    cycle_end_exclusive ⇐ cy.end_exclusive,
    next_income_equivalent ⇐ cy.end_exclusive,
    remaining_days ⇐ remaining_days,
    days_elapsed ⇐ days_elapsed,
    cycle_available ⇐ cycleAvail,
    cycle_summary ⇐ cs,
    readiness ⇐ rd,
    account_keys ⇐ resolved.account_keys,
    actual_account_totals ⇐ closingVec,
    tbds_account_entries ⇐ entries
  }
  status ← StatusLabel vm
  {
    as_of ⇐ vm.as_of,
    cycle_start ⇐ vm.cycle_start,
    cycle_end_exclusive ⇐ vm.cycle_end_exclusive,
    next_income_equivalent ⇐ vm.next_income_equivalent,
    remaining_days ⇐ vm.remaining_days,
    days_elapsed ⇐ vm.days_elapsed,
    cycle_available ⇐ vm.cycle_available,
    cycle_summary ⇐ vm.cycle_summary,
    readiness ⇐ vm.readiness,
    account_keys ⇐ vm.account_keys,
    actual_account_totals ⇐ vm.actual_account_totals,
    tbds_account_entries ⇐ vm.tbds_account_entries,
    status_label ⇐ status,
    liq_total ⇐ liq_total,
    sav_total ⇐ sav_total,
    inv_total ⇐ inv_total,
    assets_total ⇐ assets_total,
    liabilities_total ⇐ liabilities_total,
    net_worth ⇐ net_worth,
    liq_breakdown ⇐ liq_breakdown,
    section_source_snapshot_base ⇐ "src_next/tbds",
    section_source_cycle ⇐ "src_next/tbds",
    section_source_balances ⇐ "src_next/tbds",
    section_source_envelopes ⇐ fallback_current,
    section_source_outlook_daily ⇐ fallback_current,
    section_source_net_worth ⇐ "src_next/tbds"
  }
}

# ASCII art layer. Placeholder for Stage 4a minimal implementation.
# Keep this rendering-only: callers must not use this string for calculation
# or check status.
SelectArt ← {𝕊 status_label:
  ""
}

FormatAccountTotalsFromEntries ← {𝕊 entries:
  out ← "  account_totals: src_next/partial" ∾ (@+10)
  {
    out ↩ out ∾ "    - " ∾ (0⊑𝕩) ∾ " " ∾ (•Fmt (1⊑𝕩)) ∾ (@+10)
  }¨ entries
  {𝕊: out ↩ out ∾ "    - (none) 0" ∾ (@+10)}⍟(0 = ≠ entries) @
  out
}

FormatAccountTotals ← {𝕊 vm:
  entries ← vm.tbds_account_entries
  FormatAccountTotalsFromEntries entries
}

Format ← {𝕊 vm:
  out ← "--- SrcNext Snapshot ---" ∾ (@+10)
  out ↩ out ∾ "as_of: " ∾ vm.as_of ∾ (@+10)
  out ↩ out ∾ "cycle: " ∾ vm.cycle_start ∾ " .. " ∾ vm.cycle_end_exclusive ∾ " exclusive" ∾ (@+10)
  out ↩ out ∾ "next_income: " ∾ vm.next_income_equivalent ∾ " (cycle_end_equivalent)" ∾ (@+10)
  out ↩ out ∾ "remaining_days: " ∾ vm.remaining_days ∾ (@+10)
  out ↩ out ∾ "status: " ∾ vm.status_label ∾ (@+10)

  art ← SelectArt vm.status_label
  {𝕊: out ↩ out ∾ (@+10) ∾ art ∾ (@+10)}⍟(0 < ≠ art) @

  out ↩ out ∾ (@+10) ∾ "cycle:" ∾ (@+10)
  out ↩ out ∾ "  income_actual:  " ∾ (•Fmt vm.cycle_summary.income_actual) ∾ (@+10)
  out ↩ out ∾ "  expense_actual: " ∾ (•Fmt vm.cycle_summary.expense_actual) ∾ (@+10)
  out ↩ out ∾ "  net_actual:     " ∾ (•Fmt vm.cycle_summary.net_actual) ∾ (@+10)
  out ↩ out ∾ "  plan_expense:   " ∾ (•Fmt vm.cycle_summary.plan_expense) ∾ (@+10)

  out ↩ out ∾ (@+10) ∾ "assets:" ∾ (@+10)
  out ↩ out ∾ FormatAccountTotals vm
  out ↩ out ∾ "  net_worth: " ∾ (•Fmt vm.net_worth) ∾ (@+10)

  out ↩ out ∾ (@+10) ∾ "living:" ∾ (@+10)
  out ↩ out ∾ "  daily_remaining:   " ∾ fallback_current ∾ (@+10)
  out ↩ out ∾ "  food_remaining:    " ∾ fallback_current ∾ (@+10)
  out ↩ out ∾ "  flex_remaining:    " ∾ fallback_current ∾ (@+10)
  out ↩ out ∾ "  reserve_remaining: " ∾ fallback_current ∾ (@+10)

  out ↩ out ∾ (@+10) ∾ "readiness:" ∾ (@+10)
  out ↩ out ∾ "  valid_projection_rows: " ∾ (•Fmt vm.readiness.valid_rows) ∾ (@+10)
  out ↩ out ∾ "  skipped_projection_rows: " ∾ (•Fmt vm.readiness.skipped_rows) ∾ (@+10)
  out ↩ out ∾ "  unknown_account_count: " ∾ (•Fmt vm.readiness.unknown_account_count) ∾ (@+10)
  out ↩ out ∾ "  out_of_cycle_skipped_count: " ∾ (•Fmt vm.readiness.out_of_cycle_skipped_count) ∾ (@+10)
  out ↩ out ∾ (@+10) ∾ "period_scope:" ∾ (@+10)
  out ↩ out ∾ "  NOTE: skipped rows with day_before_start/after_end are valid ledger postings" ∾ (@+10)
  out ↩ out ∾ "  outside the selected report period. They contributed to TBDS opening balances." ∾ (@+10)

  out ↩ out ∾ (@+10) ∾ "notes:" ∾ (@+10)
  out ↩ out ∾ "  - src_next Snapshot is a Stage 4a observation surface" ∾ (@+10)
  out ↩ out ∾ "  - envelope and daily amount values are not implemented here yet" ∾ (@+10)
  out ↩ out ∾ "  - use current engine for daily household decisions when fallback is shown" ∾ (@+10)
  out ↩ out ∾ "  - as_of is TBDS period end (cycle_end_exclusive)" ∾ (@+10)

  out ↩ out ∾ (@+10) ∾ "section_source:" ∾ (@+10)
  out ↩ out ∾ "  snapshot_base: " ∾ vm.section_source_snapshot_base ∾ (@+10)
  out ↩ out ∾ "  cycle: " ∾ vm.section_source_cycle ∾ (@+10)
  out ↩ out ∾ "  balances: " ∾ vm.section_source_balances ∾ (@+10)
  out ↩ out ∾ "  net_worth: " ∾ vm.section_source_net_worth ∾ (@+10)
  out ↩ out ∾ "  envelopes: " ∾ vm.section_source_envelopes ∾ (@+10)
  out ↩ out ∾ "  outlook_daily: " ∾ vm.section_source_outlook_daily ∾ (@+10)
  out
}

# FormatHuman: render Snapshot as human-readable text.
FormatHuman ← {𝕊 vm:
  assets_str ← fmt.Accent fmt.FmtAmt vm.assets_total
  liab_raw ← fmt.FmtAmt (¯1 × vm.liabilities_total)
  liab_str ← (vm.liabilities_total > 0) ⊑ ⟨liab_raw, fmt.Bad liab_raw⟩
  net_raw ← fmt.FmtAmt vm.net_worth
  net_str ← (vm.net_worth < 0) ⊑ ⟨fmt.Ok net_raw, fmt.Bad net_raw⟩
  out ← fmt.Section (L "snapshot.section_title") ∾ (@+10)
  out ↩ out ∾ (L "snapshot.liquid_line") ∾ (fmt.Info fmt.FmtAmt vm.liq_total) ∾ (@+10)
  out ↩ out ∾ (L "snapshot.savings_line") ∾ (fmt.FmtAmt vm.sav_total) ∾ (@+10)
  out ↩ out ∾ (L "snapshot.invest_line") ∾ (fmt.FmtAmt vm.inv_total) ∾ (@+10)
  out ↩ out ∾ "  ------------------------------------" ∾ (@+10)
  out ↩ out ∾ (L "snapshot.assets_total_line") ∾ assets_str ∾ (@+10)
  out ↩ out ∾ (@+10)
  out ↩ out ∾ (L "snapshot.liabilities_total_line") ∾ liab_str ∾ (@+10)
  out ↩ out ∾ "  ------------------------------------" ∾ (@+10)
  out ↩ out ∾ (L "snapshot.net_worth_line") ∾ net_str ∾ (@+10)
  out ↩ out ∾ (@+10)
  out
}

# FormatJson: render Snapshot as structured JSON.
FormatJson ← {𝕊 ctx:
  vm ← Build ctx

  # Helper to parse string to number or return null token (@)
  ToNumOrNull ← {
    (unav.IsUnavailable 𝕩) ? @ ;
    { (0 < ≠𝕩) ? (•BQN 𝕩) ; @ } 𝕩
  }

  rem_days ← { (vm.cycle_available) ? (ToNumOrNull vm.remaining_days) ; @ }
  days_el ← { (vm.cycle_available ∧ (vm.days_elapsed ≠ ¯1)) ? vm.days_elapsed ; @ }

  cycle_start ← { (vm.cycle_available) ? vm.cycle_start ; @ }
  cycle_end ← { (vm.cycle_available) ? vm.cycle_end_exclusive ; @ }

  cycle_summary ← ⟨
    ⟨"income_actual", vm.cycle_summary.income_actual⟩,
    ⟨"expense_actual", vm.cycle_summary.expense_actual⟩,
    ⟨"net_actual", vm.cycle_summary.net_actual⟩,
    ⟨"plan_expense", vm.cycle_summary.plan_expense⟩
  ⟩

  readiness ← ⟨
    ⟨"valid_projection_rows", vm.readiness.valid_rows⟩,
    ⟨"skipped_projection_rows", vm.readiness.skipped_rows⟩,
    ⟨"unknown_account_count", vm.readiness.unknown_account_count⟩,
    ⟨"out_of_cycle_skipped_count", vm.readiness.out_of_cycle_skipped_count⟩
  ⟩

  totals ← ⟨
    ⟨"liquid_assets", vm.liq_total⟩,
    ⟨"savings", vm.sav_total⟩,
    ⟨"investments", vm.inv_total⟩,
    ⟨"assets_total", vm.assets_total⟩,
    ⟨"liabilities_total", vm.liabilities_total⟩,
    ⟨"net_worth", vm.net_worth⟩
  ⟩

  cycle ← ⟨
    ⟨"start", cycle_start⟩,
    ⟨"end_exclusive", cycle_end⟩,
    ⟨"available", vm.cycle_available⟩
  ⟩

  as_of_val ← { (unav.IsUnavailable vm.as_of) ? @ ; vm.as_of }

  root ← ⟨
    ⟨"as_of", as_of_val⟩,
    ⟨"status", vm.status_label⟩,
    ⟨"cycle", cycle⟩,
    ⟨"remaining_days", rem_days⟩,
    ⟨"days_elapsed", days_el⟩,
    ⟨"totals", totals⟩,
    ⟨"cycle_summary", cycle_summary⟩,
    ⟨"readiness", readiness⟩
  ⟩

  json.Serialize root
}

{ Build ⇐ Build, StatusLabel ⇐ StatusLabel, SelectArt ⇐ SelectArt, Format ⇐ Format, FormatHuman ⇐ FormatHuman, FormatJson ⇐ FormatJson, FormatAccountTotalsFromEntries ⇐ FormatAccountTotalsFromEntries, LatestActualDateInCycle ⇐ LatestActualDateInCycle, RemainingDaysText ⇐ RemainingDaysText, DaysElapsed ⇐ DaysElapsed }
