# cycle.bqn
# Read-only cycle.tsv reader for the cycle-ledger prototype.
#
# Contract (DATA_CONTRACT.md §4.5):
#   - cycle.tsv defines living-cycle boundaries
#   - treated as half-open interval [start, end_exclusive)
#   - read-only, no rewrite
#
# Supported modes:
#   fixed          start (inclusive) .. end_exclusive (exclusive)
#   incomeAnchor   resolved from nearest income dates in journal/plan
#   calendarMonth  recurring start_day resolved around observation as_of

loader ← •Import "loader.bqn"
dt    ← •Import "date.bqn"
actual_source ← •Import "actual_source.bqn"

# ── Day count between two YYYY-MM-DD dates ───────────────────
# Uses dt.DaysFromEpoch (pure BQN, no external date command).
DayCount ← {
  (dt.DaysFromEpoch (1⊑𝕩)) - dt.DaysFromEpoch (0⊑𝕩)
}

# ── Parse cycle.tsv into key→value map ──────────────────────
# The internal resolver can consume complete admitted transactions supplied by
# an outer source adapter. That path preserves cycle ownership while avoiding a
# second Journal read/admission solely to recover dates and income evidence.
ReadCycleWithEvidence ← {𝕊 base‿asOfInput‿useDefaultAsOf‿hasEvidence‿actualEvidence:
  JournalDates ← {𝕊:
    hasEvidence ◶ ⟨
      {𝕊: actual_source.LoadDates base},
      {𝕊: {𝕩.date}¨ actualEvidence.transactions}
    ⟩ @
  }
  IncomeDates ← {𝕊 incomeAccount:
    hasEvidence ◶ ⟨
      {𝕊: actual_source.IncomeDates ⟨base, incomeAccount⟩},
      {𝕊: actual_source.IncomeDatesFromCycleEvidence ⟨incomeAccount, actualEvidence⟩}
    ⟩ @
  }
  DefaultAsOf ← {𝕊:
    jdates ← JournalDates @
    valid_dates ← (dt.IsValidDateText¨ jdates) / jdates
    (0 < ≠ valid_dates) ◶ ⟨ { 𝕩 ⋄ dt.Today @ }, { 𝕩 ⋄ ¯1 ⊑ (∧ valid_dates) } ⟩ @
  }
  as_of ← asOfInput
  {𝕊: as_of ↩ DefaultAsOf @}⍟useDefaultAsOf @
  path ← base ∾ "/cycle.tsv"
  lines ← loader.ReadLines path

  # Each line: key<TAB>value
  SplitEq ← { (@+9) loader.Split 𝕩 }

  kv ← SplitEq ¨ lines
  keys ← { ⊑𝕩 } ¨ kv
  vals ← { 1 ⊑ 𝕩 } ¨ kv

  # Build lookup: given key array and val array, find val for key
  # Returns "" when key not found.
  Lookup ← {𝕊 needle:
    i ← ⊑ keys ⊐ ⟨needle⟩
    i ⊑ vals ∾ ⟨""⟩
  }

  # Extract known fields
  mode   ← Lookup "mode"
  start  ← Lookup "start"
  endExc ← Lookup "end_exclusive"

  # ── Helper: resolve incomeAnchor cycle ───────────────────
  ResolveIncomeAnchor ← { 𝕩 ⋄
    income_account ← Lookup "income_account"

    # Read the explicitly selected Actual evidence. A prepared caller supplies
    # already-admitted transactions; the compatibility adapter loads them.
    jdates ← JournalDates @
    inc_dates ← IncomeDates income_account

    # Max journal date (all rows, for plan future-filter)
    jmax ← ¯1 ⊑ (∧ jdates)

    # Read plan.tsv: extract dates and from-accounts
    plines ← loader.ReadLinesOptional (base ∾ "/plan.tsv")
    SplitP ← { (@+9) loader.Split 𝕩 }
    pdates ← { ⊑ SplitP 𝕩 } ¨ plines
    pfroms ← { 2 ⊑ SplitP 𝕩 } ¨ plines

    # Plan income rows after journal max date
    jmax_dn ← dt.DaysFromEpoch jmax
    IncIdx ← {𝕊 idx:
      d ← idx ⊑ pdates
      ((idx ⊑ pfroms) ≡ income_account) ∧ ((dt.DaysFromEpoch d) > jmax_dn)
    }
    inc_indices ← IncIdx ¨ ↕ (≠ plines)
    future_dates ← inc_indices / pdates

    # Resolve start/end
    n_inc ← ≠ inc_dates
    n_fut ← ≠ future_dates
    available ← (0 < ≠ income_account) ∧ (0 < n_inc) ∧ (0 < n_fut)

    available ◶ ⟨
      { mode ⇐ "unavailable", start ⇐ "unavailable", end_exclusive ⇐ "unavailable", day_count ⇐ 0 },
      {
        start_date ← ¯1 ⊑ (∧ inc_dates)
        end_date   ← ⊑ (∧ future_dates)
        days ← DayCount ⟨start_date, end_date⟩
        { mode ⇐ mode, start ⇐ start_date, end_exclusive ⇐ end_date, day_count ⇐ days }
      }
    ⟩ @
  }

  # ── Helper: resolve calendarMonth cycle ──────────────────
  ResolveCalendarMonth ← { 𝕩 ⋄
    start_day_str ← Lookup "start_day"
    start_day     ← (0 < ≠ start_day_str) ◶ ⟨ { 1 }, { •BQN start_day_str } ⟩ @

    y ‿ m ‿ d ← dt.Parts as_of

    # Check if we are in the previous month's cycle
    is_prev ← d < start_day

    # Calculate start year and month
    start_m ← is_prev ◶ ⟨ m, (m = 1) ◶ ⟨ m - 1, 12 ⟩ ⟩ @
    start_y ← is_prev ◶ ⟨ y, y - (m = 1) ⟩ @

    # Calculate end year and month
    end_m ← is_prev ◶ ⟨ (m = 12) ◶ ⟨ m + 1, 1 ⟩, m ⟩ @
    end_y ← is_prev ◶ ⟨ y + (m = 12), y ⟩ @

    Pad2 ← { s ← •Fmt 𝕩 ⋄ ((0 ⌈ 2-≠s)⥊'0') ∾ s }
    start_date ← (•Fmt start_y) ∾ "-" ∾ (Pad2 start_m) ∾ "-" ∾ (Pad2 start_day)
    end_date   ← (•Fmt end_y)   ∾ "-" ∾ (Pad2 end_m)   ∾ "-" ∾ (Pad2 start_day)

    days ← DayCount ⟨start_date, end_date⟩
    { mode ⇐ mode, start ⇐ start_date, end_exclusive ⇐ end_date, day_count ⇐ days }
  }

  # ── Select resolver by mode ──────────────────────────────
  mode_idx ← (mode ≡ "incomeAnchor") + (2 × (mode ≡ "fixed")) + (3 × (mode ≡ "calendarMonth"))
  mode_idx ◶ ⟨
    { 𝕩 ⋄ { mode ⇐ "unavailable", start ⇐ "unavailable", end_exclusive ⇐ "unavailable", day_count ⇐ 0 } },
    ResolveIncomeAnchor,
    { 𝕩 ⋄
      has_dates ← (0 < ≠ start) ∧ (0 < ≠ endExc)
      has_dates ◶ ⟨
        { 𝕩 ⋄ { mode ⇐ "unavailable", start ⇐ "unavailable", end_exclusive ⇐ "unavailable", day_count ⇐ 0 } },
        { 𝕩 ⋄
          days ← DayCount ⟨start, endExc⟩
          { mode ⇐ mode, start ⇐ start, end_exclusive ⇐ endExc, day_count ⇐ days }
        }
      ⟩ @
    },
    { 𝕩 ⋄ ResolveCalendarMonth @ }
  ⟩ @
}

