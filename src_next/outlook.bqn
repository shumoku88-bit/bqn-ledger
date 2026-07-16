# outlook.bqn
# Outlook / Daily Amount section for src_next.
# Shows asset breakdown, daily liquid amounts, and next-cycle obligations.

conf ← •Import "config.bqn"
loader ← •Import "loader.bqn"
proj ← •Import "projection.bqn"
cube ← •Import "cube.bqn"
tbds ← •Import "tbds.bqn"
actual_snapshot ← •Import "actual_snapshot.bqn"
fmt ← •Import "format.bqn"
labels ← •Import "report_labels.bqn"
L ← labels.Text
env_comp ← •Import "envelope_computation.bqn"

StartsWith ← { pref ← 𝕨 ⋄ pref ≡ (≠ pref) ↑ 𝕩 }
IsMember ← { list ← 𝕨 ⋄ item ← 𝕩 ⋄ (⊑ list ⊐ ⟨item⟩) < ≠ list }

GetMetaVal ← {𝕊 key‿fields:
  (5 < ≠ fields) ◶ ⟨
    { 𝕊 ⋄ "" },
    { 𝕊 ⋄
      metas ← 5 ↓ fields
      FindVal ← {𝕊 meta:
        indices ← (meta = '=') / ↕ ≠ meta
        eq_idx ← (0 < ≠ indices) ◶ ⟨ { 𝕊 ⋄ ≠ meta }, { 𝕊 ⋄ ⊑ indices } ⟩ @
        (eq_idx < ≠ meta) ◶ ⟨
          { 𝕊 ⋄ ⟨⟩ },
          { 𝕊 ⋄
            k ← eq_idx ↑ meta
            v ← (eq_idx + 1) ↓ meta
            (k ≡ key) ◶ ⟨ { 𝕊 ⋄ ⟨⟩ }, { 𝕊 ⋄ ⟨v⟩ } ⟩ @
          }
        ⟩ @
      }
      matches ← ∾ FindVal¨ metas
      (0 < ≠ matches) ◶ ⟨ { 𝕊 ⋄ "" }, { 𝕊 ⋄ 0 ⊑ matches } ⟩ @
    }
  ⟩ @
}

# ── Recorded actual frontier ─────────────────────────────────

# Preserves the current Outlook producer scope: valid journal coordinates at or
# after cycle.start, with no upper cycle bound. Unlike LatestActualDateInCycle,
# this helper keeps absence explicit instead of falling back to cycle.start.
# Invalid-date source evidence is handled by actual_snapshot fail-closed status;
# frontier discovery must not crash before that status can propagate.
RecordedFrontierInfo ← {𝕊 base‿cy:
  lines ← loader.ReadLinesOptional (base ∾ "/journal.tsv")
  scope_available ← (cy.start ≢ "unavailable") ∧ (cy.day_count > 0)
  found ← 0
  out ← ""
  {𝕊:
    start_dn ← proj.DaysFromEpoch cy.start
    dates0 ← {⊑ loader.SplitTsvKeepEmpty 𝕩}¨ lines
    dates ← (proj.IsValidDateText¨ dates0) / dates0
    DateInScope ← {𝕊 d: (proj.DaysFromEpoch d) ≥ start_dn }
    in_dates ← (DateInScope¨ dates) / dates
    {𝕊:
      out ↩ ¯1 ⊑ (∧ in_dates)
      found ↩ 1
    }⍟(0 < ≠ in_dates) @
  }⍟(scope_available ∧ (0 < ≠ lines)) @
  { available ⇐ found, date ⇐ out }
}

# Compatibility helper. Current callers historically receive cycle.start when
# no frontier row exists.
LatestActualDateInCycle ← {𝕊 base‿cy:
  frontier ← RecordedFrontierInfo ⟨base, cy⟩
  out ← cy.start
  {𝕊: out ↩ frontier.date}⍟frontier.available @
  out
}

