# Destination Planned Payments List result and human/compact/JSON renderers.
# This section owns period selection, observation, temporal labels, totals, and presentation.

completion ← •Import "../accounting/plan_completion_join.bqn"
reference ← •Import "../accounting/fact_reference.bqn"
scale ← •Import "../ledger/exact_scale.bqn"
dates ← •Import "../ledger/date_ordinal.bqn"
amount ← •Import "../ledger/amount_text.bqn"
text ← •Import "../report/text.bqn"
empty ← ⟨⟩

Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}
Unique ← {𝕊 items:
  output ← empty
  {𝕊 item: {𝕊: output∾↩⟨item⟩}⍟(¬Contains ⟨item,output⟩) @}¨items
  output
}
IndexOf ← {𝕊 item‿items: ⊑(item⊸≡¨items)⊐1}
Diagnostic ← {𝕊 codeText‿messageText:
  {severity⇐"error",stage⇐"section_planned_payments",code⇐codeText,message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}
EmptyRows ← {𝕊:
  {
    count⇐0,index⇐empty,status⇐empty,date⇐empty,category⇐empty,memo⇐empty,plan_id⇐empty,
    currency⇐empty,planned_coefficient⇐empty,planned_scale⇐empty,
    actual_coefficient⇐empty,actual_scale⇐empty,
    from_account⇐empty,to_account⇐empty,
    plan_reference⇐empty,actual_reference⇐empty,
    planned_contributors⇐empty,actual_contributors⇐empty
  }
}
EmptyResult ← {𝕊 diagnosticsValue:
  {
    state⇐"error",period_start⇐"",period_end_exclusive⇐"",as_of⇐"",currency⇐"",
    rows⇐EmptyRows @,open_indices⇐empty,completed_indices⇐empty,
    open_total_coefficient⇐empty,open_total_scale⇐empty,diagnostics⇐diagnosticsValue
  }
}
StartsWith ← {𝕊 prefix‿value: prefix≡(≠prefix)↑value}
CategoryLabel ← {𝕊 accountKey‿role:
  label ← accountKey
  {𝕊: label↩9↓accountKey}⍟((role≡"expense") ∧ StartsWith ⟨"expenses:",accountKey⟩) @
  {𝕊: label↩7↓accountKey}⍟((role≡"income") ∧ StartsWith ⟨"income:",accountKey⟩) @
  {𝕊: label↩12↓accountKey}⍟((role≡"liability") ∧ StartsWith ⟨"liabilities:",accountKey⟩) @
  label
}

# Inputs are canonical Facts, one successful resolved cycle, and explicit observation.
Build ← {𝕊 planFacts‿actualFacts‿cycle‿asOfText:
  diagnostics ← empty
  diagnostics ∾↩ AddIf ⟨cycle.state≢"ok",Diagnostic ⟨"cycle_not_ok","Planned Payments requires a resolved cycle"⟩⟩
  planFactsOk ← reference.SourceIs ⟨planFacts,"plan.tsv"⟩
  actualFactsOk ← reference.SourceIs ⟨actualFacts,"actual.journal"⟩
  diagnostics ∾↩ AddIf ⟨¬planFactsOk,Diagnostic ⟨"plan_facts_invalid","Plan facts must be admitted from plan.tsv"⟩⟩
  diagnostics ∾↩ AddIf ⟨¬actualFactsOk,Diagnostic ⟨"actual_facts_invalid","Actual facts must be admitted from actual.journal"⟩⟩
  asOfValid ← dates.IsValid asOfText
  diagnostics ∾↩ AddIf ⟨¬asOfValid,Diagnostic ⟨"observation_invalid","as-of must be strict Gregorian text"⟩⟩
  result ← EmptyResult diagnostics
  {𝕊:
    startOrdinal ← cycle.start_ordinal
    endOrdinal ← cycle.end_exclusive_ordinal
    asOfOrdinal ← dates.Ordinal asOfText
    diagnostics ∾↩ AddIf ⟨asOfOrdinal<startOrdinal ∨ asOfOrdinal≥endOrdinal,Diagnostic ⟨"observation_out_of_period","as-of must occur inside the cycle"⟩⟩

    planMask ← (planFacts.transactions.date_ordinal≥startOrdinal) ∧ planFacts.transactions.date_ordinal<endOrdinal
    actualMask ← (actualFacts.transactions.date_ordinal≥startOrdinal) ∧ actualFacts.transactions.date_ordinal<endOrdinal
    planSelection ← planMask/planFacts.transactions.index
    planDates ← planMask/planFacts.transactions.date_ordinal
    planSelection ↩ (⍋planDates)⊏planSelection
    actualSelection ← actualMask/actualFacts.transactions.index
    expectedAsOf ← startOrdinal
    {𝕊: expectedAsOf↩⌈´actualMask/actualFacts.transactions.date_ordinal}⍟(0<≠actualSelection) @
    diagnostics ∾↩ AddIf ⟨asOfOrdinal≠expectedAsOf,Diagnostic ⟨"observation_evidence_mismatch","as-of must equal latest selected Actual date, or cycle start when empty"⟩⟩

    joined ← completion.Build ⟨planFacts,actualFacts,planSelection,actualSelection⟩
    diagnostics ∾↩ joined.diagnostics
    {𝕊:
      diagnostics ∾↩ AddIf ⟨joined.counts.duplicate>0,Diagnostic ⟨"completion_duplicate","duplicate Actual completion evidence cannot be rendered as paid"⟩⟩
      diagnostics ∾↩ AddIf ⟨joined.counts.ambiguous>0,Diagnostic ⟨"completion_ambiguous","conflicting Actual completion evidence cannot be rendered"⟩⟩
      selectedCurrencies ← Unique joined.rows.currency
      diagnostics ∾↩ AddIf ⟨1<≠selectedCurrencies,Diagnostic ⟨"currency_domain_mixed","Planned Payments cannot total multiple currency domains"⟩⟩

      candidateRows ← empty
      {𝕊 rowIndex:
        relationStatus ← rowIndex⊑joined.rows.status
        completed ← relationStatus≡"completed"
        currencyMatch ← 1 ⋄ directionMatch ← 1
        {𝕊:
          currencyMatch↩⊑rowIndex⊑joined.rows.currency_matches
          directionMatch↩⊑rowIndex⊑joined.rows.direction_matches
        }⍟completed @
        diagnostics ∾↩ AddIf ⟨completed ∧ ¬currencyMatch,Diagnostic ⟨"completion_currency_mismatch","completed Plan and Actual currency must agree"⟩⟩
        diagnostics ∾↩ AddIf ⟨completed ∧ ¬directionMatch,Diagnostic ⟨"completion_direction_mismatch","completed Plan and Actual Account directions must agree"⟩⟩
        {𝕊:
          planDate ← rowIndex⊑joined.rows.plan_date
          temporalStatus ← "completed"
          {𝕊:
            planOrdinal ← dates.Ordinal planDate
            temporalStatus↩"overdue"
            {𝕊: temporalStatus↩"due"}⍟(planOrdinal=asOfOrdinal) @
            {𝕊: temporalStatus↩"future"}⍟(planOrdinal>asOfOrdinal) @
          }⍟(¬completed) @
          fromAccount ← rowIndex⊑joined.rows.planned_from_account
          toAccount ← rowIndex⊑joined.rows.planned_to_account
          fromIndex ← IndexOf ⟨fromAccount,planFacts.accounts.key⟩
          categoryAccount ← toAccount
          {𝕊: categoryAccount↩fromAccount}⍟((fromIndex⊑planFacts.accounts.role)≡"income") @
          categoryIndex ← IndexOf ⟨categoryAccount,planFacts.accounts.key⟩
          actualCoefficient ← empty ⋄ actualScale ← empty ⋄ actualReference ← empty ⋄ actualContributors ← empty
          {𝕊:
            actualCoefficient↩⊑rowIndex⊑joined.rows.actual_coefficients
            actualScale↩⊑rowIndex⊑joined.rows.actual_scales
            actualReference↩⊑rowIndex⊑joined.rows.actual_references
            actualContributors↩(⊑rowIndex⊑joined.rows.actual_debit_contributors)∾⊑rowIndex⊑joined.rows.actual_credit_contributors
          }⍟completed @
          candidateRows∾↩⟨{
            status⇐temporalStatus,date⇐planDate,
            category⇐CategoryLabel ⟨categoryAccount,categoryIndex⊑planFacts.accounts.role⟩,
            memo⇐rowIndex⊑planFacts.transactions.description,
            plan_id⇐rowIndex⊑joined.rows.plan_id,currency⇐rowIndex⊑joined.rows.currency,
            planned_coefficient⇐rowIndex⊑joined.rows.planned_coefficient,
            planned_scale⇐rowIndex⊑joined.rows.planned_scale,
            actual_coefficient⇐actualCoefficient,actual_scale⇐actualScale,
            from_account⇐fromAccount,to_account⇐toAccount,
            plan_reference⇐rowIndex⊑joined.rows.plan_reference,actual_reference⇐actualReference,
            planned_contributors⇐(rowIndex⊑joined.rows.planned_debit_contributors)∾rowIndex⊑joined.rows.planned_credit_contributors,
            actual_contributors⇐actualContributors
          }⟩
        }⍟((relationStatus≡"open") ∨ completed) @
      }¨joined.rows.index

      {𝕊:
        statuses ← {𝕩.status}¨candidateRows
        openIndices ← (¬"completed"⊸≡¨statuses)/↕≠candidateRows
        completedIndices ← ("completed"⊸≡¨statuses)/↕≠candidateRows
        openScales ← openIndices⊏{𝕩.planned_scale}¨candidateRows
        openTotalScale ← 0
        {𝕊: openTotalScale↩⌈´openScales}⍟(0<≠openScales) @
        normalized ← {𝕊 i: scale.Normalize ⟨(i⊑candidateRows).planned_coefficient,(i⊑candidateRows).planned_scale,openTotalScale⟩}¨openIndices
        normalizedOk ← ∧´1∾{𝕩.state≡"ok"}¨normalized
        diagnostics ∾↩ AddIf ⟨¬normalizedOk,Diagnostic ⟨"open_total_normalization_failed","open Plan amounts cannot normalize exactly"⟩⟩
        {𝕊:
          openTotal ← scale.Sum {𝕩.coefficient}¨normalized
          diagnostics ∾↩ AddIf ⟨openTotal.state≢"ok",Diagnostic ⟨"open_total_sum_failed","open Plan total exceeds exact range"⟩⟩
          {𝕊:
            rows ← {
              count⇐≠candidateRows,index⇐↕≠candidateRows,status⇐statuses,
              date⇐{𝕩.date}¨candidateRows,category⇐{𝕩.category}¨candidateRows,memo⇐{𝕩.memo}¨candidateRows,
              plan_id⇐{𝕩.plan_id}¨candidateRows,currency⇐{𝕩.currency}¨candidateRows,
              planned_coefficient⇐{𝕩.planned_coefficient}¨candidateRows,planned_scale⇐{𝕩.planned_scale}¨candidateRows,
              actual_coefficient⇐{𝕩.actual_coefficient}¨candidateRows,actual_scale⇐{𝕩.actual_scale}¨candidateRows,
              from_account⇐{𝕩.from_account}¨candidateRows,to_account⇐{𝕩.to_account}¨candidateRows,
              plan_reference⇐{𝕩.plan_reference}¨candidateRows,actual_reference⇐{𝕩.actual_reference}¨candidateRows,
              planned_contributors⇐{𝕩.planned_contributors}¨candidateRows,actual_contributors⇐{𝕩.actual_contributors}¨candidateRows
            }
            resultCurrency ← ""
            {𝕊: resultCurrency↩⊑selectedCurrencies}⍟(0<≠selectedCurrencies) @
            result↩{
              state⇐"ok",period_start⇐cycle.start,period_end_exclusive⇐cycle.end_exclusive,as_of⇐asOfText,
              currency⇐resultCurrency,
              rows⇐rows,open_indices⇐openIndices,completed_indices⇐completedIndices,
              open_total_coefficient⇐openTotal.coefficient,open_total_scale⇐openTotalScale,diagnostics⇐empty
            }
          }⍟(openTotal.state≡"ok") @
        }⍟normalizedOk @
      }⍟(0=≠diagnostics) @
    }⍟(joined.state≡"ok") @
  }⍟((cycle.state≡"ok") ∧ asOfValid ∧ planFactsOk ∧ actualFactsOk) @
  {𝕊: result↩EmptyResult diagnostics}⍟(0<≠diagnostics) @
  result
}

AmountText ← {𝕊 coefficient‿scaleValue: amount.Format ⟨coefficient,scaleValue⟩}
Table ← {𝕊 headers‿rows‿rightAligned:
  columnCount ← ≠headers
  widths ← {𝕊 column:
    ⌈´⟨text.VWidth column⊑headers⟩∾{text.VWidth column⊑𝕩}¨rows
  }¨↕columnCount
  RenderRow ← {𝕊 row:
    cells ← {𝕊 column:
      width ← column⊑widths ⋄ value ← column⊑row
      cell ← text.PadRight ⟨width,value⟩
      {𝕊: cell↩text.PadLeft ⟨width,value⟩}⍟(column∊rightAligned) @
      cell
    }¨↕columnCount
    ∾{𝕊 column: ((column>0)/" | ")∾column⊑cells}¨↕columnCount
  }
  separator ← ∾{𝕊 column: ((column>0)/"-+-")∾((column⊑widths)⥊'-')}¨↕columnCount
  (RenderRow headers)∾(@+10)∾separator∾(@+10)∾∾{(RenderRow 𝕩)∾(@+10)}¨rows
}

FormatHuman ← {𝕊 result:
  openRows ← {𝕊 index:
    ⟨index⊑result.rows.date,index⊑result.rows.category,index⊑result.rows.memo,
      AmountText ⟨index⊑result.rows.planned_coefficient,index⊑result.rows.planned_scale⟩,
      index⊑result.rows.status⟩
  }¨result.open_indices
  completedRows ← {𝕊 index:
    ⟨index⊑result.rows.date,index⊑result.rows.category,index⊑result.rows.memo,
      AmountText ⟨index⊑result.rows.planned_coefficient,index⊑result.rows.planned_scale⟩,
      AmountText ⟨index⊑result.rows.actual_coefficient,index⊑result.rows.actual_scale⟩⟩
  }¨result.completed_indices
  out ← "== Planned Payments =="∾(@+10)∾(@+10)
  out ∾↩ "── 未了 ──"∾(@+10)
  out ∾↩ Table ⟨⟨"Date","Category","Memo","Amount","Status"⟩,openRows,⟨3⟩⟩
  out ∾↩ (@+10)∾"未了合計: "∾(AmountText ⟨result.open_total_coefficient,result.open_total_scale⟩)∾(@+10)∾(@+10)
  out ∾↩ "── 完了 ──"∾(@+10)
  out ∾↩ Table ⟨⟨"Date","Category","Memo","Planned","Actual"⟩,completedRows,⟨3,4⟩⟩
  out ∾↩ (@+10)∾"[Status]"∾(@+10)
  out ∾↩ "future  : これから"∾(@+10)
  out ∾↩ "due     : 今日が期限"∾(@+10)
  out ∾↩ "overdue : 期限超過 ⚠"∾(@+10)
  out ∾↩ "completed : 支払い済み"∾(@+10)∾(@+10)
  out
}

FormatCompact ← {𝕊 result:
  out ← "--- Ledger Planned Payments ---"∾(@+10)
  {𝕊 index:
    machineStatus ← ((index⊑result.rows.status)≡"completed")⊑"planned"‿"paid"
    out ∾↩ "ledger_planned_payment: "∾(index⊑result.rows.date)∾" "∾machineStatus∾" "
    out ∾↩ (index⊑result.rows.memo)∾" "∾(index⊑result.rows.from_account)∾" "∾(index⊑result.rows.to_account)∾" "
    out ∾↩ (AmountText ⟨index⊑result.rows.planned_coefficient,index⊑result.rows.planned_scale⟩)∾(@+10)
  }¨result.rows.index
  {𝕊: out∾↩"ledger_planned_payment: (none)"∾(@+10)}⍟(0=result.rows.count) @
  out
}

JsonString ← {𝕊 value:
  quote←@+34 ⋄ slash←@+92
  Escape ← {
    (𝕩=quote) ? slash∾quote ;
    (𝕩=slash) ? slash∾slash ;
    (𝕩=@+8) ? slash∾"b" ;
    (𝕩=@+9) ? slash∾"t" ;
    (𝕩=@+10) ? slash∾"n" ;
    (𝕩=@+12) ? slash∾"f" ;
    (𝕩=@+13) ? slash∾"r" ;
    (𝕩<@+32) ? slash∾"u00"∾((⌊(𝕩-@)÷16)⊑"0123456789abcdef")∾((16|𝕩-@)⊑"0123456789abcdef") ;
    ⟨𝕩⟩
  }
  quote∾(∾Escape¨value)∾quote
}
JsonArray ← {𝕊 values: "["∾(∾{𝕊 i: ((i>0)/", ")∾i⊑values}¨↕≠values)∾"]"}
JsonPair ← {𝕊 key‿valueText: (JsonString key)∾": "∾valueText}
JsonObject ← {𝕊 pairs: "{"∾(∾{𝕊 i: ((i>0)/", ")∾i⊑pairs}¨↕≠pairs)∾"}"}
FormatJson ← {𝕊 result:
  OpenItem ← {𝕊 index:
    JsonObject ⟨
      JsonPair ⟨"date",(JsonString index⊑result.rows.date)⟩,
      JsonPair ⟨"category",(JsonString index⊑result.rows.category)⟩,
      JsonPair ⟨"memo",(JsonString index⊑result.rows.memo)⟩,
      JsonPair ⟨"amount",(AmountText ⟨index⊑result.rows.planned_coefficient,index⊑result.rows.planned_scale⟩)⟩,
      JsonPair ⟨"status",(JsonString index⊑result.rows.status)⟩,
      JsonPair ⟨"plan_id",(JsonString index⊑result.rows.plan_id)⟩
    ⟩
  }
  CompletedItem ← {𝕊 index:
    JsonObject ⟨
      JsonPair ⟨"date",(JsonString index⊑result.rows.date)⟩,
      JsonPair ⟨"category",(JsonString index⊑result.rows.category)⟩,
      JsonPair ⟨"memo",(JsonString index⊑result.rows.memo)⟩,
      JsonPair ⟨"amount",(AmountText ⟨index⊑result.rows.planned_coefficient,index⊑result.rows.planned_scale⟩)⟩,
      JsonPair ⟨"actual_amount",(AmountText ⟨index⊑result.rows.actual_coefficient,index⊑result.rows.actual_scale⟩)⟩,
      JsonPair ⟨"status",(JsonString "completed")⟩,
      JsonPair ⟨"plan_id",(JsonString index⊑result.rows.plan_id)⟩
    ⟩
  }
  openItems ← OpenItem¨result.open_indices
  completedItems ← CompletedItem¨result.completed_indices
  JsonObject ⟨
    JsonPair ⟨"open_items",(JsonArray openItems)⟩,
    JsonPair ⟨"open_total",(AmountText ⟨result.open_total_coefficient,result.open_total_scale⟩)⟩,
    JsonPair ⟨"completed_items",(JsonArray completedItems)⟩
  ⟩
}

{Build⇐Build,FormatHuman⇐FormatHuman,FormatCompact⇐FormatCompact,FormatJson⇐FormatJson}
