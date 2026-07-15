# actual_comparison.bqn
# Actual Comparison section for src_next.
# Compares the explicitly observed current-cycle elapsed period with the same
# elapsed length from the previous comparable income anchor.
#
# Numeric ownership:
#   checked ledger-wide Posting IR -> local actual-layer TBDS period views
# Evidence ownership:
#   checked posting source identity for counts, anchors, and rejected rows

loader ← •Import "loader.bqn"
proj ← •Import "projection.bqn"
dt ← •Import "date.bqn"
cube ← •Import "cube.bqn"
tbds ← •Import "tbds.bqn"
fmt ← •Import "format.bqn"
labels ← •Import "report_labels.bqn"
L ← labels.Text

StartsWith ← { 𝕨 ≡ (≠ 𝕨) ↑ 𝕩 }
CleanName ← {
  ( "expenses:" StartsWith 𝕩 ) ? 9 ↓ 𝕩 ;
  ( "income:" StartsWith 𝕩 ) ? 7 ↓ 𝕩 ;
  ( "liabilities:" StartsWith 𝕩 ) ? 12 ↓ 𝕩 ;
  𝕩
}

# cycle.tsv remains a narrow anchor-identity evidence dependency. It supplies
# no amount and is not used for numeric aggregation.
IncomeAnchorAccount ← {𝕊 base:
  lines ← loader.ReadLines (base ∾ "/cycle.tsv")
  kv ← { (@+9) loader.Split 𝕩 } ¨ lines
  keys ← {⊑𝕩}¨kv
  vals ← {1⊑𝕩}¨kv
  idx ← ⊑ keys ⊐ ⟨"income_account"⟩
  idx ⊑ vals ∾ ⟨""⟩
}

AccountName ← {𝕊 resolved‿row: row.account_key_index ⊑ resolved.accounts }
AccountRole ← {𝕊 resolved‿row: row.account_key_index ⊑ resolved.roles }
AccountSpendClass ← {𝕊 resolved‿row: row.account_key_index ⊑ resolved.spend_classes }

LedgerRowValid ← {𝕊 resolved‿row:
  (row.status ≡ "ok") ∧ (row.account_key_index ≥ 0) ∧ (row.account_key_index < resolved.count) ∧ (row.layer_index ≥ 0) ∧ (row.layer_index < cube.layer_count)
}

# Keep only positive semantic contribution sides for period key/count evidence.
# This excludes transfer sides, expense credits/refunds, income debits, and
# non-positive reversed sides. Numeric TBDS construction uses the full checked
# ledger-wide posting set instead.
SemanticActualRows ← {𝕊 ctx:
  resolved ← ctx.resolved
  IsSemantic ← {𝕊 row:
    valid ← LedgerRowValid ⟨resolved, row⟩
    semantic ← 0
    {𝕊:
      role ← AccountRole ⟨resolved, row⟩
      income ← (role ≡ "income") ∧ (row.side ≡ "credit") ∧ (row.delta < 0)
      expense ← (role ≡ "expense") ∧ (row.side ≡ "debit") ∧ (row.delta > 0)
      semantic ↩ income ∨ expense
    }⍟valid @
    (row.source_file ≡ "journal.tsv") ∧ (row.layer_index = cube.layer_actual) ∧ semantic
  }
  (IsSemantic¨ctx.posting_rows) / ctx.posting_rows
}

LaneForRow ← {𝕊 resolved‿row:
  role ← AccountRole ⟨resolved, row⟩
  IsExpenseLane ← {𝕊: ((AccountSpendClass ⟨resolved,row⟩) ≡ "fixed") ⊑ "variable"‿"recurring_fixed"}
  (role ≡ "income") ◶ ⟨IsExpenseLane,{𝕊:"income"}⟩ @
}

KeyForRow ← {𝕊 resolved‿row:
  ⟨LaneForRow ⟨resolved, row⟩, "account", AccountName ⟨resolved, row⟩⟩
}

InPeriod ← {𝕊 startDn‿endDn‿row:
  dn ← proj.DaysFromEpoch row.date
  (startDn ≤ dn) ∧ (dn < endDn)
}

