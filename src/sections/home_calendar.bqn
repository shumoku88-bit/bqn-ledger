# Semantic month calendar plus pure fixed-width Home presentation.
#
# Build composes already-admitted/derived meaning and does not read source files.
# FormatHuman consumes admitted calendar presentation policy without owning
# Plan/Issue/Cycle lifecycle semantics or canonical source authority.

reference ← •Import "../ledger/fact_reference.bqn"
dates ← •Import "../ledger/date_ordinal.bqn"

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

# Encode the three independent calendar marker meanings as bits. Codes with two
# or three facts map to the explicit multiple marker, so no hidden priority is
# introduced by presentation.
Markers ← {𝕊 result‿calendar:
  codes ← result.days.cycle_end + 2×result.days.plan_due + 4×result.days.issue_due
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

{Build⇐Build,Markers⇐Markers,FormatHuman⇐FormatHuman}
