#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
snapshot ← •Import "legacy_snapshot_fixture.bqn"
cycle_result ← •Import "../src/accounting/cycle_result.bqn"
cycle_period ← •Import "../src/accounting/cycle_account_period.bqn"
comparison ← •Import "../src/accounting/cycle_comparison.bqn"

base ← "fixtures/ledger-facts-phase1-proof/"
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
lines ← loader.ReadLines base∾"accounts.tsv"
facts ← (snapshot.Build ⟨lines,•FChars "../"∾base∾"actual.journal",registry⟩).facts
Window ← {𝕊 start‿finish‿observation:
  resolved ← cycle_result.Success ⟨"fixed",observation,start,finish,⟨⟩,⟨⟩⟩
  cycle_period.Build ⟨facts,"JPY",resolved,observation⟩
}
current ← Window ⟨"2026-01-01","2026-02-01","2026-01-10"⟩
baseline ← Window ⟨"2025-12-22","2026-01-22","2025-12-31"⟩
result ← comparison.Build ⟨current,baseline,"aligned_elapsed"⟩
"ok" lib.AssertEq result.state
10 lib.AssertEq result.current_day_count
10 lib.AssertEq result.baseline_day_count
⟨980,¯1000,20,0,0,0,0⟩ lib.AssertEq result.accounts.current_movement
(7⥊0) lib.AssertEq result.accounts.baseline_movement
result.accounts.current_movement lib.AssertEq result.accounts.difference
1 lib.AssertEq result.totals.balanced
"actual.journal" lib.AssertEq (⊑0⊑result.accounts.current_contributors).source
980 lib.AssertEq (0⊑result.accounts.difference_evidence).current_coefficient
0 lib.AssertEq (0⊑result.accounts.difference_evidence).baseline_coefficient

completeCurrent ← Window ⟨"2026-01-01","2026-02-01","2026-01-31"⟩
completeBaseline ← Window ⟨"2026-02-01","2026-03-01","2026-02-28"⟩
complete ← comparison.Build ⟨completeCurrent,completeBaseline,"complete_cycles"⟩
"ok" lib.AssertEq complete.state
31 lib.AssertEq complete.current_day_count
28 lib.AssertEq complete.baseline_day_count
⟨965,¯1000,30,5,0,0,0⟩ lib.AssertEq complete.accounts.difference

misalignedBaseline ← Window ⟨"2025-12-22","2026-01-22","2025-12-30"⟩
misaligned ← comparison.Build ⟨current,misalignedBaseline,"aligned_elapsed"⟩
"error" lib.AssertEq misaligned.state
0 lib.AssertEq misaligned.accounts.count
"aligned_elapsed_day_count_mismatch" lib.AssertEq (⊑misaligned.diagnostics).code
incomplete ← comparison.Build ⟨current,baseline,"complete_cycles"⟩
"error" lib.AssertEq incomplete.state
"complete_cycle_required" lib.AssertEq (⊑incomplete.diagnostics).code
invalid ← comparison.Build ⟨current,baseline,"similar_period"⟩
"error" lib.AssertEq invalid.state
"comparison_policy_invalid" lib.AssertEq (⊑invalid.diagnostics).code

unavailableWindow ← cycle_period.Build ⟨facts,"JPY",cycle_result.Unavailable ⟨"incomeAnchor","2026-01-10","anchor_missing"⟩,"2026-01-10"⟩
unavailable ← comparison.Build ⟨current,unavailableWindow,"aligned_elapsed"⟩
"unavailable" lib.AssertEq unavailable.state
"baseline_window_unavailable:anchor_missing" lib.AssertEq unavailable.reason
0 lib.AssertEq unavailable.accounts.count

lf ← @+10
usdLines ← ⟨"assets:usd	role=asset	currency=USD","expenses:usd	role=expense	currency=USD"⟩
usdRaw ← ∾⟨"commodity USD",lf,lf,"account assets:usd",lf,"    ; role: asset",lf,lf,"account expenses:usd",lf,"    ; role: expense",lf⟩
usdFacts ← (snapshot.Build ⟨usdLines,usdRaw,registry⟩).facts
UsdWindow ← {𝕊 start‿finish‿observation:
  cycle_period.Build ⟨usdFacts,"USD",cycle_result.Success ⟨"fixed",observation,start,finish,⟨⟩,⟨⟩⟩,observation⟩
}
usdCurrent ← UsdWindow ⟨"2026-03-01","2026-04-01","2026-03-10"⟩
usdBaseline ← UsdWindow ⟨"2026-02-01","2026-03-01","2026-02-10"⟩
emptyComparison ← comparison.Build ⟨usdCurrent,usdBaseline,"aligned_elapsed"⟩
"ok" lib.AssertEq emptyComparison.state
⟨0,0⟩ lib.AssertEq emptyComparison.accounts.difference
mixedDomain ← comparison.Build ⟨current,usdBaseline,"aligned_elapsed"⟩
"error" lib.AssertEq mixedDomain.state
lib.Assert ∨´"comparison_domain_mismatch"⊸≡¨{𝕩.code}¨mixedDomain.diagnostics

ref ← {source⇐"actual.journal",posting_id⇐"p",transaction_id⇐"t"}
Synthetic ← {𝕊 scaleValue‿movementValues:
  {
    state⇐"ok",reason⇐"",domain⇐"ILS",observation⇐"2026-03-01",cycle_mode⇐"fixed",
    cycle_start⇐"2026-03-01",cycle_end_exclusive⇐"2026-03-02",observed_end_exclusive_ordinal⇐738947,
    scale⇐scaleValue,
    accounts⇐{
      count⇐2,index⇐⟨0,1⟩,account_index⇐⟨0,1⟩,account_key⇐⟨"assets:ils","expenses:ils"⟩,
      movement⇐movementValues,movement_contributors⇐⟨⟨ref⟩,⟨ref⟩⟩
    },diagnostics⇐⟨⟩
  }
}
scaledCurrent ← Synthetic ⟨2,⟨¯1235,1235⟩⟩
scaledBaseline ← Synthetic ⟨1,⟨¯100,100⟩⟩
scaled ← comparison.Build ⟨scaledCurrent,scaledBaseline,"aligned_elapsed"⟩
"ok" lib.AssertEq scaled.state
2 lib.AssertEq scaled.scale
⟨¯235,235⟩ lib.AssertEq scaled.accounts.difference
•Out "test_accounting_cycle_comparison: ok"