# Resolve the previous comparable anchor from admitted income-credit source
# identity. Plan anchors retain the existing future-after-journal-frontier rule.
ResolvePreviousAnchor ← {𝕊 ctx‿currentStart:
  rows ← ctx.posting_rows
  resolved ← ctx.resolved
  incomeAccount ← IncomeAnchorAccount ctx.base

  ValidIncomeCredit ← {𝕊 row:
    valid ← LedgerRowValid ⟨resolved, row⟩
    matches ← 0
    {𝕊:
      matches ↩ (row.side ≡ "credit") ∧ ((AccountName ⟨resolved, row⟩) ≡ incomeAccount)
    }⍟valid @
    matches
  }

  journalRows ← (({𝕩.source_file ≡ "journal.tsv"}¨rows) ∧ (ValidIncomeCredit¨rows)) / rows
  journalDates0 ← {𝕩.date}¨journalRows
  journalUnique ← ((journalDates0 ⊐ journalDates0) = ↕≠journalDates0) / journalDates0

  validJournalRows ← (({(𝕩.source_file ≡ "journal.tsv") ∧ LedgerRowValid ⟨resolved,𝕩⟩}¨rows)) / rows
  journalAllDates ← {𝕩.date}¨validJournalRows
  journalMaxDn ← ¯1000000000
  {𝕊: journalMaxDn ↩ ⌈´ proj.DaysFromEpoch¨journalAllDates}⍟(0<≠journalAllDates) @

  planRows0 ← (({𝕩.source_file ≡ "plan.tsv"}¨rows) ∧ (ValidIncomeCredit¨rows)) / rows
  planRows ← ({(proj.DaysFromEpoch 𝕩.date) > journalMaxDn}¨planRows0) / planRows0
  planDates0 ← {𝕩.date}¨planRows
  planUnique ← ((planDates0 ⊐ planDates0) = ↕≠planDates0) / planDates0

  allDates0 ← journalUnique ∾ planUnique
  allDns0 ← proj.DaysFromEpoch¨allDates0
  uniqMask ← (allDns0 ⊐ allDns0) = ↕≠allDns0
  allDates ← uniqMask / allDates0
  allDns ← uniqMask / allDns0
  sortedDns ← ∧ allDns
  sortedDates ← {𝕊 dn: (⊑ allDns ⊐ ⟨dn⟩) ⊑ allDates}¨sortedDns

  result ← { state ⇐ "unavailable", start ⇐ "unavailable", start_dn ⇐ 0 }
  {𝕊:
    currentDn ← proj.DaysFromEpoch currentStart
    currentIdx ← ⊑ (sortedDns ≥ currentDn) ⊐ ⟨1⟩
    previousIdx ← currentIdx - 1
    available ← (previousIdx ≥ 0) ∧ (currentIdx < ≠sortedDns)
    {𝕊: result ↩ {state⇐"ok", start⇐previousIdx⊑sortedDates, start_dn⇐previousIdx⊑sortedDns}}⍟available @
  }⍟((0<≠incomeAccount) ∧ (0<≠sortedDns)) @
  result
}

MakePeriodCycle ← {𝕊 start‿endExclusive:
  { mode ⇐ "actual_comparison_local", start ⇐ start, end_exclusive ⇐ endExclusive,
    day_count ⇐ (proj.DaysFromEpoch endExclusive) - proj.DaysFromEpoch start }
}

BuildPeriodTbds ← {𝕊 ctx‿start‿endExclusive:
  cy ← MakePeriodCycle ⟨start,endExclusive⟩
  # tbds.Build receives the full checked ledger-wide posting set and owns
  # valid/status/period filtering. Its result argument is retained because the
  # existing API accepts it; TBDS does not derive these values from the
  # cycle-bounded canonical Cube.
  tbds.Build ⟨ctx.posting_rows, ctx.cube, ctx.resolved, cy⟩
}

PeriodEvidence ← {𝕊 resolved‿semanticRows‿startDn‿endDn:
  periodRows ← ({InPeriod ⟨startDn,endDn,𝕩⟩}¨semanticRows) / semanticRows
  Make ← {𝕊 row:
    key ← KeyForRow ⟨resolved,row⟩
    identity ← row.source_file ∾ ":" ∾ (•Fmt row.source_row) ∾ ":" ∾ (⊑key) ∾ ":" ∾ (2⊑key)
    {key⇐key, identity⇐identity}
  }
  evidence0 ← Make¨periodRows
  identities ← {𝕩.identity}¨evidence0
  ((identities ⊐ identities)=↕≠identities) / evidence0
}

CountFor ← {𝕊 key‿evidence: +´ 0 ∾ (key⊸≡¨ {𝕩.key}¨evidence) }

