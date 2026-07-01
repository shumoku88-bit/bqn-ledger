# actual_comparison.bqn
# Actual Comparison section for src_next.
# Compares current cycle elapsed period against previous cycle same elapsed period.
#
# Contract: docs/archive/completed-plans/ACTUAL_COMPARISON_REPORT_PLAN.md
#   - Lane: income / recurring_fixed / variable
#   - income: from-account with role=income
#   - expense: to-account with role=expense
#   - recurring_fixed: spend_class=fixed
#   - variable: everything else

loader ← •Import "loader.bqn"
proj ← •Import "projection.bqn"
dt ← •Import "date.bqn"
cube ← •Import "cube.bqn"
fmt ← •Import "format.bqn"
labels ← •Import "report_labels.bqn"
L ← labels.Text

# ── CleanName helper ──────────────────────────────────────
StartsWith ← { 𝕨 ≡ (≠ 𝕨) ↑ 𝕩 }
CleanName ← {
  ( "expenses:" StartsWith 𝕩 ) ? 9 ↓ 𝕩 ;
  ( "income:" StartsWith 𝕩 ) ? 7 ↓ 𝕩 ;
  ( "liabilities:" StartsWith 𝕩 ) ? 12 ↓ 𝕩 ;
  𝕩
}

# ── Date helpers ──────────────────────────────────────────

AddDays ← dt.AddDays

# ── Resolve previous cycle ─────────────────────────────────
# Finds income anchors in journal+plan and picks the pair before the current cycle start.
# Returns: ⟨prev_start_date, prev_start_dn, prev_available⟩

ResolvePreviousCycle ← {𝕊 base‿current_start:
  clines ← loader.ReadLines (base ∾ "/cycle.tsv")
  SplitEq ← { (@+9) loader.Split 𝕩 }
  kv ← SplitEq ¨ clines
  keys ← { ⊑𝕩 } ¨ kv
  vals ← { 1 ⊑ 𝕩 } ¨ kv
  income_account ← (⊑ keys ⊐ ⟨"income_account"⟩) ⊑ vals ∾ ⟨""⟩

  unavailable_result ← ⟨"unavailable", 0, 0⟩
  result ← unavailable_result
  {𝕊:
    jlines ← loader.ReadLines (base ∾ "/journal.tsv")
    SplitJ ← { loader.SplitTsvKeepEmpty 𝕩 }
    jdates ← { ⊑ SplitJ 𝕩 } ¨ jlines
    jfroms ← { 2 ⊑ SplitJ 𝕩 } ¨ jlines
    is_inc ← { (0 < ≠ 𝕩) ∧ (𝕩 ≡ income_account) } ¨ jfroms
    jr_inc_dates ← is_inc / jdates

    jmax ← (0 < ≠ jdates) ⊑ "0001-01-01"‿(¯1 ⊑ (∧ jdates))
    jmax_dn ← proj.DaysFromEpoch jmax

    plines ← loader.ReadLinesOptional (base ∾ "/plan.tsv")
    SplitP ← { loader.SplitTsvKeepEmpty 𝕩 }
    pdates ← { ⊑ SplitP 𝕩 } ¨ plines
    pfroms ← { 2 ⊑ SplitP 𝕩 } ¨ plines
    p_is_inc ← { (0 < ≠ 𝕩) ∧ (𝕩 ≡ income_account) } ¨ pfroms
    p_inc_dates ← p_is_inc / pdates
    future_mask ← { (proj.DaysFromEpoch 𝕩) > jmax_dn } ¨ p_inc_dates
    future_dates ← future_mask / p_inc_dates

    all_dates ← jr_inc_dates ∾ future_dates
    all_dns ← proj.DaysFromEpoch ¨ all_dates
    sorted_dns ← ∧ ((all_dns ⊐ all_dns) = ↕ ≠ all_dns) / all_dns
    sorted_dates ← {𝕊 dn:
      (⊑ all_dns ⊐ ⟨dn⟩) ⊑ all_dates ∾ ⟨"unavailable"⟩
    }¨ sorted_dns

    cur_start_dn ← proj.DaysFromEpoch current_start
    # Current cycle start is at this anchor index in the sorted list.
    # Previous cycle: start at index-1, end at this index.
    cur_anchor_idx ← ⊑ (sorted_dns ≥ cur_start_dn) ⊐ ⟨1⟩
    prev_start_idx ← cur_anchor_idx - 1
    prev_end_idx ← cur_anchor_idx

    available ← (prev_start_idx ≥ 0) ∧ (prev_end_idx < ≠ sorted_dates) ∧ (0 < ≠ sorted_dates)
    result ↩ available ◶ ⟨
      unavailable_result,
      ⟨ (prev_start_idx ⊑ sorted_dates), (prev_start_idx ⊑ sorted_dns), 1 ⟩
    ⟩ @
  }⍟(0 < ≠ income_account) @
  result
}

