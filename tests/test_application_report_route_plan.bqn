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
  ⟨
    "envelopes","human","JPY","2026-01-01","2026-02-01","2026-01-12",
    "actual.journal","plan.tsv","budget_alloc.tsv","assets:cash"
  ⟩,
  0,
  ⟨
    "ROUTE"∾tab∾"envelopes"∾tab∾"human"∾tab∾"8"∾tab∾"3",
    "SOURCE"∾tab∾"4"∾tab∾"journal"∾tab∾"actual",
    "SOURCE"∾tab∾"5"∾tab∾"tsv"∾tab∾"plan",
    "SOURCE"∾tab∾"6"∾tab∾"tsv"∾tab∾"budget"
  ⟩
⟩

Check ⟨
  ⟨"cycle-accounts","human","JPY","2026-01-12","actual.journal","cycle.tsv","plan.tsv"⟩,
  0,
  ⟨
    "ROUTE"∾tab∾"cycle-accounts"∾tab∾"human"∾tab∾"5"∾tab∾"3",
    "SOURCE"∾tab∾"2"∾tab∾"journal"∾tab∾"actual",
    "SOURCE"∾tab∾"3"∾tab∾"tsv"∾tab∾"cycle",
    "SOURCE"∾tab∾"4"∾tab∾"tsv"∾tab∾"plan"
  ⟩
⟩

Check ⟨
  ⟨"recent","human","nope","actual.journal"⟩,
  1,
  ⟨"ERROR"∾tab∾"limit_invalid"∾tab∾"LIMIT must be decimal digits"⟩
⟩

Check ⟨
  ⟨"all","human","manifest.tsv"⟩,
  1,
  ⟨"ERROR"∾tab∾"report_route_all_unsupported"∾tab∾"all is a manifest-level selection, not one individual route"⟩
⟩

Check ⟨
  ⟨⟩,
  2,
  ⟨"ERROR"∾tab∾"usage"∾tab∾"expected KEY SURFACE [COORDINATE...]"⟩
⟩

•Out "test_application_report_route_plan: ok"
