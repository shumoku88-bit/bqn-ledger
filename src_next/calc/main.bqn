# calc/main.bqn — CLI entry point for envelope calculation tools
# Usage: bqn src_next/calc/main.bqn <base> <op> [args...]
#
# Operations:
#   pace <label>                 P1: pace diagnosis
#   recover <label> <limit>      P2: days to recover with a fixed daily limit
#   recover-target <label> <days> P3: daily limit needed to recover in N days
#   deplete <label>              P4: depletion forecast
#   list                         envelope list
#
# Machine mode: prefix op with "machine:" (e.g. machine:pace)
#   → key:value output for AI consumption

ctx_mod ← •Import "../context.bqn"
env_comp ← •Import "../envelope_computation.bqn"
proj ← •Import "../projection.bqn"
loader ← •Import "../loader.bqn"
calc ← •Import "envelope_calc.bqn"

args ← •args
base ← ⊑ args

# ── Load data ────────────────────────────────────────────

ctx ← ctx_mod.BuildContext base
cy ← ctx.cy
total_days ← cy.day_count
envelopes ← (env_comp.Build ctx).envelopes

LatestActualDate ← {𝕊 base‿cy:
  lines ← loader.ReadLinesOptional (base ∾ "/journal.tsv")
  out ← cy.start
  {𝕊:
    start_dn ← proj.DaysFromEpoch cy.start
    dates ← {⊑ loader.SplitTsvKeepEmpty 𝕩}¨ lines
    in_dates ← ({𝕊 d: (proj.DaysFromEpoch d) ≥ start_dn}¨ dates) / dates
    {𝕊: out ↩ ¯1 ⊑ (∧ in_dates)}⍟(0 < ≠ in_dates) @
  }⍟(0 < ≠ lines) @
  out
}

as_of ← LatestActualDate ⟨base, cy⟩
elapsed ← (as_of ≢ cy.start) ⊑ 0‿(1 + (proj.DaysFromEpoch as_of) - proj.DaysFromEpoch cy.start)

FindEnvelope ← {𝕊 label:
  labels ← {𝕩.label}¨ envelopes
  idx ← ⊑ labels ⊐ ⟨label⟩
  (idx < ≠ labels) ⊑ @‿(idx ⊑ envelopes)
}

# ── Human-mode operation functions ───────────────────────

DoList ← {𝕊:
  •Out "label         | group   | allocated |   spent | remaining"
  •Out "--------------+---------+-----------+---------+----------"
  {𝕊 e:
    lab ← (8 ⌊ ≠ e.label) ↑ e.label ⋄ pad ← (8 - ≠ lab) ⥊ " "
    •Out lab∾pad∾" | "∾(•Fmt e.group)∾" | "∾(•Fmt e.allocated)∾" | "∾(•Fmt e.actual_spent)∾" | "∾(•Fmt e.remaining)
  }¨ envelopes
}

DoPace ← {𝕊 label:
  e ← FindEnvelope label
  out ← ""
  {𝕊: out ↩ calc.FormatPace ⟨calc.EnvelopePace ⟨e.allocated, e.actual_spent, elapsed, total_days⟩, label⟩}⍟(e ≢ @) @
  {𝕊: out ↩ "ERROR: envelope not found: "∾label}⍟(e ≡ @) @
  •Out out
}

DoRecover ← {𝕊 label‿limit_str:
  e ← FindEnvelope label
  out ← ""
  {𝕊:
    limit ← •BQN limit_str
    days ← calc.DaysToRecover ⟨e.allocated, e.actual_spent, elapsed, total_days, limit⟩
    out ↩ calc.FormatRecovery ⟨days, limit, label⟩
  }⍟(e ≢ @) @
  {𝕊: out ↩ "ERROR: envelope not found: "∾label}⍟(e ≡ @) @
  •Out out
}

DoRecoverTarget ← {𝕊 label‿tdays_str:
  e ← FindEnvelope label
  out ← ""
  {𝕊:
    tdays ← •BQN tdays_str
    limit ← calc.RequiredDailyLimit ⟨e.allocated, e.actual_spent, elapsed, total_days, tdays⟩
    out ↩ calc.FormatRecoveryTarget ⟨limit, tdays, label⟩
  }⍟(e ≢ @) @
  {𝕊: out ↩ "ERROR: envelope not found: "∾label}⍟(e ≡ @) @
  •Out out
}

DoDeplete ← {𝕊 label:
  e ← FindEnvelope label
  out ← ""
  {𝕊:
    out ↩ calc.FormatDepletion ⟨calc.EnvelopeDepletion ⟨e.remaining, e.actual_spent, elapsed, total_days⟩, label⟩
  }⍟(e ≢ @) @
  {𝕊: out ↩ "ERROR: envelope not found: "∾label}⍟(e ≡ @) @
  •Out out
}

# ── Machine-mode operation functions ─────────────────────

DoPaceMachine ← {𝕊 label:
  e ← FindEnvelope label
  {𝕊:
    p ← calc.EnvelopePace ⟨e.allocated, e.actual_spent, elapsed, total_days⟩
    calc.FormatPaceMachine ⟨p, label⟩
  }⍟(e ≢ @) @
  {𝕊: •Out "src_next_calc_error: envelope not found: "∾label}⍟(e ≡ @) @
}