# ── Build ──────────────────────────────────────────────────

Build ← {𝕊 ctx:
  base ← ctx.base
  cy ← ctx.cy
  resolved ← ctx.resolved

  # Resolve previous cycle
  prev_info ← ResolvePreviousCycle ⟨base, cy.start⟩
  prev_start ← 0 ⊑ prev_info
  prev_start_dn ← 1 ⊑ prev_info
  prev_available ← 2 ⊑ prev_info

  # ── Current period ─────────────────────────────────────
  jlines ← loader.ReadLines (base ∾ "/journal.tsv")
  SplitJ ← { loader.SplitTsvKeepEmpty 𝕩 }
  dates ← { ⊑ SplitJ 𝕩 } ¨ jlines

  as_of ← cy.start
  {𝕊:
    start_dn ← proj.DaysFromEpoch cy.start
    DateInCycle ← {𝕊 d: (proj.DaysFromEpoch d) ≥ start_dn }
    in_dates ← (DateInCycle ¨ dates) / dates
    {𝕊: as_of ↩ ¯1 ⊑ (∧ in_dates) }⍟(0 < ≠ in_dates) @
  }⍟((cy.start ≢ "unavailable") ∧ (cy.day_count > 0) ∧ (0 < ≠ jlines)) @

  current_start ← cy.start
  current_start_dn ← proj.DaysFromEpoch current_start
  as_of_dn ← proj.DaysFromEpoch as_of
  current_end_exclusive ← AddDays ⟨as_of, 1⟩
  current_end_exclusive_dn ← proj.DaysFromEpoch current_end_exclusive
  elapsed_days ← current_end_exclusive_dn - current_start_dn

  # ── Baseline period ────────────────────────────────────
  baseline_start ← prev_start
  baseline_start_dn ← prev_start_dn
  baseline_end_exclusive_dn ← prev_start_dn + elapsed_days
  baseline_end_exclusive ← (prev_available > 0) ⊑ "unavailable"‿(AddDays ⟨prev_start, elapsed_days⟩)

  # ── Observation status ─────────────────────────────────
  observation_status ← "unavailable"
  {𝕊:
    bad ← (¬prev_available) ∨ (baseline_start_dn ≥ baseline_end_exclusive_dn) ∨ (baseline_start_dn ≥ current_start_dn)
    # Get earliest journal date (all journal entries, not just in-cycle)
    earliest_date ← (0 < ≠ dates) ⊑ "0001-01-01"‿(⊑ (∧ dates))
    earliest_dn ← proj.DaysFromEpoch earliest_date
    insufficient ← (¬bad) ∧ (earliest_dn > baseline_start_dn)
    observation_status ↩ bad ◶ ⟨ {𝕊: insufficient ◶ ⟨{𝕊: "ok"}, {𝕊: "insufficient_history"}⟩ @}, {𝕊: "unavailable"} ⟩ @
  }⍟(prev_available > 0) @

  can_compare ← observation_status ≡ "ok"

  # ── Classification ─────────────────────────────────────
  accounts ← resolved.accounts
  roles ← resolved.roles
  spend_classes ← resolved.spend_classes

  AccIdx ← { ⊑ accounts ⊐ ⟨𝕩⟩ }
  AccRole ← {𝕊 acc: (AccIdx acc) ⊑ (roles ∾ ⟨""⟩) }
  AccSpendClass ← {𝕊 acc: (AccIdx acc) ⊑ (spend_classes ∾ ⟨""⟩) }

  IsIncAcc ← {𝕊 acc: "income" ≡ AccRole acc }
  IsExpAcc ← {𝕊 acc: "expense" ≡ AccRole acc }

  # ── Build observation rows ─────────────────────────────
  # obs: ⟨lane, unit_kind, unit, amount, date_dn⟩
  observations ← ⟨⟩
  {𝕊 line:
    flds ← SplitJ line
    ProcessRow ← {𝕊:
      date ← ⊑ flds
      fromAcc ← 2 ⊑ flds
      toAcc ← 3 ⊑ flds
      amtText ← 4 ⊑ flds
      amt ← (0 < ≠ amtText) ⊑ 0‿(•BQN amtText)
      date_dn ← proj.DaysFromEpoch date

      inc ← IsIncAcc fromAcc
      exp ← IsExpAcc toAcc

      {𝕊: observations ↩ observations ∾ ⟨⟨"income", "account", CleanName fromAcc, amt, date_dn⟩⟩ }⍟(inc ∧ amt > 0) @
      {𝕊:
        sc ← AccSpendClass toAcc
        lane ← (sc ≡ "fixed") ⊑ "variable"‿"recurring_fixed"
        observations ↩ observations ∾ ⟨⟨lane, "account", CleanName toAcc, amt, date_dn⟩⟩
      }⍟(exp ∧ amt > 0) @
    }
    ProcessRow⍟(0 < ≠ flds) @
  }¨ jlines

  # ── In-period filter ───────────────────────────────────
  InPeriod ← {𝕊 s_dn‿e_dn‿obs:
    obs_dn ← 4 ⊑ obs ⋄ (s_dn ≤ obs_dn) ∧ (obs_dn < e_dn)
  }

  cur_obs ← ({ InPeriod ⟨current_start_dn, current_end_exclusive_dn, 𝕩⟩ } ¨ observations) / observations
  base_obs ← (can_compare ∧ (≠observations) > 0) ⊑ ⟨⟩‿(({ InPeriod ⟨baseline_start_dn, baseline_end_exclusive_dn, 𝕩⟩ } ¨ observations) / observations)

  # ── Aggregation ────────────────────────────────────────
  AggPeriod ← {𝕊 obs:
    result ← { keys ⇐ ⟨⟩, amounts ⇐ ⟨⟩, counts ⇐ ⟨⟩ }
    {𝕊:
      keys ← { 3 ↑ 𝕩 } ¨ obs
      amts ← 3 ⊑¨ obs
      uniq_mask ← (keys ⊐ keys) = ↕ ≠ keys
      uniq ← uniq_mask / keys
      SumFor ← { k ← 𝕩 ⋄ +´ (k ⊸ ≡ ¨ keys) / amts }
      CountFor ← { k ← 𝕩 ⋄ +´ (k ⊸ ≡ ¨ keys) / (≠ keys) ⥊ 1 }
      result ↩ { keys ⇐ uniq, amounts ⇐ SumFor ¨ uniq, counts ⇐ CountFor ¨ uniq }
    }⍟(0 < ≠ obs) @
    result
  }

  cur_agg ← AggPeriod cur_obs
  base_agg ← AggPeriod base_obs

  # Merge all keys
  all_keys0 ← cur_agg.keys ∾ base_agg.keys
  all_uniq_mask ← (all_keys0 ⊐ all_keys0) = ↕ ≠ all_keys0
  all_keys ← all_uniq_mask / all_keys0

  GetAmt ← {𝕊 key‿agg:
    idx ← ⊑ agg.keys ⊐ ⟨key⟩
    (idx < ≠ agg.keys) ◶ ⟨{𝕊: 0}, {𝕊: idx ⊑ agg.amounts}⟩ @
  }
  GetCount ← {𝕊 key‿agg:
    idx ← ⊑ agg.keys ⊐ ⟨key⟩
    (idx < ≠ agg.keys) ◶ ⟨{𝕊: 0}, {𝕊: idx ⊑ agg.counts}⟩ @
  }

  MakeRow ← {𝕊 k:
    lane ← 0 ⊑ k ⋄ unit_kind ← 1 ⊑ k ⋄ unit ← 2 ⊑ k
    cur_amt ← GetAmt ⟨k, cur_agg⟩
    base_amt ← GetAmt ⟨k, base_agg⟩
    cur_cnt ← GetCount ⟨k, cur_agg⟩
    base_cnt ← GetCount ⟨k, base_agg⟩
    diff_amt ← cur_amt - base_amt
    diff_cnt ← cur_cnt - base_cnt

    ratio_str ← (base_amt = 0) ⊑ ⟨(•Fmt (⌊ (100 × cur_amt) ÷ base_amt))∾"%", "n/a"⟩

    status ← "no_activity"
    {𝕊:
      status ↩ (base_amt = 0) ◶ ⟨
        {𝕊:
          (cur_amt = 0) ◶ ⟨
            {𝕊: (cur_amt > base_amt) ⊑ ⟨(cur_amt < base_amt) ⊑ "same"‿"decreased", "increased"⟩ },
            {𝕊: "stopped" }
          ⟩ @
        },
        {𝕊: "new" }
      ⟩ @
    }⍟(¬ ((base_amt = 0) ∧ (cur_amt = 0))) @

    ⟨"current_cycle_elapsed", lane, unit_kind, unit, current_start, current_end_exclusive, baseline_start, baseline_end_exclusive, cur_amt, base_amt, diff_amt, cur_cnt, base_cnt, diff_cnt, ratio_str, status, observation_status⟩
  }

  table0 ← MakeRow¨ all_keys
  table ← can_compare ⊑ ⟨⟩‿table0

  {
    period_kind ⇐ "current_cycle_elapsed",
    current_start ⇐ current_start,
    current_end_exclusive ⇐ current_end_exclusive,
    baseline_start ⇐ baseline_start,
    baseline_end_exclusive ⇐ baseline_end_exclusive,
    observation_status ⇐ observation_status,
    table ⇐ table,
    as_of ⇐ as_of,
    elapsed_days ⇐ elapsed_days
  }
}