# Compatibility adapter: preserve the existing string / ⟨base,as_of⟩ API and
# its source-loading behavior.
ReadCycle ← {𝕊 arg:
  is_string ← (0 = ≠ arg) ∨ (2 = •Type 0 ⊑ arg ∾ ⟨' '⟩)
  base ← is_string ⊑ ⟨0 ⊑ arg, arg⟩
  asOfInput ← ""
  {𝕊: asOfInput ↩ 1 ⊑ arg}⍟(¬is_string) @
  emptyEvidence ← {complete⇐0, transactions⇐⟨⟩}
  ReadCycleWithEvidence ⟨base, asOfInput, is_string, 0, emptyEvidence⟩
}

# Reuse one source-owned cycle evidence result while preserving its complete or
# historical-fallback transaction shape.
ReadCycleFromActualEvidence ← {𝕊 base‿evidence:
  ReadCycleWithEvidence ⟨base, "", 1, 1, evidence⟩
}
ReadCycleFromActualEvidenceAt ← {𝕊 base‿asOf‿evidence:
  ReadCycleWithEvidence ⟨base, asOf, 0, 1, evidence⟩
}

# Selected-domain adapter: complete admission has already established the
# transaction/posting shape. Cycle still owns date selection, income-account
# interpretation, plan evidence, and period construction.
ReadCycleFromAdmittedTransactions ← {𝕊 base‿transactions:
  evidence ← {complete⇐1, transactions⇐transactions}
  ReadCycleFromActualEvidence ⟨base, evidence⟩
}

# ── Format cycle info for sanity display ─────────────────────
FormatCycleInfo ← {
  cycle ← 𝕩
  lines ← ⟨
    "--- Cycle Info ---",
    "mode: " ∾ cycle.mode,
    "start: " ∾ cycle.start,
    "end_exclusive: " ∾ cycle.end_exclusive,
    "day_count: " ∾ (•Fmt cycle.day_count)
  ⟩
  ∾ (lines ∾¨ (@+10))
}

{ ReadCycle ⇐ ReadCycle, ReadCycleFromActualEvidence ⇐ ReadCycleFromActualEvidence, ReadCycleFromActualEvidenceAt ⇐ ReadCycleFromActualEvidenceAt, ReadCycleFromAdmittedTransactions ⇐ ReadCycleFromAdmittedTransactions, FormatCycleInfo ⇐ FormatCycleInfo, DayCount ⇐ DayCount }
