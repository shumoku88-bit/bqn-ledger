#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
route ← •Import "../src/application/report_route.bqn"

cases ← ⟨
  ⟨"balances","json",⟨"JPY","2026-01-15"⟩⟩,
  ⟨"balance-sheet","human",⟨"JPY","2026-01-15"⟩⟩,
  ⟨"profit-and-loss","human",⟨"JPY","2026-01-01","2026-02-01"⟩⟩,
  ⟨"recent","compact",⟨"2026-01-15","3"⟩⟩,
  ⟨"monthly-accounts","human",⟨"JPY","2026-01","2026-02"⟩⟩,
  ⟨"daily-flow","human",⟨"JPY","2026-01-01","2026-02-01","2026-01-15"⟩⟩
⟩

{𝕊 key‿surface‿coordinates:
  admitted ← route.Admit ⟨key,surface,coordinates⟩
  "ok" lib.AssertEq admitted.state
  coordinates lib.AssertEq admitted.coordinates

  withPhysicalSource ← coordinates∾⟨"actual.journal"⟩
  rejected ← route.Admit ⟨key,surface,withPhysicalSource⟩
  "error" lib.AssertEq rejected.state
}¨cases

•Out "test_application_canonical_actual_report_route: ok"
