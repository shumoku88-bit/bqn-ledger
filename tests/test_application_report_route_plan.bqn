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
  ⟨"envelopes","human","JPY","2026-01-01","2026-02-01","2026-01-12"⟩,
  0,⟨"ROUTE"∾tab∾"envelopes"∾tab∾"human"∾tab∾"4"⟩
⟩
Check ⟨
  ⟨"cycle-accounts","human","JPY","2026-01-12"⟩,
  0,⟨"ROUTE"∾tab∾"cycle-accounts"∾tab∾"human"∾tab∾"2"⟩
⟩
Check ⟨
  ⟨"daily-target","human","JPY","2026-01-12","2026-01-22"⟩,
  0,⟨"ROUTE"∾tab∾"daily-target"∾tab∾"human"∾tab∾"3"⟩
⟩
Check ⟨
  ⟨"profit-and-loss","human","JPY","2026-01-01","2026-02-01"⟩,
  0,⟨"ROUTE"∾tab∾"profit-and-loss"∾tab∾"human"∾tab∾"3"⟩
⟩
Check ⟨
  ⟨"daily-flow","human","JPY","2026-01-01","2026-02-01","2026-01-12"⟩,
  0,⟨"ROUTE"∾tab∾"daily-flow"∾tab∾"human"∾tab∾"4"⟩
⟩

Check ⟨⟨"recent","human","2026-01-12","nope"⟩,1,⟨"ERROR"∾tab∾"limit_invalid"∾tab∾"LIMIT must be decimal digits"⟩⟩
Check ⟨⟨"all","human"⟩,1,⟨"ERROR"∾tab∾"report_route_all_unsupported"∾tab∾"all is a request-set selection, not one individual route"⟩⟩
Check ⟨⟨⟩,2,⟨"ERROR"∾tab∾"usage"∾tab∾"expected KEY SURFACE [COORDINATE...]"⟩⟩

•Out "test_application_report_route_plan: ok"
