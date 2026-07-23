#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
cube ← •Import "../src_next/cube.bqn"

MakeRow ← {𝕊 status‿day‿ak‿layer‿delta‿srcId‿side‿kind:
  {
    source_file       ⇐ "actual.journal",
    source_row        ⇐ 0,
    source_id         ⇐ srcId,
    side              ⇐ side,
    day_index         ⇐ day,
    account_key_index ⇐ ak,
    layer_index       ⇐ layer,
    delta             ⇐ delta,
    kind              ⇐ kind,
    status            ⇐ status,
    message           ⇐ ""
  }
}

valid_debit ← MakeRow ⟨"ok", 0, 1, cube.layer_actual, 10, "A", "debit", "expense"⟩
valid_credit ← MakeRow ⟨"ok", 0, 0, cube.layer_actual, ¯10, "A", "credit", "expense"⟩
valid_plan_debit ← MakeRow ⟨"ok", 0, 1, cube.layer_plan, 20, "P", "debit", "expense"⟩
valid_plan_credit ← MakeRow ⟨"ok", 0, 0, cube.layer_plan, ¯20, "P", "credit", "expense"⟩
unknown_account ← MakeRow ⟨"unknown_account", 0, 2, cube.layer_actual, 5, "B", "debit", "expense"⟩
out_of_cycle ← MakeRow ⟨"ok", 7, 0, cube.layer_actual, ¯5, "C", "credit", "expense"⟩
rows ← ⟨valid_debit, valid_credit, valid_plan_debit, valid_plan_credit, unknown_account, out_of_cycle⟩

# Row acceptance boundary: valid rows and skipped rows are separated before cube indexing.
part ← cube.PartitionRows ⟨rows, 7, 2⟩
4 lib.AssertEq part.valid_count
2 lib.AssertEq part.skipped_count
"status" lib.AssertEq 0⊑part.skipped_summary.categories
"day_after_end" lib.AssertEq 1⊑part.skipped_summary.categories
1 lib.AssertEq part.skipped_summary.status
1 lib.AssertEq part.skipped_summary.day_after_end
1 lib.AssertEq part.skipped_summary.invalid_count
1 lib.AssertEq part.skipped_summary.out_of_period_count

# Detailed reasons remain stable for current compact golden output.
"status: unknown_account" lib.AssertEq cube.RowSkipReason ⟨unknown_account, 7, 2⟩
"day_index 7 >= 7" lib.AssertEq cube.RowSkipReason ⟨out_of_cycle, 7, 2⟩

# Materialize must only use valid rows. Sentinel account_key_index=2 and day_index=7
# are skipped evidence, not cube indices.
result ← cube.Materialize ⟨rows, 7, 2⟩
4 lib.AssertEq result.valid_count
2 lib.AssertEq result.skipped_count
0 lib.AssertEq 0⊑result.layer_totals_vec
0 lib.AssertEq 1⊑result.layer_totals_vec
¯10 lib.AssertEq 0⊑result.ak_totals
10 lib.AssertEq 1⊑result.ak_totals
¯10 lib.AssertEq 0⊑result.actual_account_totals
10 lib.AssertEq 1⊑result.actual_account_totals
¯20 lib.AssertEq 0⊑result.plan_account_totals
20 lib.AssertEq 1⊑result.plan_account_totals
10 lib.AssertEq result.actual_expense_total
20 lib.AssertEq result.plan_expense_total
1 lib.AssertEq result.validation_summary.actual_total_match
1 lib.AssertEq result.validation_summary.plan_total_match
1 lib.AssertEq result.validation_summary.actual_per_account_totals_match

•Out "test_src_next_cube.bqn: OK"