AmountFor ← {𝕊 key‿periodTbds:
  lane ← ⊑key
  account ← 2⊑key
  matches ← ({(𝕩.layer_index=cube.layer_actual) ∧ (𝕩.account_name≡account)}¨periodTbds) / periodTbds
  amount ← 0
  {𝕊:
    row ← ⊑matches
    amount ↩ (lane ≡ "income") ⊑ ⟨row.debit_movement,-row.credit_movement⟩
  }⍟(0<≠matches) @
  amount
}

RejectedDiagnostics ← {𝕊 ctx‿currentStartDn‿currentEndDn‿baselineAvailable‿baselineStartDn‿baselineEndDn:
  rejected ← ({(𝕩.source_file≡"journal.tsv") ∧ (𝕩.status≢"ok")}¨ctx.posting_rows) / ctx.posting_rows
  Applies ← {𝕊 row:
    validDate ← proj.IsValidDateText row.date
    applies ← ¬validDate
    {𝕊:
      dn ← proj.DaysFromEpoch row.date
      inCurrent ← (currentStartDn≤dn) ∧ (dn<currentEndDn)
      inBaseline ← baselineAvailable ∧ (baselineStartDn≤dn) ∧ (dn<baselineEndDn)
      applies ↩ inCurrent ∨ inBaseline
    }⍟validDate @
    applies
  }
  applicable ← (Applies¨rejected) / rejected
  ids ← {𝕩.source_file∾":"∾(•Fmt 𝕩.source_row)}¨applicable
  unique ← ((ids⊐ids)=↕≠ids) / applicable
  {𝕊 row:
    {source_file⇐row.source_file, source_row⇐row.source_row, status⇐row.status,
     date⇐row.date, message⇐row.message}
  }¨unique
}

EmptyVm ← {𝕊 observation:
  { period_kind ⇐ "current_cycle_elapsed", observation_status ⇐ "error",
    reason ⇐ "invalid_observation", diagnostics ⇐ ⟨⟩, table ⇐ ⟨⟩, as_of ⇐ observation,
    current_start ⇐ "unavailable", current_end_exclusive ⇐ "unavailable",
    baseline_start ⇐ "unavailable", baseline_end_exclusive ⇐ "unavailable", elapsed_days ⇐ 0 }
}