DoRecoverMachine ← {𝕊 label‿limit_str:
  e ← FindEnvelope label
  {𝕊:
    limit ← •BQN limit_str
    days ← calc.DaysToRecover ⟨e.allocated, e.actual_spent, elapsed, total_days, limit⟩
    calc.FormatRecoveryMachine ⟨days, limit, label⟩
  }⍟(e ≢ @) @
  {𝕊: •Out "src_next_calc_error: envelope not found: "∾label}⍟(e ≡ @) @
}

DoRecoverTargetMachine ← {𝕊 label‿tdays_str:
  e ← FindEnvelope label
  {𝕊:
    tdays ← •BQN tdays_str
    limit ← calc.RequiredDailyLimit ⟨e.allocated, e.actual_spent, elapsed, total_days, tdays⟩
    calc.FormatRecoveryTargetMachine ⟨limit, tdays, label⟩
  }⍟(e ≢ @) @
  {𝕊: •Out "src_next_calc_error: envelope not found: "∾label}⍟(e ≡ @) @
}

DoDepleteMachine ← {𝕊 label:
  e ← FindEnvelope label
  {𝕊:
    d ← calc.EnvelopeDepletion ⟨e.remaining, e.actual_spent, elapsed, total_days⟩
    calc.FormatDepletionMachine ⟨d, label⟩
  }⍟(e ≢ @) @
  {𝕊: •Out "src_next_calc_error: envelope not found: "∾label}⍟(e ≡ @) @
}

DoListMachine ← {𝕊:
  calc.FormatListMachine envelopes
}

# ── Main dispatch ─────────────────────────────────────────

DoMain ← {𝕊:
  raw_op ← (1 < ≠ args) ⊑ "help"‿(1 ⊑ args)
  is_machine ← "machine:" ≡ 8 ↑ raw_op
  is_debug ← "debug:" ≡ 6 ↑ raw_op
  # Strip known prefixes. Order: machine, debug, or both (machine:debug: or debug:machine:)
  stripped ← raw_op
  {𝕊: stripped ↩ 8 ↓ stripped}⍟(is_machine) @
  {𝕊: stripped ↩ 6 ↓ stripped}⍟(is_debug) @
  {𝕊: is_debug ↩ 1 ⋄ stripped ↩ 6 ↓ stripped}⍟((¬ is_debug) ∧ ("debug:" ≡ 6 ↑ stripped)) @
  op ← stripped

  label_arg ← ""
  extra_arg ← ""
  {𝕊: label_arg ↩ 2 ⊑ args}⍟(2 < ≠ args) @
  {𝕊: extra_arg ↩ 3 ⊑ args}⍟(3 < ≠ args) @

  # Debug output: dump key intermediate values (stdout, [debug] prefix)
  # Only active in human mode to avoid corrupting machine-readable output.
  {𝕊:
    •Out "[debug] cycle: "∾cy.start∾".."∾cy.end_exclusive∾" ("∾(•Fmt total_days)∾" days)"
    •Out "[debug] as_of: "∾as_of∾"  elapsed: "∾(•Fmt elapsed)∾" days"
    •Out "[debug] envelopes:"
    {𝕊 e:
      •Out "[debug]   "∾e.label∾" group="∾e.group∾" allocated="∾(•Fmt e.allocated)∾" spent="∾(•Fmt e.actual_spent)∾" remaining="∾(•Fmt e.remaining)
    }¨ envelopes
  }⍟(is_debug ∧ (¬ is_machine) ∧ (op ≢ "help")) @

  {𝕊:
    •Out "Usage: bqn src_next/calc/main.bqn <base> <op> [label] [args...]"
    •Out "  Operations: pace recover recover-target deplete list"
    •Out "  Prefix op with machine: for key:value output"
    •Out "  Prefix op with debug: for stderr diagnostics"
    •Out "  Combine: machine:debug:pace food"
  }⍟(op ≡ "help") @

  {𝕊: DoList @}⍟((op ≡ "list") ∧ (¬ is_machine)) @
  {𝕊: DoListMachine @}⍟((op ≡ "list") ∧ is_machine) @

  {𝕊: DoPace label_arg}⍟((op ≡ "pace") ∧ (¬ is_machine)) @
  {𝕊: DoPaceMachine label_arg}⍟((op ≡ "pace") ∧ is_machine) @

  {𝕊: DoRecover ⟨label_arg, extra_arg⟩}⍟((op ≡ "recover") ∧ (¬ is_machine)) @
  {𝕊: DoRecoverMachine ⟨label_arg, extra_arg⟩}⍟((op ≡ "recover") ∧ is_machine) @

  {𝕊: DoRecoverTarget ⟨label_arg, extra_arg⟩}⍟((op ≡ "recover-target") ∧ (¬ is_machine)) @
  {𝕊: DoRecoverTargetMachine ⟨label_arg, extra_arg⟩}⍟((op ≡ "recover-target") ∧ is_machine) @

  {𝕊: DoDeplete label_arg}⍟((op ≡ "deplete") ∧ (¬ is_machine)) @
  {𝕊: DoDepleteMachine label_arg}⍟((op ≡ "deplete") ∧ is_machine) @

  known ← ⟨"help","list","pace","recover","recover-target","deplete"⟩
  {𝕊: •Out "ERROR: unknown operation: "∾op}⍟((known ⊐ ⟨op⟩) ≥ ≠ known) @
}

DoMain @
