# Destination Daily Flow Matrix section proof.
# Accounting/category evidence is supplied; observation and rendering remain section-local.

pivot ← •Import "../accounting/sparse_pivot.bqn"
matrixResult ← •Import "../accounting/matrix_result.bqn"
dates ← •Import "../ledger/date_ordinal.bqn"
amount ← •Import "../ledger/amount_text.bqn"
text ← •Import "../report/text.bqn"
empty ← ⟨⟩

SortedUnique ← {𝕊 items: ⍷ ((⍋items)⊏items)}
Diagnostic ← {𝕊 codeText‿messageText:
  {severity⇐"error",stage⇐"section_daily_flow",code⇐codeText,message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}
EmptyMatrix ← {𝕊: (matrixResult.Build ⟨empty,empty,0,empty,empty⟩).matrix}
EmptyResult ← {𝕊 diagnosticsValue:
  {
    state⇐"error",domain⇐"",layer⇐"",period_start⇐"",period_end_exclusive⇐"",as_of⇐"",
    date_text⇐empty,column_labels⇐empty,expense_column_indices⇐empty,
    matrix⇐EmptyMatrix @,diagnostics⇐diagnosticsValue
  }
}

# Input: successful date/category flow, strict period text, explicit section observation.
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
    # Index-of's absent bound selects the appended text/zero/empty fallback cells.
    sourceRowCoordinates ← flow.dates.date_ordinal ⊐ rowOrdinals
    rowTexts ← sourceRowCoordinates ⊏ (flow.dates.date_text∾⟨asOfText⟩)
    remappedGroups ← {
      count⇐flow.expense_groups.count,index⇐flow.expense_groups.index,
      row_index⇐rowOrdinals ⊐ (flow.expense_groups.row_index⊏flow.dates.date_ordinal),
      column_index⇐flow.expense_groups.column_index,
      coefficient⇐flow.expense_groups.coefficient,
      contributors⇐flow.expense_groups.contributors
    }
    expenseMatrix ← pivot.Build ⟨rowOrdinals,flow.categories.index,flow.scale,remappedGroups⟩
    diagnostics ∾↩ expenseMatrix.diagnostics
    {𝕊:
      alignedIncome ← sourceRowCoordinates ⊏ (flow.dates.income∾⟨0⟩)
      alignedNet ← sourceRowCoordinates ⊏ (flow.dates.net∾⟨0⟩)
      alignedIncomeContributors ← sourceRowCoordinates ⊏ (flow.dates.income_contributors∾⟨empty⟩)
      values ← {𝕊 rowIndex:
        ⟨rowIndex⊑alignedIncome⟩∾(rowIndex⊑expenseMatrix.matrix.values)∾⟨rowIndex⊑alignedNet⟩
      }¨↕≠rowOrdinals
      contributors ← {𝕊 rowIndex:
        incomeContributors ← rowIndex⊑alignedIncomeContributors
        expenseContributors ← rowIndex⊑expenseMatrix.matrix.contributors
        netContributors ← SortedUnique incomeContributors∾∾expenseContributors
        ⟨incomeContributors⟩∾expenseContributors∾⟨netContributors⟩
      }¨↕≠rowOrdinals
      columnCoordinates ← ⟨"measure:income"⟩∾({"expense:"∾•Fmt 𝕩}¨flow.categories.index)∾⟨"measure:net"⟩
      builtMatrix ← matrixResult.Build ⟨rowOrdinals,columnCoordinates,flow.scale,values,contributors⟩
      diagnostics ∾↩ builtMatrix.diagnostics
      {𝕊:
        result↩{
          state⇐"ok",domain⇐flow.domain,layer⇐flow.layer,
          period_start⇐periodStartText,period_end_exclusive⇐periodEndText,as_of⇐asOfText,
          date_text⇐rowTexts,column_labels⇐⟨"income"⟩∾flow.categories.label∾⟨"net"⟩,
          expense_column_indices⇐1+flow.categories.index,
          matrix⇐builtMatrix.matrix,diagnostics⇐empty
        }
      }⍟(builtMatrix.state≡"ok") @
    }⍟(expenseMatrix.state≡"ok") @
  }⍟(0=≠diagnostics) @
  {𝕊: result↩EmptyResult diagnostics}⍟(0<≠diagnostics) @
  result
}

CellText ← {𝕊 coefficient‿scale: amount.Format ⟨coefficient,scale⟩}
FormatHuman ← {𝕊 result:
  daysLeft ← (dates.Ordinal result.period_end_exclusive)-dates.Ordinal result.as_of
  widths ← {10⌈text.VWidth 𝕩}¨result.column_labels
  HeaderCell ← {𝕊 column: text.PadLeft ⟨column⊑widths,column⊑result.column_labels⟩}
  header ← "date      "∾∾{" | "∾HeaderCell 𝕩}¨↕≠result.column_labels
  separator ← "----------"∾∾{"-+-"∾((𝕩⊑widths)⥊'-')}¨↕≠widths
  out ← "== Daily Flow =="∾(@+10)∾(@+10)
  out ∾↩ "cycle: "∾result.period_start∾" 〜 "∾result.period_end_exclusive
  out ∾↩ " (as of "∾result.as_of∾"; "∾(•Fmt daysLeft)∾" days left)"∾(@+10)∾(@+10)
  out ∾↩ header∾(@+10)∾separator∾(@+10)
  {𝕊 rowIndex:
    row ← rowIndex⊑result.matrix.values
    cells ← {𝕊 columnIndex:
      value ← columnIndex⊑row
      displayValue ← value
      {𝕊: displayValue↩-value}⍟(columnIndex∊result.expense_column_indices) @
      text.PadLeft ⟨columnIndex⊑widths,CellText ⟨displayValue,result.matrix.scale⟩⟩
    }¨result.matrix.column_index
    out ∾↩ (rowIndex⊑result.date_text)∾(∾{" | "∾𝕩}¨cells)∾(@+10)
  }¨result.matrix.row_index
  out∾(@+10)
}

{Build⇐Build,FormatHuman⇐FormatHuman}