BuildAt ← {𝕊 ctx‿observation:
  vm ← EmptyVm observation
  validO ← dt.IsValidDateText observation
  {𝕊:
    cy ← ctx.cy
    cycleDatesValid ← (dt.IsValidDateText cy.start) ∧ (dt.IsValidDateText cy.end_exclusive)
    cycleValid ← 0
    {𝕊:
      startDn ← proj.DaysFromEpoch cy.start
      cycleEndDn ← proj.DaysFromEpoch cy.end_exclusive
      cycleValid ↩ (startDn < cycleEndDn) ∧ (cy.day_count = cycleEndDn-startDn)
    }⍟cycleDatesValid @

    vm ↩ {period_kind⇐"current_cycle_elapsed", observation_status⇐"error",
      reason⇐"invalid_or_unresolvable_cycle", diagnostics⇐⟨⟩, table⇐⟨⟩, as_of⇐observation,
      current_start⇐cy.start, current_end_exclusive⇐"unavailable",
      baseline_start⇐"unavailable", baseline_end_exclusive⇐"unavailable", elapsed_days⇐0}

    {𝕊:
      startDn ← proj.DaysFromEpoch cy.start
      cycleEndDn ← proj.DaysFromEpoch cy.end_exclusive
      oEndDn ← 1 + proj.DaysFromEpoch observation
      currentEndDn ← oEndDn ⌊ cycleEndDn
      currentEndDn ↩ startDn ⌈ currentEndDn
      currentEnd ← dt.FromDaysFromEpoch currentEndDn
      elapsed ← currentEndDn-startDn

      vm ↩ {period_kind⇐"current_cycle_elapsed", observation_status⇐"unavailable",
        reason⇐"empty_current_window", diagnostics⇐⟨⟩, table⇐⟨⟩, as_of⇐observation,
        current_start⇐cy.start, current_end_exclusive⇐currentEnd,
        baseline_start⇐"unavailable", baseline_end_exclusive⇐"unavailable", elapsed_days⇐elapsed}

      {𝕊:
        anchor ← ResolvePreviousAnchor ⟨ctx,cy.start⟩
        anchorAvailable ← anchor.state ≡ "ok"
        baselineEndDn ← anchor.start_dn + elapsed
        baselineEnd ← anchorAvailable ⊑ "unavailable"‿(dt.FromDaysFromEpoch baselineEndDn)
        diagnostics ← RejectedDiagnostics ⟨ctx,startDn,currentEndDn,anchorAvailable,anchor.start_dn,baselineEndDn⟩

        status ← "unavailable"
        reason ← "previous_comparable_anchor_unavailable"
        {𝕊: status ↩ "error" ⋄ reason ↩ "rejected_actual_evidence"}⍟(0<≠diagnostics) @
        {𝕊: status ↩ "ok" ⋄ reason ↩ "comparison_active"}⍟((0=≠diagnostics) ∧ anchorAvailable) @

        table ← ⟨⟩
        {𝕊:
          semanticRows ← SemanticActualRows ctx
          currentTbds ← BuildPeriodTbds ⟨ctx,cy.start,currentEnd⟩
          baselineTbds ← BuildPeriodTbds ⟨ctx,anchor.start,baselineEnd⟩
          currentEvidence ← PeriodEvidence ⟨ctx.resolved,semanticRows,startDn,currentEndDn⟩
          baselineEvidence ← PeriodEvidence ⟨ctx.resolved,semanticRows,anchor.start_dn,baselineEndDn⟩
          keys0 ← ({𝕩.key}¨currentEvidence) ∾ ({𝕩.key}¨baselineEvidence)
          keys ← ((keys0⊐keys0)=↕≠keys0) / keys0

          MakeRow ← {𝕊 key:
            lane ← ⊑key ⋄ unitKind ← 1⊑key ⋄ unit ← CleanName 2⊑key
            curAmt ← AmountFor ⟨key,currentTbds⟩
            baseAmt ← AmountFor ⟨key,baselineTbds⟩
            curCnt ← CountFor ⟨key,currentEvidence⟩
            baseCnt ← CountFor ⟨key,baselineEvidence⟩
            diffAmt ← curAmt-baseAmt ⋄ diffCnt ← curCnt-baseCnt
            ratio ← (baseAmt=0) ◶ ⟨{𝕊:(•Fmt ⌊(100×curAmt)÷baseAmt)∾"%"},{𝕊:"n/a"}⟩ @
            rowStatus ← "no_activity"
            {𝕊:
              rowStatus ↩ (baseAmt=0) ◶ ⟨
                {𝕊:(curAmt=0) ◶ ⟨{𝕊:(curAmt>baseAmt) ⊑ ⟨(curAmt<baseAmt) ⊑ "same"‿"decreased","increased"⟩},{𝕊:"stopped"}⟩ @},
                {𝕊:"new"}
              ⟩ @
            }⍟(¬((baseAmt=0) ∧ (curAmt=0))) @
            ⟨"current_cycle_elapsed",lane,unitKind,unit,cy.start,currentEnd,anchor.start,baselineEnd,
              curAmt,baseAmt,diffAmt,curCnt,baseCnt,diffCnt,ratio,rowStatus,"ok"⟩
          }
          table ↩ MakeRow¨keys
        }⍟(status≡"ok") @

        vm ↩ {period_kind⇐"current_cycle_elapsed", observation_status⇐status,
          reason⇐reason, diagnostics⇐diagnostics, table⇐table, as_of⇐observation,
          current_start⇐cy.start, current_end_exclusive⇐currentEnd,
          baseline_start⇐anchor.start, baseline_end_exclusive⇐baselineEnd, elapsed_days⇐elapsed}
      }⍟(elapsed>0) @
    }⍟cycleValid @
  }⍟validO @
  vm
}

Format ← {𝕊 vm:
  out ← "--- SrcNext Actual Comparison ---" ∾ (@+10)
  out ↩ out ∾ "src_next_actual_comparison_status: " ∾ vm.observation_status ∾ (@+10)
  out ↩ out ∾ "src_next_actual_comparison_reason: " ∾ vm.reason ∾ (@+10)
  {𝕊 d:
    line ← "src_next_actual_comparison_diagnostic: " ∾ d.source_file ∾ " row=" ∾ (•Fmt d.source_row) ∾ " status=" ∾ d.status ∾ " date=" ∾ d.date ∾ " message=" ∾ d.message
    out ↩ out ∾ line ∾ (@+10)
  }¨vm.diagnostics
  {𝕊 r:
    line ← "src_next_actual_comparison_row: " ∾ (3⊑r) ∾ " lane=" ∾ (1⊑r) ∾ " cur=" ∾ (•Fmt 8⊑r) ∾ " base=" ∾ (•Fmt 9⊑r) ∾ " diff=" ∾ (•Fmt 10⊑r) ∾ " ratio=" ∾ (14⊑r) ∾ " status=" ∾ (15⊑r)
    out ↩ out ∾ line ∾ (@+10)
  }¨vm.table
  out
}

