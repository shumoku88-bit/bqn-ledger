# daily_trend.bqn
# Daily Trend section for src_next.
# Shows per-day liquid/fund/daily/variable tracking across the cycle.

actual_source ← •Import "actual_source.bqn"
actual_observation ← •Import "actual_observation.bqn"
dt ← •Import "date.bqn"
cube ← •Import "cube.bqn"
fmt ← •Import "format.bqn"
labels ← •Import "report_labels.bqn"
L ← labels.Text
trend_plan ← •Import "daily_trend_plan.bqn"

# ── Build ──────────────────────────────────────────────────

# Pure coordinate preparation. Daily Trend intentionally does not add as_of to
# a nonempty row set; an empty accepted-Actual frontier anchors at cycle.start.
PrepareCoordinates ← {𝕊 cubeView‿cy‿actualDates:
  valid_rows ← cubeView.valid_rows
  j_projs ← (0 = {𝕩.layer_index}¨ valid_rows) / valid_rows
  j_dates ← {𝕩.date}¨ j_projs
  as_of ← actual_observation.LatestInDayCountWindowOrStart ⟨actualDates, cy⟩

  dns ← dt.DaysFromEpoch¨ j_dates
  ord ← ⍋ dns
  sorted_dates ← ord ⊏ j_dates
  sorted_dns ← ord ⊏ dns
  keep ← (sorted_dns ⊐ sorted_dns) = ↕ ≠ sorted_dns
  trend_dates_uniq ← keep / sorted_dates
  trend_dns_uniq ← keep / sorted_dns

  cycle_start_dn ← dt.DaysFromEpoch cy.start
  cycle_end_excl_dn ← dt.DaysFromEpoch cy.end_exclusive
  valid_mask ← (trend_dns_uniq ≥ cycle_start_dn) ∧ (trend_dns_uniq < cycle_end_excl_dn)
  trend_dates_pre ← valid_mask / trend_dates_uniq
  has_trend_dates ← 0 < ≠ trend_dates_pre
  trend_dates ← has_trend_dates ◶ ⟨{ ⟨cy.start⟩ }, { trend_dates_pre }⟩ @

  {as_of⇐as_of,trend_dates⇐trend_dates}
}