# ── Format (machine / check.sh compatible) ──────────────────

Format ← {𝕊 vm:
  out ← "--- SrcNext Actual Comparison ---" ∾ (@+10)
  out ↩ out ∾ "src_next_actual_comparison_status: " ∾ vm.observation_status ∾ (@+10)
  reason ← (vm.observation_status ≡ "ok") ⊑ (("status:"∾vm.observation_status)‿"comparison_active")
  out ↩ out ∾ "src_next_actual_comparison_reason: " ∾ reason ∾ (@+10)
  {
    r ← 𝕩
    out ↩ out ∾ "src_next_actual_comparison_row: " ∾ (3⊑r) ∾ " lane=" ∾ (1⊑r) ∾ " cur=" ∾ (•Fmt (8⊑r)) ∾ " base=" ∾ (•Fmt (9⊑r)) ∾ " diff=" ∾ (•Fmt (10⊑r)) ∾ " ratio=" ∾ (14⊑r) ∾ " status=" ∾ (15⊑r) ∾ (@+10)
  }¨ vm.table
  out
}

# ── FormatHuman ────────────────────────────────────────────

FormatHuman ← {𝕊 vm:
  out ← (L "actual.section_title") ∾ (@+10)
  out ↩ out ∾ (@+10)

  # Note: Display days elapsed for current, and baseline at the same point in the previous cycle
  out ↩ out ∾ (L "actual.current_label") ∾ (fmt.RangeDisp ⟨vm.current_start, vm.current_end_exclusive⟩) ∾ (L "actual.current_open") ∾ (•Fmt vm.elapsed_days) ∾ (L "actual.current_days_suffix") ∾ (@+10)
  out ↩ out ∾ (L "actual.baseline_label") ∾ (fmt.RangeDisp ⟨vm.baseline_start, vm.baseline_end_exclusive⟩) ∾ (L "actual.baseline_suffix") ∾ (@+10)
  out ↩ out ∾ (@+10)

  (vm.observation_status ≡ "ok") ◶ ⟨
    {𝕊:
      out ↩ out ∾ (L "actual.no_history") ∾ vm.observation_status ∾ ")" ∾ (@+10)
      out ↩ out ∾ (@+10)
    },
    {𝕊:
      table ← vm.table
      (0 < ≠ table) ◶ ⟨
        {𝕊: out ↩ out ∾ (L "actual.no_rows") ∾ (@+10) ∾ (@+10) },
        {𝕊:
          # Sort table: primary key is lane order (income=0, fixed=1, variable=2),
          # secondary key is |diff| descending.
          LaneOrder ← {
            ( "income" ≡ 𝕩 ) ? 0 ;
            ( "recurring_fixed" ≡ 𝕩 ) ? 1 ;
            2
          }
          keys ← { ⟨LaneOrder (1⊑𝕩), ¯1 × | 10⊑𝕩⟩ }¨ table
          table ↩ (⍋keys) ⊏ table

          LaneLabel ← {
            ( "income" ≡ 𝕩 ) ? L "actual.lane_income" ;
            ( "recurring_fixed" ≡ 𝕩 ) ? L "actual.lane_fixed" ;
            L "actual.lane_variable"
          }

          # Resolve display unit names with lane labels appended
          units_with_labels ← { (3⊑𝕩) ∾ LaneLabel (1⊑𝕩) }¨ table
          w_unit ← ⌈´ (fmt.VWidth¨ units_with_labels) ∾ ⟨4⟩
          w_amt ← 10
          w_ratio ← 7
          w_status ← 10

          AlignR ← {𝕊 w‿x:
            s ← (1 = •Type x) ⊑ ⟨x, •Fmt x⟩
            ((0 ⌈ w - ≠ s) ⥊ " ") ∾ s
          }

          out ↩ out ∾ (fmt.PadV ⟨w_unit, (L "actual.table_unit")⟩) ∾ " | " ∾ (AlignR ⟨w_amt, (L "actual.table_current")⟩) ∾ " | " ∾ (AlignR ⟨w_amt, (L "actual.table_baseline")⟩) ∾ " | " ∾ (AlignR ⟨w_amt, (L "actual.table_diff")⟩) ∾ " | " ∾ (AlignR ⟨w_ratio, (L "actual.table_ratio")⟩) ∾ " | " ∾ (fmt.PadV ⟨w_status, (L "actual.table_status")⟩) ∾ (@+10)

          FormatRow ← {𝕊 row:
            lane ← 1⊑row
            unit ← (3⊑row) ∾ LaneLabel lane
            cur ← 8⊑row ⋄ base ← 9⊑row ⋄ diff ← 10⊑row
            ratio ← 14⊑row ⋄ st ← 15⊑row
            (fmt.PadV ⟨w_unit, unit⟩) ∾ " | " ∾ (AlignR ⟨w_amt, cur⟩) ∾ " | " ∾ (AlignR ⟨w_amt, base⟩) ∾ " | " ∾ (AlignR ⟨w_amt, diff⟩) ∾ " | " ∾ (AlignR ⟨w_ratio, ratio⟩) ∾ " | " ∾ (fmt.PadV ⟨w_status, st⟩)
          }

          out ↩ out ∾ ∾ (FormatRow ¨ table) ∾¨ (@+10)
          out ↩ out ∾ (@+10)
        }
      ⟩ @
    }
  ⟩ @

  out
}

{ Build ⇐ Build, Format ⇐ Format, FormatHuman ⇐ FormatHuman }
