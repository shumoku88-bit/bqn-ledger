#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ak ← •Import "../src_next/account_key.bqn"
selected ← •Import "../src_next/selected_domain_context.bqn"
balances ← •Import "../src_next/balances.bqn"

lf ← @+10
tab ← @+9
empty ← ⟨⟩
MakeRaw ← {𝕊 lines: ∾ lines ∾¨ lf}
Source ← {𝕊 file‿lines: {source_file⇐file, required⇐0, lines⇐lines}}
MakeSnapshot ← {𝕊 plan‿budget: {sources⇐⟨Source ⟨"plan.tsv", plan⟩, Source ⟨"budget_alloc.tsv", budget⟩⟩}}
HasCode ← {𝕊 code‿result: ∨´ 0 ∾ {code≡𝕩.code}¨result.diagnostics}

resolved ← ak.Resolve ⟨
  "assets:bank-jpy"∾tab∾"role=asset"∾tab∾"type=liquid"∾tab∾"currency=JPY",
  "expenses:food-jpy"∾tab∾"role=expense"∾tab∾"currency=JPY",
  "budget:pool-jpy"∾tab∾"role=budget"∾tab∾"currency=JPY",
  "budget:daily-jpy"∾tab∾"role=budget"∾tab∾"currency=JPY",
  "assets:cash-ils"∾tab∾"role=asset"∾tab∾"type=liquid"∾tab∾"currency=ILS",
  "expenses:food-ils"∾tab∾"role=expense"∾tab∾"currency=ILS",
  "budget:pool-ils"∾tab∾"role=budget"∾tab∾"currency=ILS",
  "budget:daily-ils"∾tab∾"role=budget"∾tab∾"currency=ILS",
  "assets:cash-usd"∾tab∾"role=asset"∾tab∾"type=liquid"∾tab∾"currency=USD",
  "expenses:food-usd"∾tab∾"role=expense"∾tab∾"currency=USD",
  "budget:pool-usd"∾tab∾"role=budget"∾tab∾"currency=USD",
  "budget:daily-usd"∾tab∾"role=budget"∾tab∾"currency=USD"
⟩

raw ← MakeRaw ⟨
  "commodity JPY", "", "commodity ILS", "",
  "account assets:bank-jpy", "", "account expenses:food-jpy", "",
  "account assets:cash-ils", "", "account expenses:food-ils", "",
  "2026-07-02 * synthetic JPY expense", "  ; event-id: selected-jpy-1",
  "  assets:bank-jpy  -800 JPY", "  expenses:food-jpy  800 JPY", "",
  "2026-07-03 * synthetic ILS expense", "  ; event-id: selected-ils-1",
  "  assets:cash-ils  -12.34 ILS", "  expenses:food-ils  12.34 ILS"
⟩

plan ← ⟨
  "2026-07-10"∾tab∾"jpy plan"∾tab∾"assets:bank-jpy"∾tab∾"expenses:food-jpy"∾tab∾"100"∾tab∾"currency=JPY",
  "2026-07-11"∾tab∾"ils plan"∾tab∾"assets:cash-ils"∾tab∾"expenses:food-ils"∾tab∾"2.50"∾tab∾"currency=ILS",
  "2026-07-12"∾tab∾"usd plan"∾tab∾"assets:cash-usd"∾tab∾"expenses:food-usd"∾tab∾"3.50"∾tab∾"currency=USD"
⟩
budget ← ⟨
  "2026-07-01"∾tab∾"jpy budget"∾tab∾"budget:pool-jpy"∾tab∾"budget:daily-jpy"∾tab∾"50"∾tab∾"currency=JPY",
  "2026-07-01"∾tab∾"ils budget"∾tab∾"budget:pool-ils"∾tab∾"budget:daily-ils"∾tab∾"1.25"∾tab∾"currency=ILS",
  "2026-07-01"∾tab∾"usd budget"∾tab∾"budget:pool-usd"∾tab∾"budget:daily-usd"∾tab∾"0.75"∾tab∾"currency=USD"
⟩
cy ← {mode⇐"fixed", start⇐"2026-07-01", end_exclusive⇐"2026-08-01", day_count⇐31}
inputSnapshot ← MakeSnapshot ⟨plan, budget⟩

ils ← selected.BuildFromPrepared ⟨"ILS", raw, resolved, cy, "synthetic.journal", inputSnapshot⟩
"ok" lib.AssertEq ils.state
"ILS" lib.AssertEq ils.selected_currency
2 lib.AssertEq ils.calculation_scale
6 lib.AssertEq ≠ils.posting_rows
lib.Assert ∧´ "ILS"⊸≡¨{𝕩.domain}¨ils.posting_rows
lib.Assert ¬∨´0∾"JPY"⊸≡¨{𝕩.domain}¨ils.posting_rows
lib.Assert ∧´ 2⊸=¨{𝕩.calculation_scale}¨ils.posting_rows
ilsEntries ← balances.Build ils
cashIls ← ({(0⊑𝕩)≡"assets:cash-ils/ILS"}¨ilsEntries)/ilsEntries
expenseIls ← ({(0⊑𝕩)≡"expenses:food-ils/ILS"}¨ilsEntries)/ilsEntries
1 lib.AssertEq ≠cashIls
1 lib.AssertEq ≠expenseIls
¯1234 lib.AssertEq 1⊑⊑cashIls
1234 lib.AssertEq 1⊑⊑expenseIls

