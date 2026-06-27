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

# ── Latest actual journal date ─────────────────────────────

LatestActualDateInCycle ← {𝕊 base‿cy:
  lines ← loader.ReadLinesOptional (base ∾ "/journal.tsv")
  available ← (cy.start ≢ "unavailable") ∧ (cy.day_count > 0)
  out ← cy.start
  {𝕊:
    start_dn ← proj.DaysFromEpoch cy.start
    dates ← {⊑ loader.SplitTsvKeepEmpty 𝕩}¨ lines
    DateInCycle ← {𝕊 d: (proj.DaysFromEpoch d) ≥ start_dn }
    in_dates ← (DateInCycle¨ dates) / dates
    {𝕊: out ↩ ¯1 ⊑ (∧ in_dates)}⍟(0 < ≠ in_dates) @
  }⍟(available ∧ (0 < ≠ lines)) @
  out
}

# ── Build ──────────────────────────────────────────────────

Build ← {𝕊 ctx:
  base ← ctx.base
  cy ← ctx.cy
  resolved ← ctx.resolved

  cfg ← conf.LoadConfig base
  risk_style ← cfg.PolicyRiskStyle @
  is_simple ← risk_style ≡ "simple"

  # Dates
  as_of ← LatestActualDateInCycle ⟨base, cy⟩
  as_of_dn ← proj.DaysFromEpoch as_of
  end_dn ← proj.DaysFromEpoch cy.end_exclusive
  start_dn ← proj.DaysFromEpoch cy.start
  days_left ← 0⌈ (end_dn - as_of_dn)
  days_elapsed ← 0⌈ (as_of_dn - start_dn) + 1
  journal_lag ← 0  # same date for now

  # Determine active incomes in current period
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

  # as_of actual balance snapshot (full actual history up to as_of)
  snap ← actual_snapshot.BuildAt ⟨ctx, as_of⟩
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
  future_planned_liquid_expenses ← cube.Sum0 (0⌊plan_liquid_deltas)
  planned_future_income ← 0⌈future_planned_liquid_net
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

  # Build budget breakdown using envelope_computation
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
    as_of ⇐ as_of,
    last_journal ⇐ as_of,
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

# ── Format (machine) ───────────────────────────────────────

Format ← {𝕊 vm:
  FmtVal ← { (•Type 𝕩) ≡ 1 ? •Fmt 𝕩 ; 𝕩 }
  out ← "--- SrcNext Outlook ---" ∾ (@+10)
  out ↩ out ∾ "src_next_outlook_as_of: " ∾ vm.as_of ∾ (@+10)
  out ↩ out ∾ "src_next_outlook_days_left: " ∾ (•Fmt vm.days_left) ∾ (@+10)
  out ↩ out ∾ "src_next_outlook_liq_total: " ∾ (•Fmt vm.liq_total) ∾ (@+10)
  out ↩ out ∾ "src_next_outlook_liq_daily: " ∾ (•Fmt vm.liq_daily) ∾ (@+10)
  out ↩ out ∾ "src_next_outlook_liq_safe_daily: " ∾ (FmtVal vm.liq_safe_daily) ∾ (@+10)
  out
}

# ── FormatHuman ────────────────────────────────────────────

FormatHuman ← {𝕊 vm:
  days_left ← vm.days_left
  out ← "== Outlook Dashboard ==" ∾ (@+10) ∾ (@+10)
  out ↩ out ∾ "サイクル: " ∾ vm.cycle_start ∾ " 〜 " ∾ vm.cycle_end_exclusive ∾ "  (残 " ∾ (•Fmt days_left) ∾ " 日)" ∾ (@+10)
  out ↩ out ∾ "基準日:   " ∾ vm.as_of ∾ (@+10) ∾ (@+10)

  AlignR ← {𝕊 w‿x:
    s ← (1 = •Type x) ⊑ ⟨x, •Fmt x⟩
    ((0 ⌈ w - ≠ s) ⥊ " ") ∾ s
  }

  out ↩ out ∾ "── 日割り ──" ∾ (@+10)
  out ↩ out ∾ "  流動資産           " ∾ (AlignR ⟨10, vm.liq_total⟩) ∾ (@+10)
  
  inc_str ← (vm.planned_future_income = 0) ⊑ ("+    0   (なし)")‿("+ " ∾ (•Fmt vm.planned_future_income))
  out ↩ out ∾ "  予定収入(残)       " ∾ (AlignR ⟨10, inc_str⟩) ∾ (@+10)
  
  exp_str ← (vm.fixed_reserve = 0) ⊑ ("-    0   (なし)")‿("-" ∾ (•Fmt vm.fixed_reserve))
  out ↩ out ∾ "  予定支出(残)       " ∾ (AlignR ⟨10, exp_str⟩) ∾ (@+10)
  out ↩ out ∾ "  ─────────────────────────────" ∾ (@+10)
  
  liq_basis ← vm.liq_total + vm.planned_future_income - vm.fixed_reserve
  out ↩ out ∾ "  使える流動資産      " ∾ (AlignR ⟨8, liq_basis⟩) ∾ "  ÷ " ∾ (•Fmt days_left) ∾ "日 = " ∾ (•Fmt vm.liq_daily) ∾ " /日" ∾ (@+10)

  # For backward-compatible tests: if liq_safe_daily is calculated, output it
  {𝕊:
    out ↩ out ∾ "  流動資産 (安全/保守) ÷ 残日数 : " ∾ (fmt.FmtAmt vm.liq_safe_daily) ∾ (@+10)
  }⍟(vm.liq_safe_daily ≢ "unavailable/policy") @

  # Envelope breakdown section
  {𝕊:
    out ↩ out ∾ (@+10) ∾ "── 封筒日割り ──" ∾ (@+10)
    max_w ← ⌈´ ⟨8⟩ ∾ (fmt.VWidth¨ {0⊑𝕩}¨ vm.budget_breakdown)
    hdr_pad ← (max_w - 8) ⥊ " "
    out ↩ out ∾ "  envelope" ∾ hdr_pad ∾ " | remaining | /day" ∾ (@+10)
    
    RenderEnvRow ← {
      label ← 0⊑𝕩 ⋄ remaining ← 1⊑𝕩 ⋄ daily ← 2⊑𝕩
      name_cell ← fmt.PadV ⟨max_w, label⟩
      rem_cell ← AlignR ⟨9, remaining⟩
      day_cell ← AlignR ⟨5, daily⟩
      out ↩ out ∾ "  " ∾ name_cell ∾ " | " ∾ rem_cell ∾ " | " ∾ day_cell ∾ (@+10)
    }
    RenderEnvRow¨ vm.budget_breakdown
  }⍟(0 < ≠ vm.budget_breakdown) @

  out ↩ out ∾ (@+10)
  out
}

{ Build ⇐ Build, Format ⇐ Format, FormatHuman ⇐ FormatHuman, LatestActualDateInCycle ⇐ LatestActualDateInCycle }
