lib ← •Import "test_lib.bqn"
context ← •Import "../src_next/context.bqn"
ytd ← •Import "../src_next/ytd_summary.bqn"

base ← "fixtures/src-next-golden"
ctx ← context.BuildContext base
summary ← ytd.Build ctx

# Check range
"2026-01-01" lib.AssertEq summary.range_start
"2026-06-22" lib.AssertEq summary.range_end_exclusive

# Check actuals
120 lib.AssertEq summary.expense_actual # Food (100) + Rent (20)
0 lib.AssertEq summary.income_actual
¯120 lib.AssertEq summary.net_actual

# Check backward-compatible breakdowns
0 lib.AssertEq ≠ summary.fixed_breakdown
2 lib.AssertEq ≠ summary.var_breakdown

# Check new ytd_entries (net movement with sign convention)
# expenses:food/JPY: debit=100, credit=-20, net=80, role=expense → flow=-80
# expenses:rent/JPY: debit=20, credit=0, net=20, role=expense → flow=-20
# equity:opening is role "unknown" → not in any role bucket
2 lib.AssertEq ≠ summary.ytd_entries

firstYtd ← 0 ⊑ summary.ytd_entries
"expenses:food/JPY" lib.AssertEq 0⊑firstYtd
¯80 lib.AssertEq 1⊑firstYtd

secondYtd ← 1 ⊑ summary.ytd_entries
"expenses:rent/JPY" lib.AssertEq 0⊑secondYtd
¯20 lib.AssertEq 1⊑secondYtd

# Check FormatHuman output (FmtYtdAmt uses +/- prefix for non-zero)
human ← ytd.FormatHuman summary
1 lib.AssertEq ∨´ "== YTD Summary =="⍷human
1 lib.AssertEq ∨´ "expenses:food/JPY"⍷human
1 lib.AssertEq ∨´ "-80"⍷human
1 lib.AssertEq ∨´ "expenses:rent/JPY"⍷human
1 lib.AssertEq ∨´ "-20"⍷human

•Out "test_src_next_ytd_summary.bqn: OK"