# I/O-free numeric core. Date/source preparation and checked plan reserve
# evidence are complete before this boundary.
BuildAvailableFromPrepared ← {𝕊 cubeView‿resolved‿cy‿as_of‿trend_dates‿plan_result:
  c3d ← cubeView.cube
  day_count ← cy.day_count
  ak_count ← resolved.count

  roles ← resolved.roles
  accounts ← resolved.accounts
  types ← resolved.types
  classes ← resolved.spend_classes

  # Account masks (indices into ak axis)
  assets_mask ← ("asset"⊸≡¨ roles) ∨ ("assets:" ⊸ ≡¨ 7 ↑¨ accounts)
  liq_ak ← (assets_mask ∧ ("liquid"⊸≡¨ types)) / ↕ ak_count
  sav_ak ← (assets_mask ∧ ("savings"⊸≡¨ types)) / ↕ ak_count
  var_ak ← (("expense"⊸≡¨ roles) ∧ ("variable"⊸≡¨ classes)) / ↕ ak_count
  fixed_ak ← (("expense"⊸≡¨ roles) ∧ ("fixed"⊸≡¨ classes)) / ↕ ak_count
  inc_ak ← (("income"⊸≡¨ roles) ∨ ("income:" ⊸ ≡¨ 7 ↑¨ accounts)) / ↕ ak_count

  # Layer 0 = actual. Build day×ak cumulative matrix.
  actual_slice ← {𝕊 day: {(day‿𝕩‿0) ⊑ c3d}¨ ↕ ak_count}¨ ↕ day_count
  cum_mat ← +` actual_slice  # shape: day_count × ak_count

  valid_rows ← cubeView.valid_rows
  cycle_start_dn ← dt.DaysFromEpoch cy.start
  cycle_end_excl_dn ← dt.DaysFromEpoch cy.end_exclusive
  trend_dns ← dt.DaysFromEpoch¨ trend_dates
  obs_count ← ≠ trend_dates

  # Checked row-local reserve evidence is prepared by the context adapter.
  reserve_values ← obs_count ⥊ 0
  {𝕊: reserve_values ↩ plan_result.reserves}⍟(plan_result.state ≡ "ok") @

  # 3. Prepare planned-income projection rows. The date cutoff is selected
  # inside each trend row from that row coordinate D, not from report-local L.
  p_rows ← (1 = {𝕩.layer_index}¨ valid_rows) / valid_rows
  p_dns_valid ← {dt.DaysFromEpoch 𝕩.date}¨ p_rows

  # 4. Compute each trend date (absolute day dn)
  trend_rows ← {𝕊 dn:
    d ← dn - cycle_start_dn
    d_safe ← 0 ⌈ d

    cum ← d_safe ⊑ cum_mat
    liq ← cube.Sum0 { 𝕩 ⊑ cum }¨ liq_ak
    sav ← cube.Sum0 { 𝕩 ⊑ cum }¨ sav_ak

    # Current-source coordinate replay: future planned income is row-local.
    # Existing plan admission and income classification remain unchanged.
    future_income_mask ← (p_dns_valid > dn) ∧ (p_dns_valid < cycle_end_excl_dn) ∧ ("debit"⊸≡¨ {𝕩.side}¨ p_rows) ∧ (({𝕩.account_key_index}¨ p_rows) ∊ liq_ak) ∧ (("income"⊸≡¨ {𝕩.kind}¨ p_rows) ∨ ("income:" ⊸ ≡¨ 7 ↑¨ {𝕩.account_key}¨ p_rows))
    planned_future_income ← cube.Sum0 (future_income_mask / {𝕩.delta}¨ p_rows)

    # reserve (fixed reserve): checked Posting IR amount, row-local completion.
    reserve_idx ← ⊑ trend_dns ⊐ ⟨dn⟩
    reserve ← reserve_idx ⊑ reserve_values

    fund ← (liq + planned_future_income) - reserve
    days_left ← 0 ⌈ cycle_end_excl_dn - dn
    daily_div ← 1 ⌈ days_left
    daily ← (days_left > 0) ⊑ 0‿(⌊ (fund ÷ daily_div))

    # Actuals for the day
    day_upd ← d_safe ⊑ actual_slice
    day_var ← cube.Sum0 { 𝕩 ⊑ day_upd }¨ var_ak
    day_sav ← cube.Sum0 { 𝕩 ⊑ day_upd }¨ sav_ak
    day_fixed ← cube.Sum0 { 𝕩 ⊑ day_upd }¨ fixed_ak

    idx_in_dates ← ⊑ (trend_dns = dn) / ↕ obs_count
    date_str ← idx_in_dates ⊑ trend_dates
    
    ⟨date_str, liq, reserve, fund, days_left, daily, day_var, day_sav, day_fixed⟩
  }¨ trend_dns

  # Δdaily: change from previous day
  dailies ← {5⊑𝕩}¨ trend_rows
  prev_daily ← ⟨0⊑dailies⟩ ∾ (¯1 ↓ dailies)
  deltas ← dailies - prev_daily

  rows_with_delta ← {𝕊 i:
    r ← i ⊑ trend_rows
    d ← i ⊑ deltas
    ⟨0⊑r, 1⊑r, 2⊑r, 3⊑r, 4⊑r, 5⊑r, d, 6⊑r, 7⊑r, 8⊑r⟩
  }¨ ↕ ≠ trend_rows

  # Drop top 10
  drop_mask ← deltas < 0
  drop_indices ← drop_mask / ↕ ≠ deltas
  drop_deltas ← drop_mask / deltas
  drop_order ← ⍋ drop_deltas
  top_n ← 10 ⌊ ≠ drop_indices
  top_indices ← top_n ↑ (drop_order ⊏ drop_indices)
  
  top_drops ← {𝕊 i:
    r ← i ⊑ rows_with_delta
    ⟨0⊑r, 6⊑r, 5⊑r, 7⊑r, 8⊑r, 9⊑r⟩
  }¨ top_indices

  visible_rows ← rows_with_delta
  visible_drops ← top_drops
  {𝕊: visible_rows ↩ ⟨⟩ ⋄ visible_drops ↩ ⟨⟩}⍟(plan_result.state ≢ "ok") @

  {
    state ⇐ plan_result.state,
    reason ⇐ plan_result.reason,
    diagnostics ⇐ plan_result.diagnostics,
    trend_rows ⇐ visible_rows,
    top_drops ⇐ visible_drops,
    obs_days ⇐ obs_count,
    as_of ⇐ as_of,
    header_O ⇐ as_of,
    cycle_start ⇐ cy.start,
    cycle_end_exclusive ⇐ cy.end_exclusive,
    cycle_mode ⇐ cy.mode
  }
}

ErrorViewModel ← {𝕊 cy:
  {
    state ⇐ "error",
    reason ⇐ "invalid_trend_coordinate",
    diagnostics ⇐ ⟨⟩,
    trend_rows ⇐ ⟨⟩,
    top_drops ⇐ ⟨⟩,
    obs_days ⇐ 0,
    as_of ⇐ "unavailable",
    header_O ⇐ "unavailable",
    cycle_start ⇐ cy.start,
    cycle_end_exclusive ⇐ cy.end_exclusive,
    cycle_mode ⇐ cy.mode
  }
}

CycleValid ← {𝕊 cy:
  (cy.start ≢ "unavailable") ∧ (cy.end_exclusive ≢ "unavailable") ∧ (dt.IsValidDateText cy.start) ∧ (dt.IsValidDateText cy.end_exclusive)
}

BuildFromPrepared ← {𝕊 cubeView‿resolved‿cy‿as_of‿trend_dates‿plan_result:
  result ← ErrorViewModel cy
  {𝕊:
    coords_ok ← (dt.IsValidDateText as_of) ∧ (0 < ≠ trend_dates) ∧ ∧´ 1 ∾ dt.IsValidDateText¨ trend_dates
    {𝕊: result ↩ BuildAvailableFromPrepared ⟨cubeView, resolved, cy, as_of, trend_dates, plan_result⟩}⍟coords_ok @
  }⍟(CycleValid cy) @
  result
}

Build ← {𝕊 ctx:
  cy ← ctx.cy
  result ← ErrorViewModel cy
  {𝕊:
    dates ← actual_source.DatesFromContext ctx
    coordinates ← PrepareCoordinates ⟨ctx.cube, cy, dates⟩
    plan_result ← trend_plan.BuildAt ⟨ctx, coordinates.trend_dates⟩
    result ↩ BuildFromPrepared ⟨ctx.cube, ctx.resolved, cy, coordinates.as_of, coordinates.trend_dates, plan_result⟩
  }⍟(CycleValid cy) @
  result
}

BuildAt ← {𝕊 ⟨ctx, header_O⟩:
  vm ← Build ctx
  {
    state ⇐ vm.state,
    reason ⇐ vm.reason,
    diagnostics ⇐ vm.diagnostics,
    trend_rows ⇐ vm.trend_rows,
    top_drops ⇐ vm.top_drops,
    obs_days ⇐ vm.obs_days,
    as_of ⇐ vm.as_of,
    header_O ⇐ header_O,
    cycle_start ⇐ vm.cycle_start,
    cycle_end_exclusive ⇐ vm.cycle_end_exclusive,
    cycle_mode ⇐ vm.cycle_mode
  }
}

# ── Format (machine) ───────────────────────────────────────

Format ← {𝕊 vm:
  out ← "--- SrcNext Daily Trend ---" ∾ (@+10)
  {𝕊:
    out ↩ out ∾ "src_next_daily_trend_status: " ∾ vm.state ∾ (@+10)
    out ↩ out ∾ "src_next_daily_trend_reason: " ∾ vm.reason ∾ (@+10)
    {𝕊 diagnostic:
      out ↩ out ∾ "src_next_daily_trend_diagnostic: " ∾ diagnostic.source_file ∾ (@+9) ∾ (•Fmt diagnostic.source_row) ∾ (@+9) ∾ diagnostic.status ∾ (@+9) ∾ diagnostic.date ∾ (@+9) ∾ diagnostic.message ∾ (@+10)
    }¨ vm.diagnostics
  }⍟(vm.state ≢ "ok") @
  {
    r ← 𝕩
    # date_str liquid reserve fund days_left daily var sav delta
    out ↩ out ∾ "src_next_daily_trend: " ∾ (0⊑r) ∾ " " ∾ (•Fmt (1⊑r)) ∾ " " ∾ (•Fmt (2⊑r)) ∾ " " ∾ (•Fmt (3⊑r)) ∾ " " ∾ (•Fmt (4⊑r)) ∾ " " ∾ (•Fmt (5⊑r)) ∾ " " ∾ (•Fmt (7⊑r)) ∾ " " ∾ (•Fmt (8⊑r)) ∾ " " ∾ (•Fmt (6⊑r)) ∾ (@+10)
  }¨ vm.trend_rows
  out
}

# ── FormatHuman ────────────────────────────────────────────

FormatHuman ← {𝕊 vm:
  rows ← vm.trend_rows
  days_left ← 0
  coords_ok ← (vm.cycle_end_exclusive ≢ "unavailable") ∧ (vm.header_O ≢ "unavailable") ∧ (dt.IsValidDateText vm.cycle_end_exclusive) ∧ (dt.IsValidDateText vm.header_O)
  {𝕊: days_left ↩ 0 ⌈ (dt.DaysFromEpoch vm.cycle_end_exclusive) - dt.DaysFromEpoch vm.header_O}⍟coords_ok @

  out ← (L "daily.section_title") ∾ (@+10) ∾ (@+10)
  {𝕊:
    out ↩ out ∾ "ERROR: Daily Trend unavailable (" ∾ vm.reason ∾ ")" ∾ (@+10)
    {𝕊 diagnostic:
      out ↩ out ∾ "  " ∾ diagnostic.source_file ∾ ":" ∾ (•Fmt diagnostic.source_row) ∾ " " ∾ diagnostic.status ∾ " " ∾ diagnostic.message ∾ (@+10)
    }¨ vm.diagnostics
    out
  }⍟(vm.state ≢ "ok") @
  out ↩ out ∾ (L "daily.cycle_label") ∾ vm.cycle_start ∾ " 〜 " ∾ vm.cycle_end_exclusive ∾ (L "daily.current_suffix") ∾ (•Fmt days_left) ∾ (L "daily.current_days_suffix") ∾ (@+10) ∾ (@+10)

  TableRow ← {𝕊 i:
    r ← i ⊑ rows
    delta ← (i = 0) ⊑ ⟨fmt.HumanNumber (6⊑r), "—"⟩
    ⟨0⊑r, fmt.HumanNumber 1⊑r, fmt.HumanNumber 3⊑r, fmt.HumanNumber 5⊑r, delta, fmt.HumanNumber 7⊑r, fmt.HumanNumber 8⊑r⟩
  }
  table_rows ← TableRow¨ ↕ ≠ rows
  headers ← ⟨"Date", "Liquid", "Fund", "Daily", "ΔDaily", "Variable", "Saving"⟩
  out ↩ out ∾ fmt.RenderTable ⟨headers, table_rows, ⟨0, 1, 1, 1, 1, 1, 1⟩⟩
  out
}

{
  Build ⇐ Build,
  BuildAt ⇐ BuildAt,
  BuildFromPrepared ⇐ BuildFromPrepared,
  Format ⇐ Format,
  FormatHuman ⇐ FormatHuman
}
