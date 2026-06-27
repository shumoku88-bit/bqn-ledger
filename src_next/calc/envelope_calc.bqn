# envelope_calc.bqn
# Pure calculation primitives for envelope budget consultations.
# P1-P4 from docs/AI_BUDGET_CALCULATOR_DESIGN.md §3.
#
# All functions take simple numeric arguments (no TSV access).
# Pure functions — no side effects.

# ── Helpers ──────────────────────────────────────────────
Floor ← ⌊
Ceil ← ⌈

# P1: 封筒ペース診断
# Args: ⟨allocated, spent, elapsed, total_days⟩
# Returns namespace: ideal_spent, overshoot, daily_actual, daily_target,
#   pace_ratio, health
EnvelopePace ← {𝕊 a‿s‿e‿t:
  daily_target ← Floor a ÷ t
  ideal_spent ← Floor a × e ÷ t
  overshoot ← s - ideal_spent
  daily_actual ← (e > 0) ⊑ 0‿(Floor s ÷ e)
  pace_ratio ← (daily_target > 0) ⊑ 0‿(daily_actual ÷ daily_target)
  health ← (pace_ratio ≥ 1.5) ⊑ ((pace_ratio > 1) ⊑ "SAFE"‿"WARN")‿"SHORT"
  {
    ideal_spent ⇐ ideal_spent,
    overshoot ⇐ overshoot,
    daily_actual ⇐ daily_actual,
    daily_target ⇐ daily_target,
    pace_ratio ⇐ pace_ratio,
    health ⇐ health
  }
}

# P2: 復帰日数（指定した1日上限でペースラインに復帰する日数）
# Args: ⟨allocated, spent, elapsed, total_days, daily_limit⟩
# Returns: days_to_recover (0 if at pace, ∞ if never recoverable)
DaysToRecover ← {𝕊 a‿s‿e‿t‿limit:
  daily_target ← Floor a ÷ t
  overshoot ← s - daily_target × e
  diff ← daily_target - limit
  # overshoot≤0: already at pace → 0
  # diff≤0: limit too high to converge → ∞
  # otherwise: Ceil(overshoot/diff)
  (overshoot ≤ 0) ⊑ ((diff ≤ 0) ⊑ (Ceil (overshoot ÷ diff))‿∞)‿0
}

# P3: 目標復帰日数に対する1日上限額
# Args: ⟨allocated, spent, elapsed, total_days, target_days⟩
# Returns: required_daily_limit (maximum daily spend for target_days)
RequiredDailyLimit ← {𝕊 a‿s‿e‿t‿tdays:
  total_allowed ← Floor a × (e + tdays) ÷ t
  remaining_allowed ← 0 ⌈ total_allowed - s
  Floor remaining_allowed ÷ tdays
}

# P4: 枯渇予測
# Args: ⟨remaining, spent, elapsed, total_days⟩
# Returns namespace: burn_rate, days_until_empty, days_left, shortfall_days
EnvelopeDepletion ← {𝕊 r‿s‿e‿t:
  burn_rate ← (e > 0) ⊑ 0‿(Floor s ÷ e)
  days_left ← t - e
  days_until_empty ← (burn_rate > 0) ⊑ 999‿(Ceil r ÷ burn_rate)
  shortfall_days ← 0 ⌈ days_left - days_until_empty
  {
    burn_rate ⇐ burn_rate,
    days_until_empty ⇐ days_until_empty,
    days_left ⇐ days_left,
    shortfall_days ⇐ shortfall_days
  }
}

# ── Format helpers for human output ───────────────────────

FormatPace ← {𝕊 p‿label:
  spent_total ← p.ideal_spent + p.overshoot
  out ← "── " ∾ label ∾ " ペース診断 ──" ∾ (@+10)
  out ↩ out ∾ "  理想消化額:   " ∾ (•Fmt p.ideal_spent) ∾ (@+10)
  out ↩ out ∾ "  実消化額:     " ∾ (•Fmt spent_total) ∾ (@+10)
  out ↩ out ∾ "  超過額:       " ∾ (•Fmt p.overshoot) ∾ (@+10)
  out ↩ out ∾ "  実績/日:      " ∾ (•Fmt p.daily_actual) ∾ (@+10)
  out ↩ out ∾ "  目標/日:      " ∾ (•Fmt p.daily_target) ∾ (@+10)
  out ↩ out ∾ "  ペース比:     " ∾ (•Fmt (Floor 100 × p.pace_ratio)) ∾ "%" ∾ (@+10)
  out ↩ out ∾ "  判定:         " ∾ p.health ∾ (@+10)
  out
}

FormatRecovery ← {𝕊 days‿limit‿label:
  out ← "── " ∾ label ∾ " 復帰計算 ──" ∾ (@+10)
  (days = ∞) ◶ ⟨
    {𝕊: out ↩ out ∾ "  1日上限 " ∾ (•Fmt limit) ∾ " 円 で ペースラインに戻るまで: " ∾ (•Fmt days) ∾ " 日" ∾ (@+10)},
    {𝕊: out ↩ out ∾ "  1日上限 " ∾ (•Fmt limit) ∾ " 円: 目標ペースより高いため回復不能" ∾ (@+10)}
  ⟩ @
  out
}

