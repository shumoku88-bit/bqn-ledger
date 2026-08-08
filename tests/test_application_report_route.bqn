#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
catalog ← •Import "../src/report/catalog.bqn"
route ← •Import "../src/application/report_route.bqn"

CheckOk ← {𝕊 key‿surface‿coordinates‿coordinateRoles‿argumentIndices‿kinds‿roles:
  result ← route.Admit ⟨key,surface,coordinates⟩
  "ok" lib.AssertEq result.state
  key lib.AssertEq result.key
  surface lib.AssertEq result.surface
  coordinates lib.AssertEq result.coordinates
  coordinateRoles lib.AssertEq result.coordinate_role
  argumentIndices lib.AssertEq result.sources.argument_index
  kinds lib.AssertEq result.sources.kind
  roles lib.AssertEq result.sources.role
  (argumentIndices⊏coordinates) lib.AssertEq result.sources.name
  0 lib.AssertEq ≠result.diagnostics
}

successCases ← ⟨
  ⟨"envelopes","human",⟨"JPY","2026-01-01","2026-02-01","2026-01-12","actual.journal","ignored-plan","ignored-budget","ignored-funding"⟩,
    ⟨"domain","start","end_exclusive","observation","actual_source","plan_source","budget_source","funding_account"⟩,⟨4⟩,⟨"canonical-journal"⟩,⟨"actual"⟩⟩,
  ⟨"balances","json",⟨"JPY","2026-01-12","actual.journal"⟩,⟨"domain","as_of","actual_source"⟩,⟨2⟩,⟨"canonical-journal"⟩,⟨"actual"⟩⟩,
  ⟨"balance-sheet","human",⟨"JPY","2026-01-12","actual.journal"⟩,⟨"domain","as_of","actual_source"⟩,⟨2⟩,⟨"canonical-journal"⟩,⟨"actual"⟩⟩,
  ⟨"profit-and-loss","human",⟨"JPY","2026-01-01","2026-02-01","actual.journal"⟩,⟨"domain","start","end_exclusive","actual_source"⟩,⟨3⟩,⟨"canonical-journal"⟩,⟨"actual"⟩⟩,
  ⟨"recent","compact",⟨"10","actual.journal"⟩,⟨"limit","actual_source"⟩,⟨1⟩,⟨"canonical-journal"⟩,⟨"actual"⟩⟩,
  ⟨"planned","human",⟨"2026-01-12","actual.journal","ignored-plan","ignored-cycle"⟩,⟨"observation","actual_source","plan_source","cycle_source"⟩,⟨1⟩,⟨"canonical-journal"⟩,⟨"actual"⟩⟩,
  ⟨"cycle-accounts","human",⟨"JPY","2026-01-12","actual.journal","ignored-cycle"⟩,⟨"domain","observation","actual_source","cycle_source"⟩,⟨2⟩,⟨"canonical-journal"⟩,⟨"actual"⟩⟩,
  ⟨"cycle-comparison","human",⟨"JPY","2026-01-12","2025-12-31","aligned_elapsed","actual.journal","ignored-current","ignored-baseline","ignored-plan"⟩,
    ⟨"domain","current_observation","baseline_observation","policy","actual_source","current_cycle_source","baseline_cycle_source","plan_source"⟩,⟨4⟩,⟨"canonical-journal"⟩,⟨"actual"⟩⟩,
  ⟨"monthly-accounts","human",⟨"JPY","2026-01","2026-03","actual.journal"⟩,⟨"domain","first_month","last_month_exclusive","actual_source"⟩,⟨3⟩,⟨"canonical-journal"⟩,⟨"actual"⟩⟩,
  ⟨"daily-flow","human",⟨"JPY","2026-01-01","2026-02-01","2026-01-12","actual.journal"⟩,⟨"domain","start","end_exclusive","observation","actual_source"⟩,⟨4⟩,⟨"canonical-journal"⟩,⟨"actual"⟩⟩,
  ⟨"daily-target","compact",⟨"JPY","2026-01-12","2026-01-22","actual.journal","ignored-plan","ignored-scope"⟩,⟨"domain","observation","target","actual_source","plan_source","daily_scope_source"⟩,⟨3⟩,⟨"canonical-journal"⟩,⟨"actual"⟩⟩,
  ⟨"issues","human",⟨"issues.tsv"⟩,⟨"issues_source"⟩,⟨0⟩,⟨"tsv"⟩,⟨"issues"⟩⟩
