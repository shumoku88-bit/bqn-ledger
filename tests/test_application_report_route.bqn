#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
route ← •Import "../src/application/report_route.bqn"

CheckOk ← {𝕊 key‿surface‿coordinates‿argumentIndices‿kinds‿roles:
  result ← route.Admit ⟨key,surface,coordinates⟩
  "ok" lib.AssertEq result.state
  key lib.AssertEq result.key
  surface lib.AssertEq result.surface
  coordinates lib.AssertEq result.coordinates
  argumentIndices lib.AssertEq result.sources.argument_index
  kinds lib.AssertEq result.sources.kind
  roles lib.AssertEq result.sources.role
  (argumentIndices⊏coordinates) lib.AssertEq result.sources.name
  0 lib.AssertEq ≠result.diagnostics
}

CheckOk ⟨
  "envelopes","human",
  ⟨"JPY","2026-01-01","2026-02-01","2026-01-12","actual.journal","plan.tsv","budget_alloc.tsv","assets:cash"⟩,
  ⟨4,5,6⟩,⟨"journal","tsv","tsv"⟩,⟨"actual","plan","budget"⟩
⟩
CheckOk ⟨"balances","json",⟨"JPY","2026-01-12","actual.journal"⟩,⟨2⟩,⟨"journal"⟩,⟨"actual"⟩⟩
CheckOk ⟨"recent","compact",⟨"10","actual.journal"⟩,⟨1⟩,⟨"journal"⟩,⟨"actual"⟩⟩
CheckOk ⟨
  "planned","human",⟨"2026-01-12","actual.journal","plan.tsv","cycle.tsv"⟩,
  ⟨1,2,3⟩,⟨"journal","tsv","tsv"⟩,⟨"actual","plan","cycle"⟩
⟩
CheckOk ⟨
  "cycle-accounts","human",⟨"JPY","2026-01-12","actual.journal","cycle.tsv"⟩,
  ⟨2,3⟩,⟨"journal","tsv"⟩,⟨"actual","cycle"⟩
⟩
CheckOk ⟨
  "cycle-accounts","human",⟨"JPY","2026-01-12","actual.journal","cycle.tsv","plan.tsv"⟩,
  ⟨2,3,4⟩,⟨"journal","tsv","tsv"⟩,⟨"actual","cycle","plan"⟩
⟩
CheckOk ⟨
  "cycle-comparison","human",
  ⟨"JPY","2026-01-12","2025-12-31","aligned_elapsed","actual.journal","current.tsv","baseline.tsv","plan.tsv"⟩,
  ⟨4,5,6,7⟩,⟨"journal","tsv","tsv","tsv"⟩,⟨"actual","current_cycle","baseline_cycle","plan"⟩
⟩
CheckOk ⟨
  "monthly-accounts","human",⟨"JPY","2026-01","2026-03","actual.journal"⟩,
  ⟨3⟩,⟨"journal"⟩,⟨"actual"⟩
⟩
CheckOk ⟨
  "daily-target","compact",⟨"JPY","2026-01-12","2026-01-22","actual.journal","plan.tsv","scope.tsv"⟩,
  ⟨3,4,5⟩,⟨"journal","tsv","tsv"⟩,⟨"actual","plan","daily_scope"⟩
⟩
CheckOk ⟨"issues","human",⟨"issues.tsv"⟩,⟨0⟩,⟨"tsv"⟩,⟨"issues"⟩⟩

HasCode ← {𝕊 code‿diagnostics: ∨´0∾code⊸≡¨{𝕩.code}¨diagnostics}
CheckError ← {𝕊 key‿surface‿coordinates‿code:
  result ← route.Admit ⟨key,surface,coordinates⟩
  "error" lib.AssertEq result.state
  "" lib.AssertEq result.key
  "" lib.AssertEq result.surface
  0 lib.AssertEq ≠result.coordinates
  0 lib.AssertEq result.sources.count
  1 lib.AssertEq HasCode ⟨code,result.diagnostics⟩
}

CheckError ⟨"unknown","human",⟨⟩,"report_key_unknown"⟩
CheckError ⟨"recent","json",⟨"10","actual.journal"⟩,"report_surface_unsupported"⟩
CheckError ⟨"all","human",⟨"manifest.tsv"⟩,"report_route_all_unsupported"⟩
CheckError ⟨"envelopes","human",7⥊⟨"x"⟩,"usage_envelopes"⟩
CheckError ⟨"balances","human",⟨"JPY","2026-01-12"⟩,"usage_balances"⟩
CheckError ⟨"balances","human",4⥊⟨"x"⟩,"usage_balances"⟩
CheckError ⟨"recent","human",⟨"x","actual.journal"⟩,"limit_invalid"⟩
CheckError ⟨"recent","human",3⥊⟨"x"⟩,"usage_recent"⟩
CheckError ⟨"planned","human",3⥊⟨"x"⟩,"usage_planned"⟩
CheckError ⟨"cycle-accounts","human",3⥊⟨"x"⟩,"usage_cycle_accounts"⟩
CheckError ⟨"cycle-accounts","human",6⥊⟨"x"⟩,"usage_cycle_accounts"⟩
CheckError ⟨"cycle-comparison","human",6⥊⟨"x"⟩,"usage_cycle_comparison"⟩
CheckError ⟨"cycle-comparison","human",9⥊⟨"x"⟩,"usage_cycle_comparison"⟩
CheckError ⟨"monthly-accounts","human",3⥊⟨"x"⟩,"usage_monthly_accounts"⟩
CheckError ⟨"daily-target","human",5⥊⟨"x"⟩,"usage_daily_target"⟩
CheckError ⟨"issues","human",⟨⟩,"usage_issues"⟩
CheckError ⟨"issues","human",2⥊⟨"x"⟩,"usage_issues"⟩

•Out "test_application_report_route: ok"