FormatHuman ← {𝕊 vm:
  out ← (L "actual.section_title") ∾ (@+10) ∾ (@+10)
  currentLine ← (L "actual.current_label") ∾ (fmt.RangeDisp ⟨vm.current_start,vm.current_end_exclusive⟩) ∾ (L "actual.current_open") ∾ (•Fmt vm.elapsed_days) ∾ (L "actual.current_days_suffix")
  baselineLine ← (L "actual.baseline_label") ∾ (fmt.RangeDisp ⟨vm.baseline_start,vm.baseline_end_exclusive⟩) ∾ (L "actual.baseline_suffix")
  out ↩ out ∾ currentLine ∾ (@+10) ∾ baselineLine ∾ (@+10) ∾ (@+10)

  (vm.observation_status ≡ "ok") ◶ ⟨
    {𝕊:
      (vm.observation_status ≡ "error") ◶ ⟨
        {𝕊: out ↩ out ∾ (L "actual.no_history") ∾ " " ∾ vm.observation_status ∾ ")" ∾ (@+10) ∾ (@+10)},
        {𝕊:
          out ↩ out ∾ (L "actual.error") ∾ " (reason: " ∾ vm.reason ∾ ")" ∾ (@+10)
          {𝕊 d: out ↩ out ∾ "- "∾d.source_file∾" row "∾(•Fmt d.source_row)∾": "∾d.status∾(@+10)}¨vm.diagnostics
          out ↩ out ∾ (@+10)
        }
      ⟩ @
    },
    {𝕊:
      table ← vm.table
      (0 < ≠table) ◶ ⟨
        {𝕊: out ↩ out ∾ (L "actual.no_rows") ∾ (@+10) ∾ (@+10)},
        {𝕊:
          LaneOrder ← {𝕩≡"income" ? 0 ; 𝕩≡"recurring_fixed" ? 1 ; 2}
          keys ← {⟨LaneOrder 1⊑𝕩, ¯1×|10⊑𝕩⟩}¨table
          table ↩ (⍋keys)⊏table
          LaneLabel ← {𝕩≡"income" ? L "actual.lane_income" ; 𝕩≡"recurring_fixed" ? L "actual.lane_fixed" ; L "actual.lane_variable"}
          units ← {(3⊑𝕩)∾LaneLabel 1⊑𝕩}¨table
          wUnit ← ⌈´(fmt.VWidth¨units)∾⟨4⟩ ⋄ wAmt ← 10 ⋄ wRatio ← 7 ⋄ wStatus ← 10
          AlignR ← {𝕊 w‿x: s←(1=•Type x)⊑⟨x,•Fmt x⟩ ⋄ ((0⌈w-≠s)⥊" ")∾s}
          header ← (fmt.PadV ⟨wUnit,L "actual.table_unit"⟩)∾" | "∾(AlignR ⟨wAmt,L "actual.table_current"⟩)∾" | "∾(AlignR ⟨wAmt,L "actual.table_baseline"⟩)∾" | "∾(AlignR ⟨wAmt,L "actual.table_diff"⟩)∾" | "∾(AlignR ⟨wRatio,L "actual.table_ratio"⟩)∾" | "∾(fmt.PadV ⟨wStatus,L "actual.table_status"⟩)
          out ↩ out ∾ header ∾ (@+10)
          FormatRow ← {𝕊 r:
            unit←(3⊑r)∾LaneLabel 1⊑r
            (fmt.PadV ⟨wUnit,unit⟩)∾" | "∾(AlignR ⟨wAmt,8⊑r⟩)∾" | "∾(AlignR ⟨wAmt,9⊑r⟩)∾" | "∾(AlignR ⟨wAmt,10⊑r⟩)∾" | "∾(AlignR ⟨wRatio,14⊑r⟩)∾" | "∾(fmt.PadV ⟨wStatus,15⊑r⟩)
          }
          out ↩ out ∾ ∾ (FormatRow ¨ table) ∾¨ (@+10)
          out ↩ out ∾ (@+10)
        }
      ⟩ @
    }
  ⟩ @
  out
}

{ BuildAt ⇐ BuildAt, Format ⇐ Format, FormatHuman ⇐ FormatHuman }
