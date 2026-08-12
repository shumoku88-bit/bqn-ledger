# Pure selected-date Home detail over already-derived calendar dependencies.
#
# This section does not read canonical source files. It selects one calendar day
# and projects typed Actual transaction rows plus already-derived Plan / Issue
# rows and resolved Cycle context for presentation.

amount ← •Import "../ledger/amount_text.bqn"
dates ← •Import "../ledger/date_ordinal.bqn"

empty ← ⟨⟩
lf ← @+10

Diagnostic ← {𝕊 codeText‿messageText:
  {severity⇐"error",stage⇐"section_home_day_detail",code⇐codeText,message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}
EmptyResult ← {𝕊 diagnosticsValue:
  {
    state⇐"error",date⇐"",actual⇐{count⇐0,rows⇐empty},plans⇐{count⇐0,rows⇐empty},
    issues⇐{count⇐0,rows⇐empty},cycle⇐{start⇐"",end_exclusive⇐"",contains⇐0,end_day⇐0},
    diagnostics⇐diagnosticsValue
  }
}

Build ← {𝕊 calendar‿transactionRows‿planned‿issues‿cycle‿selectedDate:
  diagnostics ← empty
  diagnostics ∾↩ AddIf ⟨calendar.state≢"ok",Diagnostic ⟨"calendar_invalid","Home day detail requires an ok Home calendar result"⟩⟩
  diagnostics ∾↩ AddIf ⟨transactionRows.state≢"ok",Diagnostic ⟨"actual_rows_invalid","Home day detail requires typed Actual transaction rows"⟩⟩
  diagnostics ∾↩ AddIf ⟨planned.state≢"ok",Diagnostic ⟨"planned_invalid","Home day detail requires an ok Planned Payments result"⟩⟩
  diagnostics ∾↩ AddIf ⟨issues.state≢"ok",Diagnostic ⟨"issues_invalid","Home day detail requires an ok Issues result"⟩⟩
  diagnostics ∾↩ AddIf ⟨cycle.state≢"ok",Diagnostic ⟨"cycle_invalid","Home day detail requires a resolved Cycle"⟩⟩
  dateValid ← dates.IsValid selectedDate
  diagnostics ∾↩ AddIf ⟨¬dateValid,Diagnostic ⟨"selected_date_invalid","Selected Home date must be strict Gregorian text"⟩⟩

  result ← EmptyResult diagnostics
  {𝕊:
    matches ← selectedDate⊸≡¨calendar.days.date
    diagnostics ∾↩ AddIf ⟨1≠+´matches,Diagnostic ⟨"selected_date_outside_month","Selected Home date must occur in the displayed calendar month"⟩⟩
    {𝕊:
      dayIndex ← matches⊐1
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
      endDate ← dates.AddDays ⟨cycle.end_exclusive,¯1⟩
      endDay ← selectedDate≡endDate

      result↩{
        state⇐"ok",date⇐selectedDate,
        actual⇐{count⇐≠actualRows,rows⇐actualRows},
        plans⇐{count⇐≠planRows,rows⇐planRows},
        issues⇐{count⇐≠issueRows,rows⇐issueRows},
        cycle⇐{start⇐cycle.start,end_exclusive⇐cycle.end_exclusive,contains⇐contains,end_day⇐endDay},
        diagnostics⇐empty
      }
    }⍟(0=≠diagnostics) @
  }⍟((0=≠diagnostics) ∧ dateValid) @
  {𝕊:result↩EmptyResult diagnostics}⍟(0<≠diagnostics) @
  result
}

FormatHuman ← {𝕊 result:
  PostingLine ← {𝕊 domain‿posting:
    ∾⟨"    ",posting.side,"  ",posting.account_key,"  ",posting.amount_text," ",domain,lf⟩
  }
  ActualLine ← {𝕊 row:
    postingText ← ∾{𝕊 p:PostingLine ⟨row.domain,p⟩}¨row.postings
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
    {𝕊:amountText↩"  "∾amount.Format ⟨row.coefficient,row.scale⟩∾" "∾row.currency}⍟row.amount_present @
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

{Build⇐Build,FormatHuman⇐FormatHuman}