ClassifyRecordFrontier ← {𝕊 as_of‿frontier:
  relation ← "unavailable"
  distance_days ← "unavailable"
  lag_days ← "unavailable"
  {𝕊:
    o_dn ← proj.DaysFromEpoch as_of
    l_dn ← proj.DaysFromEpoch frontier.date
    delta ← o_dn - l_dn
    relation ↩ "at_observation"
    {𝕊: relation ↩ "before_observation"}⍟(l_dn < o_dn) @
    {𝕊: relation ↩ "after_observation"}⍟(l_dn > o_dn) @
    distance_days ↩ delta
    {𝕊: distance_days ↩ - delta}⍟(delta < 0) @
    lag_days ↩ 0⌈ delta
  }⍟(frontier.available ∧ proj.IsValidDateText as_of) @
  {
    relation ⇐ relation,
    distance_days ⇐ distance_days,
    journal_lag ⇐ lag_days
  }
}

# ── Build ──────────────────────────────────────────────────

ErrorVm ← {𝕊 ctx‿as_of‿frontier‿legacy_default‿snap:
  cy ← ctx.cy
  frontier_relation ← ClassifyRecordFrontier ⟨as_of, frontier⟩
  last_recorded_on ← "unavailable"
  {𝕊: last_recorded_on ↩ frontier.date}⍟frontier.available @
  last_journal ← last_recorded_on
  journal_lag ← frontier_relation.journal_lag
  {𝕊:
    last_journal ↩ as_of
    journal_lag ↩ 0
  }⍟((¬ frontier.available) ∧ legacy_default) @

  {
    state ⇐ "error",
    reason ⇐ snap.reason,
    diagnostics ⇐ snap.diagnostics,
    as_of ⇐ as_of,
    last_journal ⇐ last_journal,
    last_recorded_on ⇐ last_recorded_on,
    record_frontier_relation ⇐ frontier_relation.relation,
    record_frontier_distance_days ⇐ frontier_relation.distance_days,
    journal_lag ⇐ journal_lag,
    cycle_start ⇐ cy.start,
    cycle_end_exclusive ⇐ cy.end_exclusive,
    cycle_mode ⇐ cy.mode,
    days_left ⇐ "unavailable",
    days_elapsed ⇐ "unavailable",
    liq_total ⇐ "unavailable",
    sav_total ⇐ "unavailable",
    inv_total ⇐ "unavailable",
    assets_total ⇐ "unavailable",
    liabilities_total ⇐ "unavailable",
    net_worth ⇐ "unavailable",
    liq_breakdown ⇐ ⟨⟩,
    liq_daily ⇐ "unavailable",
    liq_safe_daily ⇐ "unavailable",
    planned_future_income ⇐ "unavailable",
    fixed_reserve ⇐ "unavailable",
    next_obligations ⇐ ⟨⟩,
    next_obligation_total ⇐ "unavailable",
    budget_breakdown ⇐ ⟨⟩,
    budget_daily_total ⇐ "unavailable"
  }
}

