#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
catalog ← •Import "../src/report/catalog.bqn"
route ← •Import "../src/application/report_route.bqn"

CheckOk ← {𝕊 key‿surface‿coordinates‿coordinateRoles:
  result ← route.Admit ⟨key,surface,coordinates⟩
  "ok" lib.AssertEq result.state
  key lib.AssertEq result.key
  surface lib.AssertEq result.surface
  coordinates lib.AssertEq result.coordinates
  coordinateRoles lib.AssertEq result.coordinate_role
  0 lib.AssertEq result.sources.count
  0 lib.AssertEq ≠result.sources.name
  0 lib.AssertEq ≠result.diagnostics
}

successCases ← ⟨
  ⟨"envelopes","human",⟨"JPY","2026-01-01","2026-02-01","2026-01-12"⟩,⟨"domain","start","end_exclusive","observation"⟩⟩,
  ⟨"balances","json",⟨"JPY","2026-01-12"⟩,⟨"domain","as_of"⟩⟩,
  ⟨"balance-sheet","human",⟨"JPY","2026-01-12"⟩,⟨"domain","as_of"⟩⟩,
  ⟨"profit-and-loss","human",⟨"JPY","2026-01-01","2026-02-01"⟩,⟨"domain","start","end_exclusive"⟩⟩,
  ⟨"recent","compact",⟨"2026-01-12","10"⟩,⟨"through","limit"⟩⟩,
  ⟨"planned","human",⟨"2026-01-12"⟩,⟨"observation"⟩⟩,
  ⟨"cycle-accounts","human",⟨"JPY","2026-01-12"⟩,⟨"domain","observation"⟩⟩,
  ⟨"cycle-comparison","human",⟨"JPY","2026-01-12","2025-12-31","aligned_elapsed"⟩,⟨"domain","current_observation","baseline_observation","policy"⟩⟩,
  ⟨"monthly-accounts","human",⟨"JPY","2026-01","2026-03"⟩,⟨"domain","first_month","last_month_exclusive"⟩⟩,
  ⟨"daily-flow","human",⟨"JPY","2026-01-01","2026-02-01","2026-01-12"⟩,⟨"domain","start","end_exclusive","observation"⟩⟩,
  ⟨"daily-target","compact",⟨"JPY","2026-01-12","2026-01-22"⟩,⟨"domain","observation","target"⟩⟩,
  ⟨"issues","human",⟨⟩,⟨⟩⟩
⟩

(catalog.Table @).key lib.AssertEq {⊑𝕩}¨successCases
CheckOk¨successCases

HasCode ← {𝕊 code‿diagnostics: ∨´0∾code⊸≡¨{𝕩.code}¨diagnostics}
CheckError ← {𝕊 key‿surface‿coordinates‿code:
  result ← route.Admit ⟨key,surface,coordinates⟩
  "error" lib.AssertEq result.state
  "" lib.AssertEq result.key
  "" lib.AssertEq result.surface
  0 lib.AssertEq ≠result.coordinates
  0 lib.AssertEq ≠result.coordinate_role
  0 lib.AssertEq result.sources.count
  1 lib.AssertEq HasCode ⟨code,result.diagnostics⟩
}

CheckError ⟨"unknown","human",⟨⟩,"report_key_unknown"⟩
CheckError ⟨"recent","json",⟨"2026-01-12","10"⟩,"report_surface_unsupported"⟩
CheckError ⟨"all","human",⟨⟩,"report_route_all_unsupported"⟩
CheckError ⟨"envelopes","human",3⥊⟨"x"⟩,"usage_envelopes"⟩
CheckError ⟨"balances","human",⟨"JPY"⟩,"usage_balances"⟩
CheckError ⟨"balance-sheet","human",3⥊⟨"x"⟩,"usage_balance_sheet"⟩
CheckError ⟨"profit-and-loss","human",2⥊⟨"x"⟩,"usage_profit_and_loss"⟩
CheckError ⟨"recent","human",⟨"2026-01-12","x"⟩,"limit_invalid"⟩
CheckError ⟨"recent","human",3⥊⟨"x"⟩,"usage_recent"⟩
CheckError ⟨"planned","human",⟨⟩,"usage_planned"⟩
CheckError ⟨"cycle-accounts","human",3⥊⟨"x"⟩,"usage_cycle_accounts"⟩
CheckError ⟨"cycle-comparison","human",3⥊⟨"x"⟩,"usage_cycle_comparison"⟩
CheckError ⟨"monthly-accounts","human",2⥊⟨"x"⟩,"usage_monthly_accounts"⟩
CheckError ⟨"daily-flow","human",3⥊⟨"x"⟩,"usage_daily_flow"⟩
CheckError ⟨"daily-target","human",2⥊⟨"x"⟩,"usage_daily_target"⟩
CheckError ⟨"issues","human",⟨"issues.tsv"⟩,"usage_issues"⟩

•Out "test_application_report_route: ok"
