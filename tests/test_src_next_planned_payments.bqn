#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
context ← •Import "../src_next/context.bqn"
planned ← •Import "../src_next/planned_payments.bqn"

# Prepared semantic input exercises the pure computation/rendering boundary
# without a base path, source adapter, or context namespace.
prepared ← {
  rows⇐⟨
    "2026-01-02\tfuture food\tassets:bank\texpenses:food\t100",
    "2026-01-03\tpaid food\tassets:bank\texpenses:food\t80"
  ⟩,
  parsed⇐⟨
    ⟨"2026-01-02", "future food", "assets:bank", "expenses:food", 100⟩,
    ⟨"2026-01-03", "paid food", "assets:bank", "expenses:food", 80⟩
  ⟩,
  plan_ids⇐⟨"p-open", "p-paid"⟩,
  completed_mask⇐⟨0, 1⟩,
  actuals⇐⟨0, 80⟩,
  temporal_statuses⇐⟨"future", "completed"⟩
}
vm_prepared ← planned.BuildViewModelFromPreparedForTest prepared
100 lib.AssertEq vm_prepared.open_total
⟨0⟩ lib.AssertEq vm_prepared.open_indices
⟨1⟩ lib.AssertEq vm_prepared.completed_indices
compact_prepared ← planned.BuildCompactViewModelFromPreparedForTest prepared
1 lib.AssertEq ∨´ " planned "⍷planned.FormatCompactViewModelForTest compact_prepared
1 lib.AssertEq ∨´ " paid "⍷planned.FormatCompactViewModelForTest compact_prepared
human_prepared ← planned.FormatHumanViewModelForTest vm_prepared
1 lib.AssertEq ∨´ "== Planned Payments =="⍷human_prepared
json_prepared ← planned.FormatJsonViewModelForTest vm_prepared
1 lib.AssertEq ∨´ "open_total"⍷json_prepared
1 lib.AssertEq ∨´ ": 100"⍷json_prepared

base ← "fixtures/plan-completion"
ctx ← context.BuildContext base
human ← planned.FormatHuman ctx

# Verify section header and content elements
1 lib.AssertEq ∨´ "== Planned Payments =="⍷human
1 lib.AssertEq ∨´ "[Status]"⍷human
1 lib.AssertEq ∨´ "completed"⍷human
1 lib.AssertEq ∨´ "overdue"⍷human

•Out "test_src_next_planned_payments.bqn: OK"
