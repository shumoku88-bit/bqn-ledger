#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
actualSource ← •Import "../src/application/actual_source_adapter.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
budgetPolicyAdmission ← •Import "../src/ledger/budget_policy_admission.bqn"
householdAdmission ← •Import "../src/ledger/household_policy_admission.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
flow ← •Import "../src/accounting/date_category_flow.bqn"
section ← •Import "../src/sections/daily_flow.bqn"

base ← "fixtures/ledger-facts-phase1-proof/"
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
actualResult ← actualSource.Load ⟨base,registry⟩
"ok" lib.AssertEq actualResult.state
facts ← actualResult.facts
budgetPolicy ← budgetPolicyAdmission.Admit ⟨•FChars "../"∾base∾"budget.toml",facts.accounts⟩
"ok" lib.AssertEq budgetPolicy.state
household ← householdAdmission.Admit ⟨•FChars "../"∾base∾"household.toml",facts.accounts,budgetPolicy⟩
"ok" lib.AssertEq household.state
startText ← "2026-01-01"
endText ← "2026-02-01"
start ← dates.Ordinal startText
end ← dates.Ordinal endText
accounting ← flow.Build ⟨facts,budgetPolicy,household,"JPY","actual",start,end⟩
result ← section.Build ⟨accounting,startText,endText,"2026-01-12"⟩

"ok" lib.AssertEq result.state
0 lib.AssertEq ≠result.diagnostics
⟨
  "assets:cash/JPY","income:salary/JPY","expenses:food/JPY","expenses:transport/JPY",
  "budget:opening/JPY","budget:unassigned/JPY","budget:food/JPY","budget:spent/JPY"
⟩ lib.AssertEq result.column_labels
⟨"2026-01-02","2026-01-10","2026-01-12"⟩ lib.AssertEq result.date_text
⟨
  ⟨1000,¯1000,0,0,0,0,0,0⟩,
  ⟨¯20,0,20,0,0,0,0,0⟩,
  ⟨¯15,0,10,5,0,0,0,0⟩
⟩ lib.AssertEq result.matrix.values
⟨1,2,3⟩ lib.AssertEq result.inverted_column_indices
⟨0⟩ lib.AssertEq 0⊑0⊑result.matrix.contributors
⟨1⟩ lib.AssertEq 1⊑0⊑result.matrix.contributors
⟨3⟩ lib.AssertEq 0⊑1⊑result.matrix.contributors
⟨2⟩ lib.AssertEq 2⊑1⊑result.matrix.contributors
⟨4⟩ lib.AssertEq 2⊑2⊑result.matrix.contributors
⟨5⟩ lib.AssertEq 3⊑2⊑result.matrix.contributors

syntheticStartText ← "2026-02-01"
syntheticEndText ← "2026-02-02"
syntheticStart ← dates.Ordinal syntheticStartText
syntheticEnd ← dates.Ordinal syntheticEndText
syntheticFlow ← {
  state⇐"ok",domain⇐"JPY",layer⇐"actual",
  start_ordinal⇐syntheticStart,end_exclusive_ordinal⇐syntheticEnd,scale⇐0,
  dates⇐{
    count⇐1,index⇐⟨0⟩,date_ordinal⇐⟨syntheticStart⟩,date_text⇐⟨syntheticStartText⟩,
    income⇐⟨10⟩,net⇐⟨6⟩,income_contributors⇐⟨⟨5,1,5⟩⟩
  },
  categories⇐{
    count⇐1,index⇐⟨0⟩,label⇐⟨"food"⟩,kind⇐⟨"envelope"⟩,
    envelope_account_index⇐⟨0⟩
  },
  expense_groups⇐{
    count⇐1,index⇐⟨0⟩,row_index⇐⟨0⟩,column_index⇐⟨0⟩,
    coefficient⇐⟨4⟩,contributors⇐⟨⟨3,1,3⟩⟩
  },
  accounts⇐{
    count⇐3,index⇐↕3,account_index⇐↕3,
    key⇐⟨"income:work","expenses:food","assets:cash"⟩,
    role⇐⟨"income","expense","asset"⟩
  },
  account_groups⇐{
    count⇐3,index⇐↕3,row_index⇐3⥊0,column_index⇐↕3,
    coefficient⇐⟨¯10,4,6⟩,contributors⇐⟨⟨5,1,5⟩,⟨3,1,3⟩,⟨7⟩⟩
  },
  diagnostics⇐⟨⟩
}
deduplicated ← section.Build ⟨syntheticFlow,syntheticStartText,syntheticEndText,syntheticStartText⟩
"ok" lib.AssertEq deduplicated.state
⟨syntheticStartText⟩ lib.AssertEq deduplicated.date_text
⟨⟨¯10,4,6⟩⟩ lib.AssertEq deduplicated.matrix.values
⟨0,1⟩ lib.AssertEq deduplicated.inverted_column_indices
⟨5,1,5⟩ lib.AssertEq 0⊑0⊑deduplicated.matrix.contributors
⟨3,1,3⟩ lib.AssertEq 1⊑0⊑deduplicated.matrix.contributors
⟨7⟩ lib.AssertEq 2⊑0⊑deduplicated.matrix.contributors

