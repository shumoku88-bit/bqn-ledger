#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ctx ← •Import "../src_next/context.bqn"
ak ← •Import "../src_next/account_key.bqn"
lens ← •Import "../src_next/event_lens.bqn"

tab ← @+9
Line ← {𝕊 fields: ∾ fields ∾¨ tab}
Snapshot ← {𝕊 jlines‿plines‿blines:
  {
    sources ⇐ ⟨
      {source_file⇐"journal.tsv", required⇐1, lines⇐jlines},
      {source_file⇐"plan.tsv", required⇐0, lines⇐plines},
      {source_file⇐"budget_alloc.tsv", required⇐0, lines⇐blines}
    ⟩
  }
}

resolved ← ak.Resolve ⟨
  "assets:bank"∾tab∾"role=asset",
  "expenses:food"∾tab∾"role=expense",
  "expenses:learning"∾tab∾"role=expense",
  "income:salary"∾tab∾"role=income"
⟩
cycleStart ← "2026-06-15"

# Helper to check a success lens result
CheckSuccessLens ← {𝕊 result:
  "ok" lib.AssertEq result.state
}

# 1. JPY row (normal)
s1 ← Snapshot ⟨
  ⟨Line ⟨"2026-06-15", "normal memo", "assets:bank", "expenses:food", "1200"⟩⟩,
  ⟨⟩,
  ⟨⟩
⟩
res1 ← ctx.BuildCheckedPostingProjectionFromSnapshot ⟨s1, resolved, cycleStart⟩
lens_res1 ← lens.BuildRows res1
CheckSuccessLens lens_res1
1 lib.AssertEq ≠ lens_res1.rows
row1 ← ⊑ lens_res1.rows
"journal.tsv" lib.AssertEq row1.source_file
0 lib.AssertEq row1.source_row
"normal memo" lib.AssertEq row1.source_id
"2026-06-15" lib.AssertEq row1.when_value
"direct" lib.AssertEq row1.when_state
"" lib.AssertEq row1.party_value
"absent" lib.AssertEq row1.party_state
"normal memo" lib.AssertEq row1.what_value
"ambiguous" lib.AssertEq row1.what_state
"assets:bank" lib.AssertEq row1.from_account
"expenses:food" lib.AssertEq row1.where_to_value
"direct" lib.AssertEq row1.where_to_state
"1200" lib.AssertEq row1.amount_text
1200 lib.AssertEq row1.amount_coefficient
0 lib.AssertEq row1.amount_scale
"JPY" lib.AssertEq row1.currency
"direct" lib.AssertEq row1.amount_state
"actual:expense" lib.AssertEq row1.action_value
"derived" lib.AssertEq row1.action_state
"actual" lib.AssertEq row1.layer
"expense" lib.AssertEq row1.kind

# 2. Explicit party=
s2 ← Snapshot ⟨
  ⟨Line ⟨"2026-06-15", "memo text", "assets:bank", "expenses:food", "1200", "party=StoreA"⟩⟩,
  ⟨⟩,
  ⟨⟩
⟩
res2 ← ctx.BuildCheckedPostingProjectionFromSnapshot ⟨s2, resolved, cycleStart⟩
lens_res2 ← lens.BuildRows res2
CheckSuccessLens lens_res2
row2 ← ⊑ lens_res2.rows
"StoreA" lib.AssertEq row2.party_value
"direct" lib.AssertEq row2.party_state

# 3. Party missing, memo present
s3 ← Snapshot ⟨
  ⟨Line ⟨"2026-06-15", "some description", "assets:bank", "expenses:food", "1200"⟩⟩,
  ⟨⟩,
  ⟨⟩
⟩
res3 ← ctx.BuildCheckedPostingProjectionFromSnapshot ⟨s3, resolved, cycleStart⟩
lens_res3 ← lens.BuildRows res3
CheckSuccessLens lens_res3
row3 ← ⊑ lens_res3.rows
"" lib.AssertEq row3.party_value
"absent" lib.AssertEq row3.party_state
"some description" lib.AssertEq row3.what_value
"ambiguous" lib.AssertEq row3.what_state

# 4. Empty memo
s4 ← Snapshot ⟨
  ⟨Line ⟨"2026-06-15", "", "assets:bank", "expenses:food", "1200"⟩⟩,
  ⟨⟩,
  ⟨⟩
⟩
res4 ← ctx.BuildCheckedPostingProjectionFromSnapshot ⟨s4, resolved, cycleStart⟩
lens_res4 ← lens.BuildRows res4
CheckSuccessLens lens_res4
row4 ← ⊑ lens_res4.rows
"" lib.AssertEq row4.what_value
"absent" lib.AssertEq row4.what_state

# 5. plan row and layer derived action
s5 ← Snapshot ⟨
  ⟨⟩,
  ⟨Line ⟨"2026-06-15", "plan exp", "assets:bank", "expenses:food", "1200"⟩⟩,
  ⟨⟩
