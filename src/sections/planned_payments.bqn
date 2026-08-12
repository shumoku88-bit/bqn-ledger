# Destination Planned Payments List result and human/compact/JSON renderers.
# This section owns selection, observation, cycle grouping, totals, and presentation.
# Completed Plans are excluded from the section semantic result.

completion ← •Import "../accounting/plan_completion_join.bqn"
planStatus ← •Import "../accounting/plan_temporal_status.bqn"
reference ← •Import "../ledger/fact_reference.bqn"
scale ← •Import "../ledger/exact_scale.bqn"
dates ← •Import "../ledger/date_ordinal.bqn"
amount ← •Import "../ledger/amount_text.bqn"
text ← •Import "../report/text.bqn"
json ← •Import "../report/json_text.bqn"
empty ← ⟨⟩
lf ← @+10

IndexOf ← {𝕊 item‿items: ⊑(item⊸≡¨items)⊐1}
Diagnostic ← {𝕊 codeText‿messageText:
  {severity⇐"error",stage⇐"section_planned_payments",code⇐codeText,message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}
EmptyRows ← {𝕊:
  {
    count⇐0,index⇐empty,status⇐empty,time_group⇐empty,date⇐empty,category⇐empty,memo⇐empty,plan_id⇐empty,
    currency⇐empty,planned_coefficient⇐empty,planned_scale⇐empty,
    from_account⇐empty,to_account⇐empty,
    plan_reference⇐empty,planned_contributors⇐empty
  }
}
EmptyResult ← {𝕊 diagnosticsValue:
  {
    state⇐"error",period_start⇐"",period_end_exclusive⇐"",as_of⇐"",currency⇐"",
    rows⇐EmptyRows @,overdue_indices⇐empty,current_cycle_indices⇐empty,future_cycle_indices⇐empty,
    overdue_total_coefficient⇐empty,overdue_total_scale⇐empty,
    current_cycle_total_coefficient⇐empty,current_cycle_total_scale⇐empty,
    due_through_cycle_total_coefficient⇐empty,due_through_cycle_total_scale⇐empty,
    future_cycles_total_coefficient⇐empty,future_cycles_total_scale⇐empty,
    diagnostics⇐diagnosticsValue
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
  planFactsOk ← reference.SourceIs ⟨planFacts,"plan.journal"⟩
  actualFactsOk ← reference.SourceIs ⟨actualFacts,"actual.journal"⟩
  diagnostics ∾↩ AddIf ⟨¬planFactsOk,Diagnostic ⟨"plan_facts_invalid","Plan facts must be admitted from plan.journal"⟩⟩
  diagnostics ∾↩ AddIf ⟨¬actualFactsOk,Diagnostic ⟨"actual_facts_invalid","Actual facts must be admitted from actual.journal"⟩⟩
  asOfValid ← dates.IsValid asOfText
  diagnostics ∾↩ AddIf ⟨¬asOfValid,Diagnostic ⟨"observation_invalid","as-of must be strict Gregorian text"⟩⟩
  result ← EmptyResult diagnostics
  {𝕊:
    startOrdinal ← cycle.start_ordinal
    endOrdinal ← cycle.end_exclusive_ordinal
    asOfOrdinal ← dates.Ordinal asOfText
    diagnostics ∾↩ AddIf ⟨asOfOrdinal<startOrdinal ∨ asOfOrdinal≥endOrdinal,Diagnostic ⟨"observation_out_of_period","as-of must occur inside the cycle"⟩⟩

    currentCycleActualMask ← (actualFacts.transactions.date_ordinal≥startOrdinal) ∧ actualFacts.transactions.date_ordinal<endOrdinal
    currentCycleActuals ← currentCycleActualMask/actualFacts.transactions.date_ordinal
    expectedAsOf ← startOrdinal
    {𝕊: expectedAsOf↩⌈´currentCycleActuals}⍟(0<≠currentCycleActuals) @
    diagnostics ∾↩ AddIf ⟨asOfOrdinal≠expectedAsOf,Diagnostic ⟨"observation_evidence_mismatch","as-of must equal latest selected Actual date, or cycle start when empty"⟩⟩

    planOrder ← ⍋planFacts.transactions.date_ordinal
    planSelection ← planOrder⊏planFacts.transactions.index
    actualSelection ← actualFacts.transactions.index

    joined ← completion.Build ⟨planFacts,actualFacts,planSelection,actualSelection⟩
    diagnostics ∾↩ joined.diagnostics
    {𝕊:
      diagnostics ∾↩ AddIf ⟨joined.counts.duplicate>0,Diagnostic ⟨"completion_duplicate","duplicate Actual completion evidence cannot be rendered as paid"⟩⟩
      diagnostics ∾↩ AddIf ⟨joined.counts.ambiguous>0,Diagnostic ⟨"completion_ambiguous","conflicting Actual completion evidence cannot be rendered"⟩⟩

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
      }¨joined.rows.index

      openIndices ← ("open"⊸≡¨joined.rows.status)/joined.rows.index
      candidateRows ← {𝕊 rowIndex:
        planTransactionIndex ← rowIndex⊑joined.rows.plan_transaction_index
        planDate ← rowIndex⊑joined.rows.plan_date
        planOrdinal ← dates.Ordinal planDate
        timeGroup ← "current_cycle"
        {𝕊: timeGroup↩"overdue"}⍟(planOrdinal<startOrdinal) @
        {𝕊: timeGroup↩"future_cycles"}⍟(planOrdinal≥endOrdinal) @

        temporalStatus ← planStatus.Classify ⟨planDate,asOfText⟩

        fromAccount ← rowIndex⊑joined.rows.planned_from_account
        toAccount ← rowIndex⊑joined.rows.planned_to_account
        fromIndex ← IndexOf ⟨fromAccount,planFacts.accounts.key⟩
        categoryAccount ← toAccount
        {𝕊: categoryAccount↩fromAccount}⍟((fromIndex⊑planFacts.accounts.role)≡"income") @
        categoryIndex ← IndexOf ⟨categoryAccount,planFacts.accounts.key⟩

        {
          status⇐temporalStatus,time_group⇐timeGroup,date⇐planDate,
          category⇐CategoryLabel ⟨categoryAccount,categoryIndex⊑planFacts.accounts.role⟩,
          memo⇐planTransactionIndex⊑planFacts.transactions.description,
          plan_id⇐rowIndex⊑joined.rows.plan_id,currency⇐rowIndex⊑joined.rows.currency,
          planned_coefficient⇐rowIndex⊑joined.rows.planned_coefficient,
          planned_scale⇐rowIndex⊑joined.rows.planned_scale,
          from_account⇐fromAccount,to_account⇐toAccount,
          plan_reference⇐rowIndex⊑joined.rows.plan_reference,
          planned_contributors⇐(rowIndex⊑joined.rows.planned_debit_contributors)∾rowIndex⊑joined.rows.planned_credit_contributors
        }
      }¨openIndices

      {𝕊:
        selectedCurrencies ← ⍷({𝕩.currency}¨candidateRows)
        diagnostics ∾↩ AddIf ⟨1<≠selectedCurrencies,Diagnostic ⟨"currency_domain_mixed","Planned Payments cannot total multiple currency domains"⟩⟩
        resultCurrency ← ""
        {𝕊: resultCurrency↩⊑selectedCurrencies}⍟(0<≠selectedCurrencies) @

        overdueIndices ← ("overdue"⊸≡¨{𝕩.time_group}¨candidateRows)/↕≠candidateRows
        currentCycleIndices ← ("current_cycle"⊸≡¨{𝕩.time_group}¨candidateRows)/↕≠candidateRows
        futureCycleIndices ← ("future_cycles"⊸≡¨{𝕩.time_group}¨candidateRows)/↕≠candidateRows
        dueThroughIndices ← overdueIndices∾currentCycleIndices

        SumGroup ← {𝕊 indices:
          count ← ≠indices
          res ← {count⇐0,coef⇐0,scale⇐0,ok⇐1}
          {𝕊:
            scales ← indices⊏{𝕩.planned_scale}¨candidateRows
            maxScale ← ⌈´scales
            norm ← {scale.Normalize ⟨(𝕩⊑candidateRows).planned_coefficient,(𝕩⊑candidateRows).planned_scale,maxScale⟩}¨indices
            allNormOk ← ∧´1∾{𝕩.state≡"ok"}¨norm
            res ↩ {count⇐count,coef⇐0,scale⇐maxScale,ok⇐0}
            {𝕊:
              s ← scale.Sum {𝕩.coefficient}¨norm
              res ↩ {count⇐count,coef⇐s.coefficient,scale⇐maxScale,ok⇐(s.state≡"ok")}
            }⍟allNormOk @
          }⍟(0<count) @
          res
        }

        overdueSum ← SumGroup overdueIndices
        currentCycleSum ← SumGroup currentCycleIndices
        dueThroughSum ← SumGroup dueThroughIndices
        futureCyclesSum ← SumGroup futureCycleIndices

        totalsOk ← overdueSum.ok ∧ currentCycleSum.ok ∧ dueThroughSum.ok ∧ futureCyclesSum.ok
        diagnostics ∾↩ AddIf ⟨¬totalsOk,Diagnostic ⟨"total_sum_failed","open Plan total computation failed"⟩⟩

        {𝕊:
          rows ← {
            count⇐≠candidateRows,index⇐↕≠candidateRows,
            status⇐{𝕩.status}¨candidateRows,time_group⇐{𝕩.time_group}¨candidateRows,
            date⇐{𝕩.date}¨candidateRows,category⇐{𝕩.category}¨candidateRows,memo⇐{𝕩.memo}¨candidateRows,
            plan_id⇐{𝕩.plan_id}¨candidateRows,currency⇐{𝕩.currency}¨candidateRows,
            planned_coefficient⇐{𝕩.planned_coefficient}¨candidateRows,planned_scale⇐{𝕩.planned_scale}¨candidateRows,
            from_account⇐{𝕩.from_account}¨candidateRows,to_account⇐{𝕩.to_account}¨candidateRows,
            plan_reference⇐{𝕩.plan_reference}¨candidateRows,planned_contributors⇐{𝕩.planned_contributors}¨candidateRows
          }
          result↩{
            state⇐"ok",period_start⇐cycle.start,period_end_exclusive⇐cycle.end_exclusive,as_of⇐asOfText,
            currency⇐resultCurrency,
            rows⇐rows,
            overdue_indices⇐overdueIndices,current_cycle_indices⇐currentCycleIndices,future_cycle_indices⇐futureCycleIndices,
            overdue_total_coefficient⇐overdueSum.coef,overdue_total_scale⇐overdueSum.scale,
            current_cycle_total_coefficient⇐currentCycleSum.coef,current_cycle_total_scale⇐currentCycleSum.scale,
            due_through_cycle_total_coefficient⇐dueThroughSum.coef,due_through_cycle_total_scale⇐dueThroughSum.scale,
            future_cycles_total_coefficient⇐futureCyclesSum.coef,future_cycles_total_scale⇐futureCyclesSum.scale,
            diagnostics⇐empty
          }
        }⍟totalsOk @
      }⍟(0=≠diagnostics) @
    }⍟(joined.state≡"ok") @
  }⍟((cycle.state≡"ok") ∧ asOfValid ∧ planFactsOk ∧ actualFactsOk) @
  {𝕊: result↩EmptyResult diagnostics}⍟(0<≠diagnostics) @
  result
}

AmountText ← {𝕊 coefficient‿scaleValue: amount.Format ⟨coefficient,scaleValue⟩}
FormatHuman ← {𝕊 input:
  result ← input ⋄ style ← "minus"
  {𝕊: result↩0⊑input ⋄ style↩(1⊑input).negative_style}⍟((0<≡input) ∧ (2=≠input)) @
  Fmt ← {𝕊 coeff‿scale: text.FormatAmount ⟨coeff,scale,style⟩}
  currentCycleRows ← {
    ⟨𝕩⊑result.rows.date,𝕩⊑result.rows.category,𝕩⊑result.rows.memo,
      Fmt ⟨𝕩⊑result.rows.planned_coefficient,𝕩⊑result.rows.planned_scale⟩,
      𝕩⊑result.rows.status⟩
  }¨result.current_cycle_indices

  headingText ← "== Planned Payments =="∾lf∾lf
  overdueBlock ← ""
  {𝕊:
    overdueRows ← {
      ⟨𝕩⊑result.rows.date,𝕩⊑result.rows.category,𝕩⊑result.rows.memo,
        Fmt ⟨𝕩⊑result.rows.planned_coefficient,𝕩⊑result.rows.planned_scale⟩,
        𝕩⊑result.rows.status⟩
    }¨result.overdue_indices
    overdueBlock↩∾⟨
      "── 期限超過の未払い ──",lf,
      text.RenderTable ⟨⟨"Date","Category","Memo","Amount","Status"⟩,overdueRows,⟨3⟩⟩,lf
    ⟩
  }⍟(0<≠result.overdue_indices) @
  currentBlock ← ∾⟨
    "── 今サイクルの未払い ──",lf,
    text.RenderTable ⟨⟨"Date","Category","Memo","Amount","Status"⟩,currentCycleRows,⟨3⟩⟩,
    lf,"今サイクル未払い合計: ",Fmt ⟨result.current_cycle_total_coefficient,result.current_cycle_total_scale⟩,lf
  ⟩
  futureBlock ← ""
  {𝕊:
    futureCycleRows ← {
      ⟨𝕩⊑result.rows.date,𝕩⊑result.rows.category,𝕩⊑result.rows.memo,
        Fmt ⟨𝕩⊑result.rows.planned_coefficient,𝕩⊑result.rows.planned_scale⟩⟩
    }¨result.future_cycle_indices
    futureBlock↩∾⟨
      lf,"── サイクル外の予定 ──",lf,
      text.RenderTable ⟨⟨"Date","Category","Memo","Amount"⟩,futureCycleRows,⟨3⟩⟩
    ⟩
  }⍟(0<≠result.future_cycle_indices) @
  statusText ← ∾⟨
    lf,lf,"[Status]",lf,
    "future  : これから",lf,
    "due     : 今日が期限",lf,
    "overdue : 期限超過 ⚠",lf,lf
  ⟩
  ∾⟨headingText,overdueBlock,currentBlock,futureBlock,statusText⟩
}

FormatCompact ← {𝕊 result:
  rowLines ← {𝕊 index:
    ∾⟨
      "ledger_planned_payment: ",index⊑result.rows.date," planned ",
      index⊑result.rows.memo," ",index⊑result.rows.from_account," ",index⊑result.rows.to_account," ",
      AmountText ⟨index⊑result.rows.planned_coefficient,index⊑result.rows.planned_scale⟩
    ⟩
  }¨result.rows.index
  bodyLines ← rowLines∾((0=result.rows.count)/⟨"ledger_planned_payment: (none)"⟩)
  ∾{𝕩∾lf}¨⟨"--- Ledger Planned Payments ---"⟩∾bodyLines
}

FormatJson ← {𝕊 result:
  Item ← {𝕊 index:
    json.Object ⟨
      json.Pair ⟨"date",json.String index⊑result.rows.date⟩,
      json.Pair ⟨"category",json.String index⊑result.rows.category⟩,
      json.Pair ⟨"memo",json.String index⊑result.rows.memo⟩,
      json.Pair ⟨"amount",json.ExactNumber ⟨index⊑result.rows.planned_coefficient,index⊑result.rows.planned_scale⟩⟩,
      json.Pair ⟨"status",json.String index⊑result.rows.status⟩,
      json.Pair ⟨"time_group",json.String index⊑result.rows.time_group⟩,
      json.Pair ⟨"plan_id",json.String index⊑result.rows.plan_id⟩
    ⟩
  }
  openItems ← Item¨result.rows.index
  json.Object ⟨
    json.Pair ⟨"open_items",json.Array openItems⟩,
    json.Pair ⟨"current_cycle_total",json.ExactNumber ⟨result.current_cycle_total_coefficient,result.current_cycle_total_scale⟩⟩,
    json.Pair ⟨"due_through_cycle_total",json.ExactNumber ⟨result.due_through_cycle_total_coefficient,result.due_through_cycle_total_scale⟩⟩,
    json.Pair ⟨"overdue_total",json.ExactNumber ⟨result.overdue_total_coefficient,result.overdue_total_scale⟩⟩,
    json.Pair ⟨"future_cycles_total",json.ExactNumber ⟨result.future_cycles_total_coefficient,result.future_cycles_total_scale⟩⟩
  ⟩
}

{Build⇐Build,FormatHuman⇐FormatHuman,FormatCompact⇐FormatCompact,FormatJson⇐FormatJson}