⟩

(catalog.Table @).key lib.AssertEq {⊑𝕩}¨successCases
CheckOk¨successCases

CheckOk ⟨"envelopes","human",⟨"JPY","2026-01-01","2026-02-01","2026-01-12","actual.journal","bad/plan","bad/budget","bad/funding","another"⟩,
  ⟨"domain","start","end_exclusive","observation","actual_source","plan_source","budget_source","funding_account","funding_account"⟩,⟨4⟩,⟨"canonical-journal"⟩,⟨"actual"⟩⟩
CheckOk ⟨"cycle-accounts","human",⟨"JPY","2026-01-12","actual.journal","bad/cycle","bad/plan"⟩,
  ⟨"domain","observation","actual_source","cycle_source","plan_source"⟩,⟨2⟩,⟨"canonical-journal"⟩,⟨"actual"⟩⟩
CheckOk ⟨"cycle-comparison","human",⟨"JPY","2026-01-12","2025-12-31","aligned_elapsed","actual.journal","bad/current","bad/baseline"⟩,
  ⟨"domain","current_observation","baseline_observation","policy","actual_source","current_cycle_source","baseline_cycle_source"⟩,⟨4⟩,⟨"canonical-journal"⟩,⟨"actual"⟩⟩

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
CheckError ⟨"recent","json",⟨"10","actual.journal"⟩,"report_surface_unsupported"⟩
CheckError ⟨"all","human",⟨"manifest.tsv"⟩,"report_route_all_unsupported"⟩
CheckError ⟨"envelopes","human",7⥊⟨"x"⟩,"usage_envelopes"⟩
CheckError ⟨"balances","human",⟨"JPY","2026-01-12"⟩,"usage_balances"⟩
CheckError ⟨"balances","human",4⥊⟨"x"⟩,"usage_balances"⟩
CheckError ⟨"balance-sheet","human",2⥊⟨"x"⟩,"usage_balance_sheet"⟩
CheckError ⟨"profit-and-loss","human",3⥊⟨"x"⟩,"usage_profit_and_loss"⟩
CheckError ⟨"recent","human",⟨"x","actual.journal"⟩,"limit_invalid"⟩
CheckError ⟨"recent","human",3⥊⟨"x"⟩,"usage_recent"⟩
CheckError ⟨"planned","human",3⥊⟨"x"⟩,"usage_planned"⟩
CheckError ⟨"cycle-accounts","human",3⥊⟨"x"⟩,"usage_cycle_accounts"⟩
CheckError ⟨"cycle-accounts","human",6⥊⟨"x"⟩,"usage_cycle_accounts"⟩
CheckError ⟨"cycle-comparison","human",6⥊⟨"x"⟩,"usage_cycle_comparison"⟩
CheckError ⟨"cycle-comparison","human",9⥊⟨"x"⟩,"usage_cycle_comparison"⟩
CheckError ⟨"monthly-accounts","human",3⥊⟨"x"⟩,"usage_monthly_accounts"⟩
CheckError ⟨"daily-flow","human",4⥊⟨"x"⟩,"usage_daily_flow"⟩
CheckError ⟨"daily-target","human",5⥊⟨"x"⟩,"usage_daily_target"⟩
CheckError ⟨"issues","human",⟨⟩,"usage_issues"⟩
CheckError ⟨"issues","human",2⥊⟨"x"⟩,"usage_issues"⟩

•Out "test_application_report_route: ok"
