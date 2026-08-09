# Destination Date × Account Daily Flow Matrix.
# Accounting evidence is supplied; observation and rendering remain section-local.

pivot ← •Import "../accounting/sparse_pivot.bqn"
matrixResult ← •Import "../accounting/matrix_result.bqn"
dates ← •Import "../ledger/date_ordinal.bqn"
text ← •Import "../report/text.bqn"
empty ← ⟨⟩

IndexOf ← {𝕊 item‿items: ⊑(item⊸≡¨items)⊐1}
SortedUnique ← {𝕊 items: ⍷(⍋items)⊏items}
Diagnostic ← {𝕊 codeText‿messageText:
  {severity⇐"error",stage⇐"section_daily_flow",code⇐codeText,message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}
EmptyMatrix ← {𝕊: (matrixResult.Build ⟨empty,empty,0,empty,empty⟩).matrix}
EmptyResult ← {𝕊 diagnosticsValue:
  {
    state⇐"error",domain⇐"",layer⇐"",period_start⇐"",period_end_exclusive⇐"",as_of⇐"",
    date_text⇐empty,column_labels⇐empty,inverted_column_indices⇐empty,
    matrix⇐EmptyMatrix @,diagnostics⇐diagnosticsValue
  }
}

# Input: successful date/Account-category flow, strict period text, explicit section observation.
Build ← {𝕊 flow‿periodStartText‿periodEndText‿asOfText:
  diagnostics ← empty
  diagnostics ∾↩ AddIf ⟨flow.state≢"ok",Diagnostic ⟨"date_category_flow_not_ok","date/category accounting evidence must be ok"⟩⟩
  startValid ← dates.IsValid periodStartText
  endValid ← dates.IsValid periodEndText
  asOfValid ← dates.IsValid asOfText
  diagnostics ∾↩ AddIf ⟨¬startValid,Diagnostic ⟨"period_start_invalid","period start text must be strict Gregorian text"⟩⟩
  diagnostics ∾↩ AddIf ⟨¬endValid,Diagnostic ⟨"period_end_invalid","period end text must be strict Gregorian text"⟩⟩
  diagnostics ∾↩ AddIf ⟨¬asOfValid,Diagnostic ⟨"observation_invalid","as-of text must be strict Gregorian text"⟩⟩
  startOrdinal ← 0 ⋄ endOrdinal ← 0 ⋄ asOfOrdinal ← 0
  {𝕊:
    startOrdinal↩dates.Ordinal periodStartText
    endOrdinal↩dates.Ordinal periodEndText
    asOfOrdinal↩dates.Ordinal asOfText
    diagnostics ∾↩ AddIf ⟨startOrdinal≠flow.start_ordinal,Diagnostic ⟨"period_start_mismatch","period start text must match accounting coordinate"⟩⟩
    diagnostics ∾↩ AddIf ⟨endOrdinal≠flow.end_exclusive_ordinal,Diagnostic ⟨"period_end_mismatch","period end text must match accounting coordinate"⟩⟩
    diagnostics ∾↩ AddIf ⟨(asOfOrdinal<startOrdinal) ∨ asOfOrdinal≥endOrdinal,Diagnostic ⟨"observation_out_of_period","as-of must occur inside the half-open period"⟩⟩
    expectedAsOf ← startOrdinal
    {𝕊: expectedAsOf↩¯1⊑flow.dates.date_ordinal}⍟(0<flow.dates.count) @
    diagnostics ∾↩ AddIf ⟨asOfOrdinal≠expectedAsOf,Diagnostic ⟨"observation_evidence_mismatch","as-of must equal latest selected transaction date, or period start when empty"⟩⟩
  }⍟(startValid ∧ endValid ∧ asOfValid ∧ flow.state≡"ok") @

  result ← EmptyResult diagnostics
  {𝕊:
    rowOrdinals ← SortedUnique flow.dates.date_ordinal∾⟨asOfOrdinal⟩
    rowTexts ← {𝕊 ordinal:
      value ← asOfText
      matches ← (ordinal=flow.dates.date_ordinal)/↕flow.dates.count
      {𝕊: value↩(⊑matches)⊑flow.dates.date_text}⍟(1=≠matches) @
      value
    }¨rowOrdinals
    remappedGroups ← {
      count⇐flow.account_groups.count,index⇐flow.account_groups.index,
      row_index⇐{𝕊 oldIndex: IndexOf ⟨oldIndex⊑flow.dates.date_ordinal,rowOrdinals⟩}¨flow.account_groups.row_index,
      column_index⇐flow.account_groups.column_index,
      coefficient⇐flow.account_groups.coefficient,
      contributors⇐flow.account_groups.contributors
    }
    accountMatrix ← pivot.Build ⟨rowOrdinals,flow.accounts.account_index,flow.scale,remappedGroups⟩
    diagnostics ∾↩ accountMatrix.diagnostics
    {𝕊:
      result↩{
        state⇐"ok",domain⇐flow.domain,layer⇐flow.layer,
        period_start⇐periodStartText,period_end_exclusive⇐periodEndText,as_of⇐asOfText,
        date_text⇐rowTexts,column_labels⇐{𝕩∾"/"∾flow.domain}¨flow.accounts.key,
        inverted_column_indices⇐(("income"⊸≡¨flow.accounts.role) ∨ "expense"⊸≡¨flow.accounts.role)/flow.accounts.index,
        matrix⇐accountMatrix.matrix,diagnostics⇐empty
      }
    }⍟(accountMatrix.state≡"ok") @
  }⍟(0=≠diagnostics) @
  {𝕊: result↩EmptyResult diagnostics}⍟(0<≠diagnostics) @
  result
}

FormatHuman ← {𝕊 input:
  result ← input ⋄ style ← "minus" ⋄ configuredMax ← 0
  {𝕊:
    result↩0⊑input ⋄ presentation ← 1⊑input
    style↩presentation.negative_style ⋄ configuredMax↩presentation.daily_flow_max_date_columns
  }⍟((0<≡input) ∧ (2=≠input)) @
  maxDateColumns ← configuredMax⌈result.matrix.row_count×configuredMax=0
  daysLeft ← (dates.Ordinal result.period_end_exclusive)-dates.Ordinal result.as_of
  firstDate ← 0⌈result.matrix.row_count-maxDateColumns
  dateIndices ← firstDate↓result.matrix.row_index
  rows ← {𝕊 accountIndex:
    values ← {𝕊 dateIndex:
      value ← accountIndex⊑dateIndex⊑result.matrix.values
      {𝕊:value↩-value}⍟(accountIndex∊result.inverted_column_indices) @
      text.FormatAmount ⟨value,result.matrix.scale,style⟩
    }¨dateIndices
    ⟨accountIndex⊑result.column_labels⟩∾values
  }¨result.matrix.column_index
  headers ← ⟨"Account"⟩∾dateIndices⊏result.date_text
  out ← "== Daily Flow =="∾(@+10)∾(@+10)
  out ∾↩ "cycle: "∾result.period_start∾" 〜 "∾result.period_end_exclusive
  out ∾↩ " (as of "∾result.as_of∾"; "∾(•Fmt daysLeft)∾" days left)"∾(@+10)∾(@+10)
  out ∾↩ text.RenderTable ⟨headers,rows,1+↕≠dateIndices⟩
  out∾(@+10)
}

{Build⇐Build,FormatHuman⇐FormatHuman}
