# Destination Date × active non-Budget Account Daily Flow Matrix.
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
      active ← {𝕊 column: ∨´0∾{0≠column⊑𝕩}¨accountMatrix.matrix.values}¨flow.accounts.index
      visible ← active ∧ ¬"budget"⊸≡¨flow.accounts.role
      visibleIndices ← visible/flow.accounts.index
      visibleRoles ← visible/flow.accounts.role
      visibleMatrix ← matrixResult.Build ⟨
        rowOrdinals,visible/flow.accounts.account_index,flow.scale,
        {visibleIndices⊏𝕩}¨accountMatrix.matrix.values,
        {visibleIndices⊏𝕩}¨accountMatrix.matrix.contributors
      ⟩
      diagnostics ∾↩ visibleMatrix.diagnostics
      {𝕊:
        result↩{
          state⇐"ok",domain⇐flow.domain,layer⇐flow.layer,
          period_start⇐periodStartText,period_end_exclusive⇐periodEndText,as_of⇐asOfText,
          date_text⇐rowTexts,column_labels⇐{𝕩∾"/"∾flow.domain}¨visible/flow.accounts.key,
          inverted_column_indices⇐(("income"⊸≡¨visibleRoles) ∨ "expense"⊸≡¨visibleRoles)/↕≠visibleRoles,
          matrix⇐visibleMatrix.matrix,diagnostics⇐empty
        }
      }⍟(visibleMatrix.state≡"ok") @
    }⍟(accountMatrix.state≡"ok") @
  }⍟(0=≠diagnostics) @
  {𝕊: result↩EmptyResult diagnostics}⍟(0<≠diagnostics) @
  result
}

FormatHuman ← {𝕊 input:
  result ← input ⋄ style ← "minus"
  {𝕊: result↩0⊑input ⋄ style↩(1⊑input).negative_style}⍟((0<≡input) ∧ (2=≠input)) @
  daysLeft ← (dates.Ordinal result.period_end_exclusive)-dates.Ordinal result.as_of
  rows ← {𝕊 dateIndex:
    values ← {𝕊 accountIndex:
      value ← accountIndex⊑dateIndex⊑result.matrix.values
      {𝕊:value↩-value}⍟(accountIndex∊result.inverted_column_indices) @
      text.FormatAmount ⟨value,result.matrix.scale,style⟩
    }¨result.matrix.column_index
    ⟨dateIndex⊑result.date_text⟩∾values
  }¨result.matrix.row_index
  headers ← ⟨"date"⟩∾result.column_labels
  out ← "== Daily Flow =="∾(@+10)∾(@+10)
  out ∾↩ "cycle: "∾result.period_start∾" 〜 "∾result.period_end_exclusive
  out ∾↩ " (as of "∾result.as_of∾"; "∾(•Fmt daysLeft)∾" days left)"∾(@+10)∾(@+10)
  out ∾↩ text.RenderTable ⟨headers,rows,1+↕result.matrix.column_count⟩
  out∾(@+10)
}

{Build⇐Build,FormatHuman⇐FormatHuman}