BuildCore ← {𝕊 ctx‿as_of‿frontier‿legacy_default‿snap:
  base ← ctx.base
  cy ← ctx.cy
  resolved ← ctx.resolved

  cfg ← conf.LoadConfig base
  risk_style ← cfg.PolicyRiskStyle @
  is_simple ← risk_style ≡ "simple"

  # Dates
  as_of_dn ← proj.DaysFromEpoch as_of
  end_dn ← proj.DaysFromEpoch cy.end_exclusive
  start_dn ← proj.DaysFromEpoch cy.start
  days_left ← 0⌈ (end_dn - as_of_dn)
  days_elapsed ← 0⌈ (as_of_dn - start_dn) + 1

  frontier_relation ← ClassifyRecordFrontier ⟨as_of, frontier⟩
  last_recorded_on ← "unavailable"
  {𝕊: last_recorded_on ↩ frontier.date}⍟frontier.available @

  # last_journal and journal_lag are compatibility fields. Explicit BuildAt
  # exposes unavailable when no frontier exists; legacy Build preserves its
  # historical cycle.start fallback and zero lag.
  last_journal ← last_recorded_on
  journal_lag ← frontier_relation.journal_lag
  {𝕊:
    last_journal ↩ as_of
    journal_lag ↩ 0
  }⍟((¬ frontier.available) ∧ legacy_default) @

  # Determine active incomes in current period. Anchor activation semantics are
  # intentionally unchanged in Slice A.
  jlines ← loader.ReadLinesOptional (base ∾ "/journal.tsv")
  InPeriodJ ← {𝕊 line:
    flds ← loader.SplitTsvKeepEmpty line
    ok ← 5 ≤ ≠ flds
    r ← 0
    {𝕊:
      dn ← proj.DaysFromEpoch (0⊑flds)
      r ↩ (dn ≥ start_dn) ∧ (dn < end_dn)
    }⍟ok @
    r
  }
  in_period_jlines ← InPeriodJ¨ jlines
  GetIncomeAccJ ← {𝕊 line:
    flds ← loader.SplitTsvKeepEmpty line
    fromAcc ← 2⊑flds
    ("income:" StartsWith fromAcc) ⊑ ⟨""⟩‿⟨fromAcc⟩
  }
  j_incomes ← (0 < ≠ jlines) ◶ ⟨ { 𝕊 ⋄ ⟨⟩ }, { 𝕊 ⋄ ∾ GetIncomeAccJ¨ (in_period_jlines / jlines) } ⟩ @

  plan_lines ← loader.ReadLinesOptional (base ∾ "/plan.tsv")
  InPeriodP ← {𝕊 line:
    flds ← loader.SplitTsvKeepEmpty line
    ok ← 5 ≤ ≠ flds
    r ← 0
    {𝕊:
      dn ← proj.DaysFromEpoch (0⊑flds)
      r ↩ (dn ≥ start_dn) ∧ (dn < end_dn)
    }⍟ok @
    r
  }
  in_period_plines ← InPeriodP¨ plan_lines
  GetIncomeAccP ← {𝕊 line:
    flds ← loader.SplitTsvKeepEmpty line
    fromAcc ← 2⊑flds
    ("income:" StartsWith fromAcc) ⊑ ⟨""⟩‿⟨fromAcc⟩
  }
  p_incomes ← (0 < ≠ plan_lines) ◶ ⟨ { 𝕊 ⋄ ⟨⟩ }, { 𝕊 ⋄ ∾ GetIncomeAccP¨ (in_period_plines / plan_lines) } ⟩ @

  active_incomes ← j_incomes ∾ p_incomes

  # Explicit observation cutoff for actual balances is already authorized and
  # materialized by actual_snapshot before BuildCore is entered.
  liq_total ← snap.liq_total
  sav_total ← snap.sav_total
  inv_total ← snap.inv_total
  assets_total ← snap.assets_total
  liabilities_total ← snap.liabilities_total
  net_worth ← snap.net_worth
  liq_breakdown ← snap.liq_breakdown

  roles ← resolved.roles
  accounts ← resolved.accounts
  types ← resolved.types
  spend_classes ← resolved.spend_classes

  AccIdx ← { ⊑ accounts ⊐ ⟨𝕩⟩ }
  AccRole ← {𝕊 acc: (AccIdx acc) ⊑ (roles ∾ ⟨""⟩) }
  AccType ← {𝕊 acc: (AccIdx acc) ⊑ (types ∾ ⟨""⟩) }
  AccSpendClass ← {𝕊 acc: (AccIdx acc) ⊑ (spend_classes ∾ ⟨""⟩) }

  # Plan rows used by daily amount calculations
  InRemaining ← {𝕊 line:
    flds ← loader.SplitTsvKeepEmpty line
    ok ← 5 ≤ ≠ flds
    r ← 0
    {𝕊:
      dn ← proj.DaysFromEpoch (0⊑flds)
      in_date_range ← (dn ≥ as_of_dn) ∧ (dn < end_dn)
      { 𝕊 ⋄
        anchor ← GetMetaVal ⟨"anchor", flds⟩
        has_anchor ← 0 < ≠ anchor
        active ← has_anchor ◶ ⟨
          { 𝕊 ⋄ active_incomes IsMember anchor },
          { 𝕊 ⋄ 1 }
        ⟩ @
        r ↩ active
      }⍟in_date_range @
    }⍟ok @
    r
  }
  Amount ← {𝕊 line:
    flds ← loader.SplitTsvKeepEmpty line
    amtText ← (4 < ≠ flds) ⊑ "0"‿(4⊑flds)
    proj.IsIntegerText amtText ? •BQN amtText ; 0
  }
  PlanLiquidDelta ← {𝕊 line:
    flds ← loader.SplitTsvKeepEmpty line
    fromAcc ← 2⊑flds ⋄ toAcc ← 3⊑flds ⋄ amt ← Amount line
    to_liq ← (AccType toAcc) ≡ "liquid"
    from_liq ← (AccType fromAcc) ≡ "liquid"
    (to_liq × amt) - (from_liq × amt)
  }
  rem_mask ← InRemaining¨ plan_lines
  plan_liquid_deltas ← PlanLiquidDelta¨ (rem_mask / plan_lines)
  future_planned_liquid_net ← cube.Sum0 plan_liquid_deltas
  future_planned_liquid_income ← cube.Sum0 (0⌈plan_liquid_deltas)
  future_planned_liquid_expenses ← cube.Sum0 (0⌊plan_liquid_deltas)
  planned_future_income ← future_planned_liquid_income
  fixed_reserve ← ¯1 × future_planned_liquid_expenses

  # Next cycle obligations: plan entries on cycle end_exclusive date
  end_dn_obl ← proj.DaysFromEpoch cy.end_exclusive
  ObligationFor ← {𝕊 line:
    flds ← loader.SplitTsvKeepEmpty line
    result ← ⟨⟩
    {𝕊:
      pdate ← 0⊑flds
      pdate_dn ← proj.DaysFromEpoch pdate
      is_end ← pdate_dn = end_dn_obl
      toAcc ← 3⊑flds
      is_obl ← "liabilities:" ≡ 12 ↑ toAcc
      {𝕊:
        amt ← (0 < ≠ 4⊑flds) ⊑ 0‿(•BQN (4⊑flds))
        result ↩ ⟨ ⟨pdate, 1⊑flds, toAcc, amt⟩ ⟩
      }⍟(is_end ∧ is_obl) @
    }⍟(0 < ≠ flds) @
    result
  }
  obligation_rows ← ∾ ObligationFor¨ plan_lines
  next_obligation_total ← (0 < ≠ obligation_rows) ⊑ 0‿(cube.Sum0 ({3⊑𝕩}¨ obligation_rows))

  # Daily amounts. Match current engine plan_view semantics:
  # liq_daily uses projected liquid balance after all remaining plan liquid deltas;
  # liq_safe_daily reserves future planned liquid outflows.
  liq_basis ← liq_total + future_planned_liquid_net
  liq_safe_basis ← liq_total + future_planned_liquid_expenses
  liq_daily ← (days_left > 0) ⊑ 0‿(⌊ (liq_basis ÷ days_left))
  liq_safe_daily ← is_simple ◶ ⟨
    { 𝕊 ⋄ (days_left > 0) ⊑ 0‿(⌊ (liq_safe_basis ÷ days_left)) },
    { 𝕊 ⋄ "unavailable/policy" }
  ⟩ @

  # Build budget breakdown using envelope_computation. Envelope temporal semantics
  # remain outside this explicit-observation slice.
  env_summary ← env_comp.Build ctx
  life_groups ← cfg.HouseholdGroupLifeLabels @
  daily_flex_envs ← ( { life_groups IsMember 𝕩.group }¨ env_summary.envelopes ) / env_summary.envelopes
  budget_breakdown ← {
    e ← 𝕩
    daily_val ← (days_left > 0) ⊑ 0‿(⌊ e.remaining ÷ days_left)
    ⟨e.label, e.remaining, daily_val⟩
  }¨ daily_flex_envs
  budget_daily_total ← cube.Sum0 ({2⊑𝕩}¨ budget_breakdown)

  {
    state ⇐ "ok",
    reason ⇐ "outlook_active",
    diagnostics ⇐ ⟨⟩,
    as_of ⇐ as_of,
    last_journal ⇐ last_journal,
    last_recorded_on ⇐ last_recorded_on,
    record_frontier_relation ⇐ frontier_relation.relation,
    record_frontier_distance_days ⇐ frontier_relation.distance_days,
    journal_lag ⇐ journal_lag,
    cycle_start ⇐ cy.start,
    cycle_end_exclusive ⇐ cy.end_exclusive,
    cycle_mode ⇐ cy.mode,
    days_left ⇐ days_left,
    days_elapsed ⇐ days_elapsed,
    liq_total ⇐ liq_total,
    sav_total ⇐ sav_total,
    inv_total ⇐ inv_total,
    assets_total ⇐ assets_total,
    liabilities_total ⇐ liabilities_total,
    net_worth ⇐ net_worth,
    liq_breakdown ⇐ liq_breakdown,
    liq_daily ⇐ liq_daily,
    liq_safe_daily ⇐ liq_safe_daily,
    planned_future_income ⇐ planned_future_income,
    fixed_reserve ⇐ fixed_reserve,
    next_obligations ⇐ obligation_rows,
    next_obligation_total ⇐ next_obligation_total,
    budget_breakdown ⇐ budget_breakdown,
    budget_daily_total ⇐ budget_daily_total
  }
}

