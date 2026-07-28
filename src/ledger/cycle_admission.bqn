# Pure strict cycle.tsv definition admission.
# Resolution against Actual/Plan facts and an as-of coordinate is a later capability.

 dates ← •Import "date_ordinal.bqn"
empty ← ⟨⟩
tab ← @+9
knownKeys ← ⟨"mode","start","end_exclusive","income_account","start_day","offset"⟩

SplitKeepEmpty ← {𝕊 sep‿text:
  groups ← (+`sep=text)⊔text
  {(sep≠𝕩)/𝕩}¨groups
}
Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}
Unique ← {𝕊 items:
  result ← empty
  {𝕊 item: {𝕊: result∾↩⟨item⟩}⍟(¬Contains ⟨item,result⟩) @}¨items
  result
}
IndexOf ← {𝕊 item‿items: ⊑(item⊸≡¨items)⊐1}
Ignored ← {𝕊 line: (0=≠line) ∨ ((0<≠line) ∧ ((⊑line)∊"#\\")) }
IsDigits ← {𝕊 text: (0<≠text) ∧ ∧´text∊"0123456789"}
IsInteger ← {𝕊 text:
  result ← 0
  {𝕊:
    negative ← (⊑text)='-'
    digits ← negative⊑⟨text,1↓text⟩
    result↩IsDigits digits
  }⍟(0<≠text) @
  result
}
Diagnostic ← {𝕊 codeText‿row‿messageText:
  {severity⇐"error",stage⇐"ledger_cycle_admission",code⇐codeText,source_row⇐row,message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}
ValueOr ← {𝕊 key‿rows‿fallback:
  matches ← ({𝕩.key≡key}¨rows)/rows
  result ← fallback
  {𝕊: result↩(⊑matches).value}⍟(1=≠matches) @
  result
}
Present ← {𝕊 key‿keys: Contains ⟨key,keys⟩}

Admit ← {𝕊 lines‿accounts:
  diagnostics ← empty
  rows ← empty
  {𝕊 i:
    line ← i⊑lines
    {𝕊:
      row ← i+1
      fields ← SplitKeepEmpty ⟨tab,line⟩
      rowDiagnostics ← empty
      rowDiagnostics ∾↩ AddIf ⟨2≠≠fields,Diagnostic ⟨"cycle_row_shape_invalid",row,"cycle row requires exactly key and value"⟩⟩
      {𝕊:
        key ← 0⊑fields ⋄ value ← 1⊑fields
        rowDiagnostics ∾↩ AddIf ⟨0=≠key,Diagnostic ⟨"cycle_key_empty",row,"cycle key must be nonempty"⟩⟩
        rowDiagnostics ∾↩ AddIf ⟨0=≠value,Diagnostic ⟨"cycle_value_empty",row,"cycle value must be nonempty"⟩⟩
        rowDiagnostics ∾↩ AddIf ⟨¬Contains ⟨key,knownKeys⟩,Diagnostic ⟨"cycle_key_unsupported",row,"cycle key is not admitted"⟩⟩
        diagnostics ∾↩ rowDiagnostics
        {𝕊: rows∾↩⟨{key⇐key,value⇐value,source_row⇐row}⟩}⍟(0=≠rowDiagnostics) @
      }⍟(2=≠fields) @
    }⍟(¬Ignored line) @
  }¨↕≠lines

  keys ← {𝕩.key}¨rows
  diagnostics ∾↩ AddIf ⟨(≠keys)≠≠Unique keys,Diagnostic ⟨"cycle_key_duplicate",0,"cycle keys must be unique"⟩⟩
  mode ← ValueOr ⟨"mode",rows,""⟩
  start ← ValueOr ⟨"start",rows,""⟩
  endExclusive ← ValueOr ⟨"end_exclusive",rows,""⟩
  incomeAccount ← ValueOr ⟨"income_account",rows,""⟩
  startDayText ← ValueOr ⟨"start_day",rows,""⟩
  offsetText ← ValueOr ⟨"offset",rows,""⟩
  modeKnown ← Contains ⟨mode,⟨"fixed","incomeAnchor","calendarMonth"⟩⟩
  diagnostics ∾↩ AddIf ⟨¬modeKnown,Diagnostic ⟨"cycle_mode_invalid",0,"cycle mode must be fixed, incomeAnchor, or calendarMonth"⟩⟩

  isFixed ← mode≡"fixed"
  isIncome ← mode≡"incomeAnchor"
  isCalendar ← mode≡"calendarMonth"
  {𝕊:
    diagnostics ∾↩ AddIf ⟨(0=≠start) ∨ 0=≠endExclusive,Diagnostic ⟨"fixed_cycle_boundary_missing",0,"fixed cycle requires start and end_exclusive"⟩⟩
    startValid ← dates.IsValid start
    endValid ← dates.IsValid endExclusive
    diagnostics ∾↩ AddIf ⟨(0<≠start) ∧ ¬startValid,Diagnostic ⟨"fixed_cycle_start_invalid",0,"fixed cycle start must be strict Gregorian text"⟩⟩
    diagnostics ∾↩ AddIf ⟨(0<≠endExclusive) ∧ ¬endValid,Diagnostic ⟨"fixed_cycle_end_invalid",0,"fixed cycle end_exclusive must be strict Gregorian text"⟩⟩
    {𝕊: diagnostics∾↩AddIf ⟨(dates.Ordinal start)≥dates.Ordinal endExclusive,Diagnostic ⟨"fixed_cycle_range_invalid",0,"fixed cycle requires start before end_exclusive"⟩⟩}⍟(startValid ∧ endValid) @
    extraField ← (Present ⟨"start_day",keys⟩) ∨ Present ⟨"offset",keys⟩
    diagnostics ∾↩ AddIf ⟨extraField,Diagnostic ⟨"fixed_cycle_field_invalid",0,"fixed cycle does not accept start_day or offset"⟩⟩
  }⍟isFixed @

  {𝕊:
    diagnostics ∾↩ AddIf ⟨0=≠incomeAccount,Diagnostic ⟨"income_anchor_account_missing",0,"incomeAnchor requires income_account"⟩⟩
    extraField ← (Present ⟨"start",keys⟩) ∨ (Present ⟨"end_exclusive",keys⟩) ∨ Present ⟨"start_day",keys⟩
    diagnostics ∾↩ AddIf ⟨extraField,Diagnostic ⟨"income_anchor_field_invalid",0,"incomeAnchor does not accept fixed/calendar boundaries"⟩⟩
    offsetValid ← 0=≠offsetText
    {𝕊: offsetValid↩0=•BQN offsetText}⍟(IsInteger offsetText) @
    diagnostics ∾↩ AddIf ⟨¬offsetValid,Diagnostic ⟨"income_anchor_offset_unsupported",0,"strict incomeAnchor currently admits only offset 0"⟩⟩
  }⍟isIncome @

  startDay ← 0
  {𝕊:
    validDigits ← IsDigits startDayText
    {𝕊: startDay↩•BQN startDayText}⍟validDigits @
    invalidDay ← (¬validDigits) ∨ (startDay<1) ∨ (startDay>28)
    diagnostics ∾↩ AddIf ⟨invalidDay,Diagnostic ⟨"calendar_start_day_invalid",0,"calendarMonth start_day must be an integer from 1 through 28"⟩⟩
    extraField ← (Present ⟨"start",keys⟩) ∨ (Present ⟨"end_exclusive",keys⟩) ∨ (Present ⟨"income_account",keys⟩) ∨ Present ⟨"offset",keys⟩
    diagnostics ∾↩ AddIf ⟨extraField,Diagnostic ⟨"calendar_cycle_field_invalid",0,"calendarMonth accepts only mode and start_day"⟩⟩
  }⍟isCalendar @

  {𝕊:
    accountKnown ← Contains ⟨incomeAccount,accounts.key⟩
    diagnostics ∾↩ AddIf ⟨¬accountKnown,Diagnostic ⟨"cycle_income_account_unknown",0,"income_account must occur in admitted Account facts"⟩⟩
    {𝕊:
      role ← (IndexOf ⟨incomeAccount,accounts.key⟩)⊑accounts.role
      diagnostics ∾↩ AddIf ⟨role≢"income",Diagnostic ⟨"cycle_income_account_role_invalid",0,"income_account must have explicit income role"⟩⟩
    }⍟accountKnown @
  }⍟(0<≠incomeAccount) @

  offset ← 0
  {𝕊: offset↩•BQN offsetText}⍟(IsInteger offsetText) @
  hasError ← 0<≠diagnostics
  admittedRows ← hasError⊑rows‿empty
  {
    state⇐hasError⊑"ok"‿"error",
    table⇐{
      count⇐≠admittedRows,index⇐↕≠admittedRows,
      key⇐{𝕩.key}¨admittedRows,value⇐{𝕩.value}¨admittedRows,source_row⇐{𝕩.source_row}¨admittedRows
    },
    definition⇐{
      mode⇐hasError⊑mode‿"",start⇐hasError⊑start‿"",end_exclusive⇐hasError⊑endExclusive‿"",
      income_account⇐hasError⊑incomeAccount‿"",start_day⇐hasError⊑startDay‿0,offset⇐hasError⊑offset‿0
    },
    diagnostics⇐diagnostics
  }
}

{Admit⇐Admit}