jpy ← selected.BuildFromPrepared ⟨"JPY", raw, resolved, cy, "synthetic.journal", inputSnapshot⟩
"ok" lib.AssertEq jpy.state
"JPY" lib.AssertEq jpy.selected_currency
0 lib.AssertEq jpy.calculation_scale
6 lib.AssertEq ≠jpy.posting_rows
lib.Assert ∧´ "JPY"⊸≡¨{𝕩.domain}¨jpy.posting_rows
jpyEntries ← balances.Build jpy
bankJpy ← ({(0⊑𝕩)≡"assets:bank-jpy/JPY"}¨jpyEntries)/jpyEntries
¯800 lib.AssertEq 1⊑⊑bankJpy

# A declaration-only Journal is a valid empty Actual source for every supported
# selected domain. Plan and budget rows still construct the selected context.
emptyActualRaw ← MakeRaw ⟨
  "commodity JPY", "", "commodity ILS", "", "commodity USD", "",
  "account assets:bank-jpy", "", "account expenses:food-jpy", "",
  "account assets:cash-ils", "", "account expenses:food-ils", "",
  "account assets:cash-usd", "", "account expenses:food-usd"
⟩
{𝕊 currency:
  planOnly ← selected.BuildFromPrepared ⟨currency, emptyActualRaw, resolved, cy, "empty.journal", inputSnapshot⟩
  "ok" lib.AssertEq planOnly.state
  0 lib.AssertEq ≠ planOnly.actual_transactions
  4 lib.AssertEq ≠ planOnly.posting_rows
  lib.Assert ∧´ currency⊸≡¨{𝕩.domain}¨planOnly.posting_rows
}¨ ⟨"JPY", "ILS", "USD"⟩

# With no Actual, plan, or budget, every supported currency returns the same
# normal empty context rather than a currency-specific fallback or error.
{𝕊 currency:
  emptyContext ← selected.BuildFromPrepared ⟨currency, emptyActualRaw, resolved, cy, "empty.journal", MakeSnapshot ⟨empty,empty⟩⟩
  "ok" lib.AssertEq emptyContext.state
  0 lib.AssertEq ≠ emptyContext.actual_transactions
  0 lib.AssertEq ≠ emptyContext.posting_rows
  0 lib.AssertEq emptyContext.calculation_scale
}¨ ⟨"JPY", "ILS", "USD"⟩

# Actual evidence in another currency does not enter the selected domain. The
# selected plan and budget remain usable even when selected Actual is absent.
jpyOnlyRaw ← MakeRaw ⟨
  "commodity JPY", "", "account assets:bank-jpy", "", "account expenses:food-jpy", "",
  "2026-07-02 * JPY only", "  assets:bank-jpy  -800 JPY", "  expenses:food-jpy  800 JPY"
⟩
ilsWithoutActual ← selected.BuildFromPrepared ⟨"ILS", jpyOnlyRaw, resolved, cy, "jpy-only.journal", inputSnapshot⟩
"ok" lib.AssertEq ilsWithoutActual.state
0 lib.AssertEq ≠ ilsWithoutActual.actual_transactions
4 lib.AssertEq ≠ ilsWithoutActual.posting_rows
lib.Assert ∧´ "ILS"⊸≡¨{𝕩.domain}¨ilsWithoutActual.posting_rows

ilsOnlyRaw ← MakeRaw ⟨
  "commodity ILS", "", "account assets:cash-ils", "", "account expenses:food-ils", "",
  "2026-07-03 * ILS only", "  assets:cash-ils  -12.34 ILS", "  expenses:food-ils  12.34 ILS"
⟩
jpyWithoutActual ← selected.BuildFromPrepared ⟨"JPY", ilsOnlyRaw, resolved, cy, "ils-only.journal", inputSnapshot⟩
"ok" lib.AssertEq jpyWithoutActual.state
0 lib.AssertEq ≠ jpyWithoutActual.actual_transactions
4 lib.AssertEq ≠ jpyWithoutActual.posting_rows
lib.Assert ∧´ "JPY"⊸≡¨{𝕩.domain}¨jpyWithoutActual.posting_rows