BuildWithSnapshot ← {𝕊 ctx‿as_of‿frontier‿legacy_default:
  snap ← actual_snapshot.BuildAt ⟨ctx, as_of⟩
  vm ← ErrorVm ⟨ctx, as_of, frontier, legacy_default, snap⟩
  {𝕊: vm ↩ BuildCore ⟨ctx, as_of, frontier, legacy_default, snap⟩}⍟(snap.state ≡ "ok") @
  vm
}

# Caller-owned explicit Outlook observation path.
BuildAt ← {𝕊 ctx‿as_of:
  frontier ← RecordedFrontierInfo ⟨ctx.base, ctx.cy⟩
  BuildWithSnapshot ⟨ctx, as_of, frontier, 0⟩
}

# Compatibility default: preserve current local-L observation policy.
Build ← {𝕊 ctx:
  frontier ← RecordedFrontierInfo ⟨ctx.base, ctx.cy⟩
  as_of ← LatestActualDateInCycle ⟨ctx.base, ctx.cy⟩
  BuildWithSnapshot ⟨ctx, as_of, frontier, 1⟩
}

# ── Format (machine) ───────────────────────────────────────

Format ← {𝕊 vm:
  FmtVal ← { (•Type 𝕩) ≡ 1 ? •Fmt 𝕩 ; 𝕩 }
  out ← "--- SrcNext Outlook ---" ∾ (@+10)
  out ↩ out ∾ "src_next_outlook_status: " ∾ vm.state ∾ (@+10)
  out ↩ out ∾ "src_next_outlook_reason: " ∾ vm.reason ∾ (@+10)
  out ↩ out ∾ "src_next_outlook_as_of: " ∾ vm.as_of ∾ (@+10)
  out ↩ out ∾ "src_next_outlook_days_left: " ∾ (FmtVal vm.days_left) ∾ (@+10)
  out ↩ out ∾ "src_next_outlook_liq_total: " ∾ (FmtVal vm.liq_total) ∾ (@+10)
  out ↩ out ∾ "src_next_outlook_liq_daily: " ∾ (FmtVal vm.liq_daily) ∾ (@+10)
  out ↩ out ∾ "src_next_outlook_liq_safe_daily: " ∾ (FmtVal vm.liq_safe_daily) ∾ (@+10)
  {𝕊 diagnostic:
    out ↩ out ∾ "src_next_outlook_diagnostic: " ∾ diagnostic.source_file ∾ (@+9) ∾ (•Fmt diagnostic.source_row) ∾ (@+9) ∾ diagnostic.status ∾ (@+9) ∾ diagnostic.date ∾ (@+9) ∾ diagnostic.message ∾ (@+10)
  }¨ vm.diagnostics
  out
}

