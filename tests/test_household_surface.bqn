#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
surface ← •Import "../src/application/household_surface.bqn"
reports ← •Import "../src/report/catalog.bqn"

table ← surface.Table @
24 lib.AssertEq table.count
⟨"actual","plan","envelope","account","issue","household"⟩ lib.AssertEq (surface.Domains @).key
⟨"observe","add","change","resolve"⟩ lib.AssertEq (surface.Operations @).key

1 lib.AssertEq (surface.Find ⟨"actual","observe"⟩).enabled
0 lib.AssertEq (surface.Find ⟨"actual","change"⟩).enabled
1 lib.AssertEq (surface.Find ⟨"actual","resolve"⟩).enabled
1 lib.AssertEq (surface.Find ⟨"plan","change"⟩).enabled
1 lib.AssertEq (surface.Find ⟨"plan","resolve"⟩).enabled
1 lib.AssertEq (surface.Find ⟨"envelope","add"⟩).enabled
0 lib.AssertEq (surface.Find ⟨"envelope","change"⟩).enabled
1 lib.AssertEq (surface.Find ⟨"issue","resolve"⟩).enabled
1 lib.AssertEq (surface.Find ⟨"household","observe"⟩).enabled
0 lib.AssertEq (surface.Find ⟨"household","add"⟩).enabled
"unknown" lib.AssertEq (surface.Find ⟨"missing","observe"⟩).state

reportTable ← reports.Table @
12 lib.AssertEq reportTable.count
1 lib.AssertEq ∧´reportTable.surface_domain∊⟨"actual","plan","envelope","account","issue","household"⟩
1 lib.AssertEq ∧´reportTable.surface_scope∊⟨"day","recent","current","future","cycle","month"⟩

actions ← surface.Actions @
31 lib.AssertEq actions.count
actualAdd ← surface.ActionsFor ⟨"actual","add"⟩
4 lib.AssertEq actualAdd.count
⟨"expense","income","move","multi"⟩ lib.AssertEq actualAdd.action_key
planObserve ← surface.ActionsFor ⟨"plan","observe"⟩
5 lib.AssertEq planObserve.count
1 lib.AssertEq "planned"∊planObserve.action_key
accountObserve ← surface.ActionsFor ⟨"account","observe"⟩
5 lib.AssertEq accountObserve.count
1 lib.AssertEq "monthly-accounts"∊accountObserve.action_key
householdObserve ← surface.ActionsFor ⟨"household","observe"⟩
4 lib.AssertEq householdObserve.count
1 lib.AssertEq "daily-target"∊householdObserve.action_key
0 lib.AssertEq (surface.ActionsFor ⟨"household","add"⟩).count

•Out "test_household_surface: ok"