human ← section.FormatHuman result
human lib.AssertEq section.FormatHuman result
(•FChars "../"∾base∾"daily_flow.destination.human.txt") lib.AssertEq human
limited ← section.FormatHuman ⟨result,{negative_style⇐"minus",daily_flow_max_date_columns⇐2}⟩
lib.Assert ∨´"Account                | 2026-01-10 | 2026-01-12"⍷limited
lib.Assert ¬∨´"Account                | 2026-01-02"⍷limited

emptyFacts ← {
  state⇐facts.state,transactions⇐{
    count⇐0,index⇐⟨⟩,transaction_id⇐⟨⟩,source_event_id⇐⟨⟩,identity_kind⇐⟨⟩,
    source_start_line⇐⟨⟩,source_end_line⇐⟨⟩,date_ordinal⇐⟨⟩,date_text⇐⟨⟩,
    domain_index⇐⟨⟩,layer_index⇐⟨⟩,description⇐⟨⟩,status_marker⇐⟨⟩,
    txn_id⇐⟨⟩,plan_id⇐⟨⟩,allocation_id⇐⟨⟩,execution_envelope⇐⟨⟩,
    actual_event_id⇐⟨⟩,metadata⇐⟨⟩
  },postings⇐{
    count⇐0,index⇐⟨⟩,transaction_index⇐⟨⟩,posting_index⇐⟨⟩,posting_id⇐⟨⟩,
    account_index⇐⟨⟩,domain_index⇐⟨⟩,layer_index⇐⟨⟩,date_ordinal⇐⟨⟩,
    coefficient⇐⟨⟩,scale⇐⟨⟩,side⇐⟨⟩,source_line⇐⟨⟩
  },sources⇐facts.sources,domains⇐facts.domains,accounts⇐facts.accounts,layers⇐facts.layers,diagnostics⇐⟨⟩
}
emptyAccounting ← flow.Build ⟨emptyFacts,budgetPolicy,household,"JPY","actual",start,end⟩
"ok" lib.AssertEq emptyAccounting.state
0 lib.AssertEq emptyAccounting.dates.count
emptyResult ← section.Build ⟨emptyAccounting,startText,endText,startText⟩
"ok" lib.AssertEq emptyResult.state
⟨startText⟩ lib.AssertEq emptyResult.date_text
⟨8⥊0⟩ lib.AssertEq emptyResult.matrix.values

rejected ← section.Build ⟨accounting,startText,endText,"2026-01-11"⟩
"error" lib.AssertEq rejected.state
0 lib.AssertEq rejected.matrix.cell_count
1 lib.AssertEq ∨´0∾"observation_evidence_mismatch"⊸≡¨{𝕩.code}¨rejected.diagnostics

•Out "test_section_daily_flow: ok"