# ── FormatHuman ────────────────────────────────────────────

FormatHumanOk ← {𝕊 vm:
  days_left ← vm.days_left
  out ← (L "outlook.section_title") ∾ (@+10) ∾ (@+10)
  out ↩ out ∾ (L "outlook.cycle_label") ∾ vm.cycle_start ∾ " " ∾ (L "outlook.range_separator") ∾ " " ∾ vm.cycle_end_exclusive ∾ (L "outlook.remaining_open") ∾ (•Fmt days_left) ∾ (L "outlook.remaining_close") ∾ (@+10)
  out ↩ out ∾ (L "outlook.as_of_label") ∾ vm.as_of ∾ (@+10) ∾ (@+10)

  AlignR ← {𝕊 w‿x:
    s ← (1 = •Type x) ⊑ ⟨x, •Fmt x⟩
    ((0 ⌈ w - ≠ s) ⥊ " ") ∾ s
  }

  out ↩ out ∾ (L "outlook.daily_title") ∾ (@+10)
  out ↩ out ∾ (L "outlook.liquid_label") ∾ (AlignR ⟨10, vm.liq_total⟩) ∾ (@+10)

  inc_str ← (vm.planned_future_income ≠ 0) ⊑ (L "outlook.future_none")‿("+ " ∾ (•Fmt vm.planned_future_income))
  out ↩ out ∾ (L "outlook.future_income_label") ∾ (AlignR ⟨10, inc_str⟩) ∾ (@+10)

  exp_str ← (vm.fixed_reserve ≠ 0) ⊑ (L "outlook.expense_none")‿("-" ∾ (•Fmt vm.fixed_reserve))
  out ↩ out ∾ (L "outlook.future_expense_label") ∾ (AlignR ⟨10, exp_str⟩) ∾ (@+10)
  out ↩ out ∾ "  " ∾ (L "outlook.daily_separator") ∾ (@+10)

  liq_basis ← vm.liq_total + vm.planned_future_income - vm.fixed_reserve
  out ↩ out ∾ (L "outlook.using_liquid_label") ∾ (AlignR ⟨8, liq_basis⟩) ∾ "  ÷ " ∾ (•Fmt days_left) ∾ (L "outlook.days_suffix") ∾ (•Fmt vm.liq_daily) ∾ (L "outlook.per_day_suffix") ∾ (@+10)

  # Envelope breakdown section
  {𝕊:
    out ↩ out ∾ (@+10) ∾ (L "outlook.envelope_title") ∾ (@+10)
    name_header ← L "outlook.envelope_name_header"
    remaining_header ← L "outlook.envelope_remaining_header"
    per_day_header ← L "outlook.envelope_per_day_header"
    column_separator ← " " ∾ (L "outlook.envelope_column_separator") ∾ " "
    name_header_width ← fmt.VWidth name_header
    max_w ← ⌈´ ⟨name_header_width⟩ ∾ (fmt.VWidth¨ {0⊑𝕩}¨ vm.budget_breakdown)
    hdr_pad ← (max_w - name_header_width) ⥊ " "
    out ↩ out ∾ "  " ∾ name_header ∾ hdr_pad ∾ column_separator ∾ remaining_header ∾ column_separator ∾ per_day_header ∾ (@+10)

    RenderEnvRow ← {
      label ← 0⊑𝕩 ⋄ remaining ← 1⊑𝕩 ⋄ daily ← 2⊑𝕩
      name_cell ← fmt.PadV ⟨max_w, label⟩
      rem_cell ← AlignR ⟨9, remaining⟩
      day_cell ← AlignR ⟨5, daily⟩
      out ↩ out ∾ "  " ∾ name_cell ∾ column_separator ∾ rem_cell ∾ column_separator ∾ day_cell ∾ (@+10)
    }
    RenderEnvRow¨ vm.budget_breakdown
  }⍟(0 < ≠ vm.budget_breakdown) @

  out ↩ out ∾ (@+10)
  out
}

