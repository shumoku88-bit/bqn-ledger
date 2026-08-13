# Semantic month calendar, selected-date detail, and pure Home presentation.
#
# Build composes already-admitted/derived meaning and does not read source files.
# BuildDetail selects one day from the calendar relation and projects typed
# transaction rows plus already-derived Plan / Issue / Cycle meaning.
# Presentation consumes admitted or already-derived values without owning
# Plan/Issue/Cycle lifecycle semantics or canonical source authority.

reference ← •Import "../ledger/fact_reference.bqn"
dates ← •Import "../ledger/date_ordinal.bqn"
amount ← •Import "../ledger/amount_text.bqn"

empty ← ⟨⟩
lf ← @+10

Diagnostic ← {𝕊 codeText‿messageText:
  {severity⇐"error",stage⇐"section_home_calendar",code⇐codeText,message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}

EmptyDays ← {𝕊:
  {
    count⇐0,index⇐empty,day⇐empty,date⇐empty,ordinal⇐empty,
    actual_indices⇐empty,plan_indices⇐empty,issue_indices⇐empty,
    actual_present⇐empty,plan_due⇐empty,issue_due⇐empty,cycle_end⇐empty,marker_count⇐empty
  }
}
EmptyResult ← {𝕊 diagnosticsValue:
  {
    state⇐"error",focus_date⇐"",month_start⇐"",month_end_exclusive⇐"",weekday_start⇐0,
    day_index_grid⇐0‿7⥊empty,days⇐EmptyDays @,diagnostics⇐diagnosticsValue
  }
}
EmptyDetail ← {𝕊 diagnosticsValue:
  {
    state⇐"error",date⇐"",actual⇐{count⇐0,rows⇐empty},plans⇐{count⇐0,rows⇐empty},
    issues⇐{count⇐0,rows⇐empty},cycle⇐{start⇐"",end_exclusive⇐"",contains⇐0,end_day⇐0},
    diagnostics⇐diagnosticsValue
  }
}

IndicesByOrdinal ← {𝕊 ordinal‿values‿indices: (ordinal=values)/indices}
IndicesByText ← {𝕊 value‿values‿indices: (value⊸≡¨values)/indices}

# Inputs are canonical Actual Facts plus already-derived open Plan and open Issue
# results, one resolved Cycle, and one strict Gregorian focus date.
Build ← {𝕊 actualFacts‿planned‿issues‿cycle‿focusDate:
  diagnostics ← empty
  actualOk ← reference.SourceIs ⟨actualFacts,"actual.journal"⟩
  diagnostics ∾↩ AddIf ⟨¬actualOk,Diagnostic ⟨"actual_facts_invalid","Home calendar requires admitted Actual facts"⟩⟩
  diagnostics ∾↩ AddIf ⟨planned.state≢"ok",Diagnostic ⟨"planned_payments_invalid","Home calendar requires an ok Planned Payments result"⟩⟩
  diagnostics ∾↩ AddIf ⟨issues.state≢"ok",Diagnostic ⟨"issues_invalid","Home calendar requires an ok open Issues result"⟩⟩
  diagnostics ∾↩ AddIf ⟨cycle.state≢"ok",Diagnostic ⟨"cycle_invalid","Home calendar requires a resolved cycle"⟩⟩
  focusValid ← dates.IsValid focusDate
  diagnostics ∾↩ AddIf ⟨¬focusValid,Diagnostic ⟨"focus_date_invalid","Home calendar focus date must be strict Gregorian text"⟩⟩

  result ← EmptyResult diagnostics
  {𝕊:
    year‿month‿focusDay ← dates.Parts focusDate
    monthStart ← dates.FromParts ⟨year,month,1⟩
    nextYear ← year+month=12
    nextMonth ← 1+12|month
    monthEndExclusive ← dates.FromParts ⟨nextYear,nextMonth,1⟩
    startOrdinal ← dates.Ordinal monthStart
    endOrdinal ← dates.Ordinal monthEndExclusive
    count ← endOrdinal-startOrdinal
    index ← ↕count
    dayOrdinals ← startOrdinal+index
    dayDates ← dates.FromOrdinal¨dayOrdinals

    # Ordinal's residue is anchored so Monday=0 ... Sunday=6 by adding two.
    weekdayStart ← 7|2+startOrdinal
    usedCells ← weekdayStart+count
    gridCount ← 7×⌈usedCells÷7
    trailing ← gridCount-usedCells
    dayIndexGrid ← (gridCount÷7)‿7⥊(weekdayStart⥊¯1)∾index∾trailing⥊¯1

    actualIndices ← {𝕊 ordinal:
      IndicesByOrdinal ⟨ordinal,actualFacts.transactions.date_ordinal,actualFacts.transactions.index⟩
    }¨dayOrdinals
    planIndices ← {𝕊 dateText:
      IndicesByText ⟨dateText,planned.rows.date,planned.rows.index⟩
    }¨dayDates
    issueIndices ← {𝕊 dateText:
      IndicesByText ⟨dateText,issues.issues.due,issues.issues.index⟩
    }¨dayDates

    actualPresent ← 0<≠¨actualIndices
    planDue ← 0<≠¨planIndices
    issueDue ← 0<≠¨issueIndices
    cycleEndDate ← dates.AddDays ⟨cycle.end_exclusive,¯1⟩
    cycleEnd ← cycleEndDate⊸≡¨dayDates
    markerCount ← planDue+issueDue+cycleEnd

    result↩{
      state⇐"ok",focus_date⇐focusDate,month_start⇐monthStart,month_end_exclusive⇐monthEndExclusive,
      weekday_start⇐weekdayStart,day_index_grid⇐dayIndexGrid,
      days⇐{
        count⇐count,index⇐index,day⇐1+index,date⇐dayDates,ordinal⇐dayOrdinals,
        actual_indices⇐actualIndices,plan_indices⇐planIndices,issue_indices⇐issueIndices,
        actual_present⇐actualPresent,plan_due⇐planDue,issue_due⇐issueDue,
        cycle_end⇐cycleEnd,marker_count⇐markerCount
      },diagnostics⇐empty
    }
  }⍟(0=≠diagnostics) @
  result
}

# The calendar already owns the date-to-index relation. Detail selection follows
# those indices rather than rescanning canonical source text or reclassifying due
# meaning in a second owner.
BuildDetail ← {𝕊 calendar‿transactionRows‿planned‿issues‿cycle‿selectedDate:
  diagnostics ← empty
  diagnostics ∾↩ AddIf ⟨calendar.state≢"ok",Diagnostic ⟨"detail_calendar_invalid","Home detail requires an ok Home calendar result"⟩⟩
  diagnostics ∾↩ AddIf ⟨transactionRows.state≢"ok",Diagnostic ⟨"detail_actual_rows_invalid","Home detail requires typed Actual transaction rows"⟩⟩
  diagnostics ∾↩ AddIf ⟨planned.state≢"ok",Diagnostic ⟨"detail_planned_invalid","Home detail requires an ok Planned Payments result"⟩⟩
  diagnostics ∾↩ AddIf ⟨issues.state≢"ok",Diagnostic ⟨"detail_issues_invalid","Home detail requires an ok Issues result"⟩⟩
  diagnostics ∾↩ AddIf ⟨cycle.state≢"ok",Diagnostic ⟨"detail_cycle_invalid","Home detail requires a resolved Cycle"⟩⟩
  selectedValid ← dates.IsValid selectedDate
  diagnostics ∾↩ AddIf ⟨¬selectedValid,Diagnostic ⟨"detail_date_invalid","Selected Home date must be strict Gregorian text"⟩⟩

  result ← EmptyDetail diagnostics
  {𝕊:
    matches ← selectedDate⊸≡¨calendar.days.date
    diagnostics ∾↩ AddIf ⟨1≠+´matches,Diagnostic ⟨"detail_date_outside_month","Selected Home date must occur in the displayed calendar month"⟩⟩
    {𝕊:
      dayIndex ← ⊑(matches⊐1)
      actualIndices ← dayIndex⊑calendar.days.actual_indices
      planIndices ← dayIndex⊑calendar.days.plan_indices
      issueIndices ← dayIndex⊑calendar.days.issue_indices

      actualRows ← actualIndices⊏transactionRows.rows
      planRows ← {𝕊 i:
        {
          index⇐i,plan_id⇐i⊑planned.rows.plan_id,status⇐i⊑planned.rows.status,
          category⇐i⊑planned.rows.category,memo⇐i⊑planned.rows.memo,currency⇐i⊑planned.rows.currency,
          coefficient⇐i⊑planned.rows.planned_coefficient,scale⇐i⊑planned.rows.planned_scale,
          from_account⇐i⊑planned.rows.from_account,to_account⇐i⊑planned.rows.to_account
        }
      }¨planIndices
      issueRows ← {𝕊 i:
        {
          index⇐i,issue_id⇐i⊑issues.issues.issue_id,category⇐i⊑issues.issues.category,
          title⇐i⊑issues.issues.title,details⇐i⊑issues.issues.details,
          amount_present⇐i⊑issues.issues.amount_present,coefficient⇐i⊑issues.issues.coefficient,
          scale⇐i⊑issues.issues.scale,currency⇐i⊑issues.issues.currency
        }
      }¨issueIndices

      selectedOrdinal ← dates.Ordinal selectedDate
      contains ← (selectedOrdinal≥cycle.start_ordinal) ∧ selectedOrdinal<cycle.end_exclusive_ordinal
      cycleStart ← cycle.start
      cycleEndExclusive ← cycle.end_exclusive
      endDay ← selectedDate≡dates.AddDays ⟨cycleEndExclusive,¯1⟩

      result↩{
        state⇐"ok",date⇐selectedDate,
        actual⇐{count⇐≠actualRows,rows⇐actualRows},
        plans⇐{count⇐≠planRows,rows⇐planRows},
        issues⇐{count⇐≠issueRows,rows⇐issueRows},
        cycle⇐{start⇐cycleStart,end_exclusive⇐cycleEndExclusive,contains⇐contains,end_day⇐endDay},
        diagnostics⇐empty
      }
    }⍟(0=≠diagnostics) @
  }⍟((0=≠diagnostics) ∧ selectedValid) @
  {𝕊:result↩EmptyDetail diagnostics}⍟(0<≠diagnostics) @
  result
}

# Encode the three independent calendar marker meanings as bits. Codes with two
# or three facts map to the explicit multiple marker, so no hidden priority is
# introduced by presentation. Parentheses keep the 1/2/4 weights explicit under
# BQN's right-to-left expression evaluation.
Markers ← {𝕊 result‿calendar:
  codes ← result.days.cycle_end + (2×result.days.plan_due) + (4×result.days.issue_due)
  table ← ⟨
    " ",calendar.cycle_end_marker,calendar.plan_due_marker,calendar.multiple_marker,
    calendar.issue_due_marker,calendar.multiple_marker,calendar.multiple_marker,calendar.multiple_marker
  ⟩
  codes⊏table
}

FormatHuman ← {𝕊 result‿calendar:
  markers ← Markers ⟨result,calendar⟩
  PadDay ← {𝕊 dayValue:
    value ← •Fmt dayValue
    ((0⌈2-≠value)⥊' ')∾value
  }
  cells ← {𝕊 i:(PadDay i⊑result.days.day)∾i⊑markers}¨result.days.index
  CellFor ← {𝕊 dayIndex:
    cell ← "   "
    {𝕊:cell↩dayIndex⊑cells}⍟(dayIndex≥0) @
    cell
  }
  rowTexts ← {𝕊 rowIndex:
    rowCells ← CellFor¨rowIndex⊏result.day_index_grid
    ¯1↓∾{𝕩∾" "}¨rowCells
  }¨↕≠result.day_index_grid
  ∾⟨
    7↑result.month_start,lf,
    "Mo  Tu  We  Th  Fr  Sa  Su ",lf,
    ∾{𝕩∾lf}¨rowTexts
  ⟩
}

FormatDetailHuman ← {𝕊 result:
  PostingLine ← {𝕊 domain‿posting:
    ∾⟨"    ",posting.side,"  ",posting.account_key,"  ",posting.amount_text," ",domain,lf⟩
  }
  ActualLine ← {𝕊 row:
    postingText ← ∾{𝕊 posting:PostingLine ⟨row.domain,posting⟩}¨row.postings
    ∾⟨"  [",•Fmt row.transaction_index,"] ",row.description,lf,postingText⟩
  }
  actualText ← "  (none)"∾lf
  {𝕊:actualText↩∾ActualLine¨result.actual.rows}⍟(0<result.actual.count) @

  PlanLine ← {𝕊 row:
    ∾⟨
      "  ",row.plan_id,"  ",row.category,"  ",row.memo,"  ",
      row.from_account," -> ",row.to_account,"  ",
      amount.Format ⟨row.coefficient,row.scale⟩," ",row.currency,lf
    ⟩
  }
  planText ← "  (none)"∾lf
  {𝕊:planText↩∾PlanLine¨result.plans.rows}⍟(0<result.plans.count) @

  IssueLine ← {𝕊 row:
    amountText ← ""
    {𝕊:amountText↩"  "∾(amount.Format ⟨row.coefficient,row.scale⟩)∾" "∾row.currency}⍟row.amount_present @
    detailText ← ""
    {𝕊:detailText↩lf∾"    "∾row.details}⍟(0<≠row.details) @
    ∾⟨"  ",row.issue_id,"  [",row.category,"] ",row.title,amountText,detailText,lf⟩
  }
  issueText ← "  (none)"∾lf
  {𝕊:issueText↩∾IssueLine¨result.issues.rows}⍟(0<result.issues.count) @

  cycleState ← "outside current resolved cycle"
  {𝕊:cycleState↩"inside current resolved cycle"}⍟result.cycle.contains @
  {𝕊:cycleState↩"cycle end day"}⍟result.cycle.end_day @

  ∾⟨
    result.date,lf,lf,
    "Actual",lf,actualText,lf,
    "Plans due",lf,planText,lf,
    "Issues due",lf,issueText,lf,
    "Cycle",lf,
    "  ",result.cycle.start," .. ",result.cycle.end_exclusive," (end exclusive)",lf,
    "  ",cycleState,lf
  ⟩
}

{Build⇐Build,BuildDetail⇐BuildDetail,Markers⇐Markers,FormatHuman⇐FormatHuman,FormatDetailHuman⇐FormatDetailHuman}