# A selected non-actual row whose accounts prove another domain rejects the
# complete context and returns no partial rows.
badPlan ← ⟨"2026-07-10"∾tab∾"bad domain"∾tab∾"assets:bank-jpy"∾tab∾"expenses:food-jpy"∾tab∾"1.25"∾tab∾"currency=ILS"⟩
badDomain ← selected.BuildFromPrepared ⟨"ILS", raw, resolved, cy, "synthetic.journal", MakeSnapshot ⟨badPlan, empty⟩⟩
"error" lib.AssertEq badDomain.state
lib.Assert HasCode ⟨"nonactual_account_currency_mismatch", badDomain⟩
0 lib.AssertEq ≠badDomain.posting_rows

# Excess precision is rejected by production admission; no valid transaction or
# partial selected context escapes.
badRaw ← MakeRaw ⟨
  "commodity ILS", "", "account assets:cash-ils", "", "account expenses:food-ils", "",
  "2026-07-03 * excessive precision", "  assets:cash-ils  -1.001 ILS", "  expenses:food-ils  1.001 ILS"
⟩
badScale ← selected.BuildFromPrepared ⟨"ILS", badRaw, resolved, cy, "bad.journal", MakeSnapshot ⟨empty,empty⟩⟩
"error" lib.AssertEq badScale.state
lib.Assert HasCode ⟨"posting_precision_exceeded", badScale⟩
0 lib.AssertEq ≠badScale.posting_rows
badNormalization ← selected.NormalizeCoefficient ⟨123, 2, 1⟩
lib.Assert ¬badNormalization.valid

# One invalid transaction suppresses an otherwise valid selected transaction.
partialRaw ← MakeRaw ⟨
  "commodity JPY", "", "commodity ILS", "",
  "account assets:bank-jpy", "", "account expenses:food-jpy", "",
  "account assets:cash-ils", "", "account expenses:food-ils", "",
  "2026-07-02 * valid JPY", "  assets:bank-jpy  -1 JPY", "  expenses:food-jpy  1 JPY", "",
  "2026-07-03 * invalid ILS", "  assets:cash-ils  -1.001 ILS", "  expenses:food-ils  1.001 ILS"
⟩
partial ← selected.BuildFromPrepared ⟨"JPY",partialRaw,resolved,cy,"partial.journal",MakeSnapshot ⟨empty,empty⟩⟩
"error" lib.AssertEq partial.state
0 lib.AssertEq ≠partial.posting_rows

# Identical account text in independent currency coordinates remains distinct;
# no selected context can manufacture a shared amount coordinate.
sameJpyResolved ← ak.Resolve ⟨"assets:cash"∾tab∾"role=asset"∾tab∾"currency=JPY", "expenses:food"∾tab∾"role=expense"∾tab∾"currency=JPY"⟩
sameIlsResolved ← ak.Resolve ⟨"assets:cash"∾tab∾"role=asset"∾tab∾"currency=ILS", "expenses:food"∾tab∾"role=expense"∾tab∾"currency=ILS"⟩
sameUsdResolved ← ak.Resolve ⟨"assets:cash"∾tab∾"role=asset"∾tab∾"currency=USD", "expenses:food"∾tab∾"role=expense"∾tab∾"currency=USD"⟩
sameJpyRaw ← MakeRaw ⟨"commodity JPY","","account assets:cash","","account expenses:food","","2026-07-01 * same name JPY","  assets:cash  -1 JPY","  expenses:food  1 JPY"⟩
sameIlsRaw ← MakeRaw ⟨"commodity ILS","","account assets:cash","","account expenses:food","","2026-07-01 * same name ILS","  assets:cash  -1 ILS","  expenses:food  1 ILS"⟩
sameUsdRaw ← MakeRaw ⟨"commodity USD","","account assets:cash","","account expenses:food","","2026-07-01 * same name USD","  assets:cash  -1.25 USD","  expenses:food  1.25 USD"⟩
sameJpy ← selected.BuildFromPrepared ⟨"JPY",sameJpyRaw,sameJpyResolved,cy,"jpy.journal",MakeSnapshot ⟨empty,empty⟩⟩
sameIls ← selected.BuildFromPrepared ⟨"ILS",sameIlsRaw,sameIlsResolved,cy,"ils.journal",MakeSnapshot ⟨empty,empty⟩⟩
sameUsd ← selected.BuildFromPrepared ⟨"USD",sameUsdRaw,sameUsdResolved,cy,"usd.journal",MakeSnapshot ⟨empty,empty⟩⟩
"ok" lib.AssertEq sameJpy.state
"ok" lib.AssertEq sameIls.state
"ok" lib.AssertEq sameUsd.state
2 lib.AssertEq ≠sameJpy.posting_rows
2 lib.AssertEq ≠sameIls.posting_rows
2 lib.AssertEq ≠sameUsd.posting_rows
"assets:cash/JPY" lib.AssertEq (0⊑sameJpy.posting_rows).account_key
"assets:cash/ILS" lib.AssertEq (0⊑sameIls.posting_rows).account_key
"assets:cash/USD" lib.AssertEq (0⊑sameUsd.posting_rows).account_key

•Out "test_src_next_selected_domain_context.bqn: OK"