FormatHumanError ← {𝕊 vm:
  out ← (L "outlook.section_title") ∾ (@+10) ∾ (@+10)
  out ↩ out ∾ (L "outlook.cycle_label") ∾ vm.cycle_start ∾ " " ∾ (L "outlook.range_separator") ∾ " " ∾ vm.cycle_end_exclusive ∾ (@+10)
  out ↩ out ∾ (L "outlook.as_of_label") ∾ vm.as_of ∾ (@+10) ∾ (@+10)
  out ↩ out ∾ (L "outlook.error") ∾ " (" ∾ vm.reason ∾ ")" ∾ (@+10)
  {𝕊 diagnostic:
    out ↩ out ∾ "  " ∾ diagnostic.source_file ∾ ":" ∾ (•Fmt diagnostic.source_row) ∾ " " ∾ diagnostic.status ∾ " " ∾ diagnostic.message ∾ (@+10)
  }¨ vm.diagnostics
  out ↩ out ∾ (@+10)
  out
}

FormatHuman ← {𝕊 vm:
  out ← FormatHumanError vm
  {𝕊: out ↩ FormatHumanOk vm}⍟(vm.state ≡ "ok") @
  out
}

{ Build ⇐ Build, BuildAt ⇐ BuildAt, Format ⇐ Format, FormatHuman ⇐ FormatHuman, LatestActualDateInCycle ⇐ LatestActualDateInCycle }
