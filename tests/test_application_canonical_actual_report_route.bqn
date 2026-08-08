#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
route ← •Import "../src/application/report_route.bqn"

cases ← ⟨
  ⟨"balances","json",⟨"JPY","2026-01-15","actual.journal"⟩⟩,
  ⟨"balance-sheet","human",⟨"JPY","2026-01-15","actual.journal"⟩⟩,
  ⟨"profit-and-loss","human",⟨"JPY","2026-01-01","2026-02-01","actual.journal"⟩⟩,
  ⟨"recent","compact",⟨"3","actual.journal"⟩⟩,
  ⟨"monthly-accounts","human",⟨"JPY","2026-01","2026-02","actual.journal"⟩⟩,
  ⟨"daily-flow","human",⟨"JPY","2026-01-01","2026-02-01","2026-01-15","actual.journal"⟩⟩
⟩

{𝕊 key‿surface‿coordinates:
  admitted ← route.Admit ⟨key,surface,coordinates⟩
  "ok" lib.AssertEq admitted.state
  ⟨"actual"⟩ lib.AssertEq admitted.sources.role
  ⟨"actual.journal"⟩ lib.AssertEq admitted.sources.name

  rejectedCoordinates ← (¯1↓coordinates) ∾ ⟨"legacy.journal"⟩
  rejected ← route.Admit ⟨key,surface,rejectedCoordinates⟩
  "error" lib.AssertEq rejected.state
  "actual_source_not_canonical" lib.AssertEq (⊑rejected.diagnostics).code
}¨cases

•Out "test_application_canonical_actual_report_route: ok"
