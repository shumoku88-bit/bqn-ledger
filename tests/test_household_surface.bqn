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

•Out "test_household_surface: ok"