FormatRecoveryTarget ← {𝕊 limit‿tdays‿label:
  out ← "── " ∾ label ∾ " 復帰計算 ──" ∾ (@+10)
  out ↩ out ∾ "  " ∾ (•Fmt tdays) ∾ " 日でペースラインに戻るための 1日上限: " ∾ (•Fmt limit) ∾ " 円" ∾ (@+10)
  out
}

FormatDepletion ← {𝕊 d‿label:
  out ← "── " ∾ label ∾ " 枯渇予測 ──" ∾ (@+10)
  out ↩ out ∾ "  消化速度/日:   " ∾ (•Fmt d.burn_rate) ∾ (@+10)
  out ↩ out ∾ "  残日数:        " ∾ (•Fmt d.days_left) ∾ (@+10)
  out ↩ out ∾ "  枯渇まで:      " ∾ (•Fmt d.days_until_empty) ∾ " 日" ∾ (@+10)
  (d.shortfall_days > 0) ◶ ⟨
    {𝕊: out ↩ out ∾ "  判定:          SAFE (残日数内に収まる)" ∾ (@+10)},
    {𝕊: out ↩ out ∾ "  不足日数:      " ∾ (•Fmt d.shortfall_days) ∾ " 日 ⚠" ∾ (@+10)}
  ⟩ @
  out
}

# ── Machine-readable format ──────────────────────────────

FormatPaceMachine ← {𝕊 p‿label:
  •Out "src_next_calc_op: pace"
  •Out "src_next_calc_label: "∾label
  •Out "src_next_calc_ideal_spent: "∾(•Fmt p.ideal_spent)
  •Out "src_next_calc_overshoot: "∾(•Fmt p.overshoot)
  •Out "src_next_calc_daily_actual: "∾(•Fmt p.daily_actual)
  •Out "src_next_calc_daily_target: "∾(•Fmt p.daily_target)
  •Out "src_next_calc_pace_ratio: "∾(•Fmt p.pace_ratio)
  •Out "src_next_calc_health: "∾p.health
}

FormatRecoveryMachine ← {𝕊 days‿limit‿label:
  status ← (days = ∞) ⊑ "recoverable"‿"unrecoverable"
  •Out "src_next_calc_op: recover"
  •Out "src_next_calc_label: "∾label
  •Out "src_next_calc_daily_limit: "∾(•Fmt limit)
  •Out "src_next_calc_days_to_recover: "∾(•Fmt days)
  •Out "src_next_calc_status: "∾status
}

FormatRecoveryTargetMachine ← {𝕊 limit‿tdays‿label:
  •Out "src_next_calc_op: recover-target"
  •Out "src_next_calc_label: "∾label
  •Out "src_next_calc_target_days: "∾(•Fmt tdays)
  •Out "src_next_calc_required_daily_limit: "∾(•Fmt limit)
}

FormatDepletionMachine ← {𝕊 d‿label:
  status ← (d.shortfall_days > 0) ⊑ "safe"‿"shortfall"
  •Out "src_next_calc_op: deplete"
  •Out "src_next_calc_label: "∾label
  •Out "src_next_calc_burn_rate: "∾(•Fmt d.burn_rate)
  •Out "src_next_calc_days_left: "∾(•Fmt d.days_left)
  •Out "src_next_calc_days_until_empty: "∾(•Fmt d.days_until_empty)
  •Out "src_next_calc_shortfall_days: "∾(•Fmt d.shortfall_days)
  •Out "src_next_calc_status: "∾status
}

FormatListMachine ← {𝕊 envs:
  •Out "src_next_calc_op: list"
  •Out "src_next_calc_envelope_count: "∾(•Fmt (≠ envs))
  {𝕊 e:
    •Out "src_next_calc_envelope: "∾e.label∾" "∾e.group∾" "∾(•Fmt e.allocated)∾" "∾(•Fmt e.actual_spent)∾" "∾(•Fmt e.remaining)
  }¨ envs
}

{
  EnvelopePace ⇐ EnvelopePace,
  DaysToRecover ⇐ DaysToRecover,
  RequiredDailyLimit ⇐ RequiredDailyLimit,
  EnvelopeDepletion ⇐ EnvelopeDepletion,
  FormatPace ⇐ FormatPace,
  FormatRecovery ⇐ FormatRecovery,
  FormatRecoveryTarget ⇐ FormatRecoveryTarget,
  FormatDepletion ⇐ FormatDepletion,
  FormatPaceMachine ⇐ FormatPaceMachine,
  FormatRecoveryMachine ⇐ FormatRecoveryMachine,
  FormatRecoveryTargetMachine ⇐ FormatRecoveryTargetMachine,
  FormatDepletionMachine ⇐ FormatDepletionMachine,
  FormatListMachine ⇐ FormatListMachine
}