⟩
res5 ← ctx.BuildCheckedPostingProjectionFromSnapshot ⟨s5, resolved, cycleStart⟩
lens_res5 ← lens.BuildRows res5
CheckSuccessLens lens_res5
row5 ← ⊑ lens_res5.rows
"plan.tsv" lib.AssertEq row5.source_file
"plan:expense" lib.AssertEq row5.action_value
"derived" lib.AssertEq row5.action_state
"plan" lib.AssertEq row5.layer
"expense" lib.AssertEq row5.kind

# 6. transfer row
s6 ← Snapshot ⟨
  ⟨Line ⟨"2026-06-15", "transfer memo", "assets:bank", "assets:bank", "1200"⟩⟩,
  ⟨⟩,
  ⟨⟩
⟩
res6 ← ctx.BuildCheckedPostingProjectionFromSnapshot ⟨s6, resolved, cycleStart⟩
lens_res6 ← lens.BuildRows res6
CheckSuccessLens lens_res6
row6 ← ⊑ lens_res6.rows
"actual:transfer" lib.AssertEq row6.action_value
"transfer" lib.AssertEq row6.kind

# 6b. income row
s6b ← Snapshot ⟨
  ⟨Line ⟨"2026-06-15", "salary memo", "income:salary", "assets:bank", "1200"⟩⟩,
  ⟨⟩,
  ⟨⟩
⟩
res6b ← ctx.BuildCheckedPostingProjectionFromSnapshot ⟨s6b, resolved, cycleStart⟩
lens_res6b ← lens.BuildRows res6b
CheckSuccessLens lens_res6b
row6b ← ⊑ lens_res6b.rows
"actual:income" lib.AssertEq row6b.action_value
"income" lib.AssertEq row6b.kind

# 7. all-ILS exact decimal result
s7 ← Snapshot ⟨
  ⟨
    Line ⟨"2026-06-15", "food", "assets:bank", "expenses:food", "1200", "currency=ILS"⟩,
    Line ⟨"2026-06-16", "book", "assets:bank", "expenses:learning", "42.50", "currency=ILS"⟩,
    Line ⟨"2026-06-17", "small", "assets:bank", "expenses:food", "0.05", "currency=ILS"⟩
  ⟩,
  ⟨⟩,
  ⟨⟩
⟩
res7 ← ctx.BuildCheckedPostingProjectionFromSnapshot ⟨s7, resolved, cycleStart⟩
lens_res7 ← lens.BuildRows res7
CheckSuccessLens lens_res7
3 lib.AssertEq ≠ lens_res7.rows

r7_0 ← 0 ⊑ lens_res7.rows
120000 lib.AssertEq r7_0.amount_coefficient
2 lib.AssertEq r7_0.amount_scale
"ILS" lib.AssertEq r7_0.currency

r7_1 ← 1 ⊑ lens_res7.rows
4250 lib.AssertEq r7_1.amount_coefficient
2 lib.AssertEq r7_1.amount_scale
"ILS" lib.AssertEq r7_1.currency

r7_2 ← 2 ⊑ lens_res7.rows
5 lib.AssertEq r7_2.amount_coefficient
2 lib.AssertEq r7_2.amount_scale
"ILS" lib.AssertEq r7_2.currency

# 8. failed checked result rejection
s8 ← Snapshot ⟨
  ⟨Line ⟨"2026-06-15", "malformed", "assets:bank", "expenses:food", "12x", "currency=JPY"⟩⟩,
  ⟨⟩,
  ⟨⟩
⟩
res8 ← ctx.BuildCheckedPostingProjectionFromSnapshot ⟨s8, resolved, cycleStart⟩
"error" lib.AssertEq res8.state
lens_res8 ← lens.BuildRows res8
"error" lib.AssertEq lens_res8.state

# 9 & 10. source row order, identity retention, 1-to-1 mapping
s9 ← Snapshot ⟨
  ⟨
    Line ⟨"2026-06-15", "first", "assets:bank", "expenses:food", "100"⟩,
    Line ⟨"2026-06-16", "second", "assets:bank", "expenses:food", "200"⟩
  ⟩,
  ⟨⟩,
  ⟨⟩
⟩
res9 ← ctx.BuildCheckedPostingProjectionFromSnapshot ⟨s9, resolved, cycleStart⟩
lens_res9 ← lens.BuildRows res9
CheckSuccessLens lens_res9
2 lib.AssertEq ≠ lens_res9.rows
"first" lib.AssertEq (0 ⊑ lens_res9.rows).what_value
"second" lib.AssertEq (1 ⊑ lens_res9.rows).what_value
0 lib.AssertEq (0 ⊑ lens_res9.rows).source_row
1 lib.AssertEq (1 ⊑ lens_res9.rows).source_row

•Out "All event lens tests passed!"
