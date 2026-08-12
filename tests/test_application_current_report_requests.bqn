#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
builder ← •Import "../src/application/current_report_requests.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"

reportPlan ← {
  state⇐"ok",
  trial_balance⇐{as_of⇐"2026-01-20"},
  balance_sheet⇐{as_of⇐"2026-01-20"},
  profit_and_loss⇐{from⇐"2026-01-01",through⇐"2026-01-20"},
  daily_flow⇐{from⇐"2026-01-01",through⇐"2026-01-20",max_date_columns⇐5},
  monthly_accounts⇐{from⇐"2025-12-15",through⇐"2026-01-20"},
  recent_transactions⇐{through⇐"2026-01-20",count⇐5},
  presentation⇐{negative_style⇐"minus",negative_color⇐"red",daily_flow_max_date_columns⇐5}
}
facts ← {
  domains⇐{index⇐⟨0,1⟩,code⇐⟨"JPY","USD"⟩},
  transactions⇐{
    domain_index⇐⟨0,0,1,0⟩,
    date_ordinal⇐dates.Ordinal¨⟨"2026-01-02","2026-01-18","2026-01-19","2026-02-01"⟩
  }
}
current ← {
  state⇐"ok",start⇐"2026-01-01",end_exclusive⇐"2026-02-01",
  start_ordinal⇐dates.Ordinal "2026-01-01",end_exclusive_ordinal⇐dates.Ordinal "2026-02-01"
}
baseline ← {
  state⇐"ok",start⇐"2025-12-01",end_exclusive⇐"2026-01-01",
  start_ordinal⇐dates.Ordinal "2025-12-01",end_exclusive_ordinal⇐dates.Ordinal "2026-01-01"
}

result ← builder.Build ⟨"JPY","human",reportPlan,facts,"2026-01-20",current,baseline⟩
"ok" lib.AssertEq result.state
0 lib.AssertEq ≠result.diagnostics
12 lib.AssertEq ≠result.rows

Find ← {𝕊 key:⊑(key⊸≡¨{𝕩.key}¨result.rows)/result.rows}
⟨"JPY","2026-01-20"⟩ lib.AssertEq (Find "balances").arguments
⟨"JPY","2026-01-01","2026-01-21"⟩ lib.AssertEq (Find "profit-and-loss").arguments
⟨"2026-01-20","5"⟩ lib.AssertEq (Find "recent").arguments
⟨"JPY","2026-01-20","2025-12-20","aligned_elapsed"⟩ lib.AssertEq (Find "cycle-comparison").arguments
⟨"JPY","2025-12","2026-02"⟩ lib.AssertEq (Find "monthly-accounts").arguments
⟨"JPY","2026-01-01","2026-01-21","2026-01-18"⟩ lib.AssertEq (Find "daily-flow").arguments
⟨"JPY","2026-01-20","2026-02-01"⟩ lib.AssertEq (Find "daily-target").arguments
0 lib.AssertEq ≠(Find "issues").arguments

emptyDaily ← builder.DailyObservation ⟨facts,"JPY","2025-11-01","2025-11-30"⟩
"2025-11-01" lib.AssertEq emptyDaily

compact ← builder.Build ⟨"JPY","compact",reportPlan,facts,"2026-01-20",current,baseline⟩
"ok" lib.AssertEq compact.state
⟨"envelopes","balances","recent","planned","daily-target"⟩ lib.AssertEq {𝕩.key}¨compact.rows

•Out "test_application_current_report_requests: ok"
