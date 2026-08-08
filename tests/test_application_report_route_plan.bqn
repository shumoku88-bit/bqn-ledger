#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
app ← •Import "../src/application/report_route_plan.bqn"
tab ← @+9

Check ← {𝕊 args‿exitCode‿lines:
  result ← app.Run args
  exitCode lib.AssertEq result.exit_code
  lines lib.AssertEq result.lines
}

Check ⟨
  ⟨"envelopes","human","JPY","2026-01-01","2026-02-01","2026-01-12","actual.journal","ignored-plan","ignored-budget","ignored-funding"⟩,
  0,
  ⟨"ROUTE"∾tab∾"envelopes"∾tab∾"human"∾tab∾"8"∾tab∾"1",
    "SOURCE"∾tab∾"4"∾tab∾"canonical-journal"∾tab∾"actual"⟩
⟩

Check ⟨
  ⟨"cycle-accounts","human","JPY","2026-01-12","actual.journal","ignored-cycle","ignored-plan"⟩,
  0,
  ⟨"ROUTE"∾tab∾"cycle-accounts"∾tab∾"human"∾tab∾"5"∾tab∾"1",
    "SOURCE"∾tab∾"2"∾tab∾"canonical-journal"∾tab∾"actual"⟩
⟩

Check ⟨
  ⟨"daily-target","human","JPY","2026-01-12","2026-01-22","actual.journal","ignored-plan","ignored-scope"⟩,
  0,
  ⟨"ROUTE"∾tab∾"daily-target"∾tab∾"human"∾tab∾"6"∾tab∾"1",
    "SOURCE"∾tab∾"3"∾tab∾"canonical-journal"∾tab∾"actual"⟩
⟩

Check ⟨
  ⟨"profit-and-loss","human","JPY","2026-01-01","2026-02-01","actual.journal"⟩,
  0,
  ⟨"ROUTE"∾tab∾"profit-and-loss"∾tab∾"human"∾tab∾"4"∾tab∾"1",
    "SOURCE"∾tab∾"3"∾tab∾"canonical-journal"∾tab∾"actual"⟩
⟩

Check ⟨
  ⟨"daily-flow","human","JPY","2026-01-01","2026-02-01","2026-01-12","actual.journal"⟩,
  0,
  ⟨"ROUTE"∾tab∾"daily-flow"∾tab∾"human"∾tab∾"5"∾tab∾"1",
    "SOURCE"∾tab∾"4"∾tab∾"canonical-journal"∾tab∾"actual"⟩
⟩

Check ⟨⟨"recent","human","nope","actual.journal"⟩,1,⟨"ERROR"∾tab∾"limit_invalid"∾tab∾"LIMIT must be decimal digits"⟩⟩
Check ⟨⟨"all","human","manifest.tsv"⟩,1,⟨"ERROR"∾tab∾"report_route_all_unsupported"∾tab∾"all is a manifest-level selection, not one individual route"⟩⟩
Check ⟨⟨⟩,2,⟨"ERROR"∾tab∾"usage"∾tab∾"expected KEY SURFACE [COORDINATE...]"⟩⟩

•Out "test_application_report_route_plan: ok"
