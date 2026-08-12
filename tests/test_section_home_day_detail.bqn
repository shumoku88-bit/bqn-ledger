#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
section ← •Import "../src/sections/home_day_detail.bqn"

lf ← @+10
selectedDate ← "2026-08-12"
calendar ← {
  state⇐"ok",
  days⇐{
    date⇐⟨selectedDate⟩,
    actual_indices⇐⟨⟨0⟩⟩,
    plan_indices⇐⟨⟨0⟩⟩,
    issue_indices⇐⟨⟨0⟩⟩
  }
}
transactionRows ← {
  state⇐"ok",diagnostics⇐⟨⟩,
  rows⇐⟨{
    transaction_index⇐0,description⇐"Groceries",domain⇐"JPY",
    postings⇐⟨
      {side⇐"credit",account_key⇐"Assets:Bank",amount_text⇐"5000"},
      {side⇐"debit",account_key⇐"Expenses:Groceries",amount_text⇐"5000"}
    ⟩
  }⟩
}
planned ← {
  state⇐"ok",
  rows⇐{
    plan_id⇐⟨"plan-001"⟩,status⇐⟨"due"⟩,category⇐⟨"Groceries"⟩,memo⇐⟨"Weekly food"⟩,
    currency⇐⟨"JPY"⟩,planned_coefficient⇐⟨4000⟩,planned_scale⇐⟨0⟩,
    from_account⇐⟨"Assets:Bank"⟩,to_account⇐⟨"Expenses:Groceries"⟩
  }
}
issues ← {
  state⇐"ok",
  issues⇐{
    issue_id⇐⟨"ISSUE-001"⟩,category⇐⟨"general"⟩,title⇐⟨"Check receipt"⟩,details⇐⟨"Compare paper receipt"⟩,
    amount_present⇐⟨1⟩,coefficient⇐⟨5000⟩,scale⇐⟨0⟩,currency⇐⟨"JPY"⟩
  }
}
cycle ← {
  state⇐"ok",start⇐"2026-07-01",end_exclusive⇐"2026-08-13",
  start_ordinal⇐dates.Ordinal "2026-07-01",end_exclusive_ordinal⇐dates.Ordinal "2026-08-13"
}

result ← section.Build ⟨calendar,transactionRows,planned,issues,cycle,selectedDate⟩
"ok" lib.AssertEq result.state
selectedDate lib.AssertEq result.date
1 lib.AssertEq result.actual.count
1 lib.AssertEq result.plans.count
1 lib.AssertEq result.issues.count
1 lib.AssertEq result.cycle.contains
1 lib.AssertEq result.cycle.end_day
"Groceries" lib.AssertEq (⊑result.actual.rows).description
"plan-001" lib.AssertEq (⊑result.plans.rows).plan_id
"ISSUE-001" lib.AssertEq (⊑result.issues.rows).issue_id

expected ← ∾⟨
  "2026-08-12",lf,lf,
  "Actual",lf,
  "  [0] Groceries",lf,
  "    credit  Assets:Bank  5000 JPY",lf,
  "    debit  Expenses:Groceries  5000 JPY",lf,lf,
  "Plans due",lf,
  "  plan-001  Groceries  Weekly food  Assets:Bank -> Expenses:Groceries  4000 JPY",lf,lf,
  "Issues due",lf,
  "  ISSUE-001  [general] Check receipt  5000 JPY",lf,
  "    Compare paper receipt",lf,lf,
  "Cycle",lf,
  "  2026-07-01 .. 2026-08-13 (end exclusive)",lf,
  "  cycle end day",lf
⟩
expected lib.AssertEq section.FormatHuman result

emptyCalendar ← {
  state⇐"ok",
  days⇐{
    date⇐⟨"2026-08-11"⟩,
    actual_indices⇐⟨⟨⟩⟩,plan_indices⇐⟨⟨⟩⟩,issue_indices⇐⟨⟨⟩⟩
  }
}
emptyResult ← section.Build ⟨emptyCalendar,transactionRows,planned,issues,cycle,"2026-08-11"⟩
0 lib.AssertEq emptyResult.actual.count
0 lib.AssertEq emptyResult.plans.count
0 lib.AssertEq emptyResult.issues.count

outside ← section.Build ⟨calendar,transactionRows,planned,issues,cycle,"2026-08-13"⟩
"error" lib.AssertEq outside.state
"selected_date_outside_month" lib.AssertEq (⊑outside.diagnostics).code

•Out "test_section_home_day_detail: ok"
