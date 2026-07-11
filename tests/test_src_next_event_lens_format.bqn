#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
fmt ← •Import "../src_next/event_lens_format.bqn"

Tab ← @+9
Lf ← @+10

header ← "source_file" ∾ Tab ∾ "source_row" ∾ Tab ∾ "source_id" ∾ Tab ∾ "when_value" ∾ Tab ∾ "when_state" ∾ Tab ∾ "party_value" ∾ Tab ∾ "party_state" ∾ Tab ∾ "what_value" ∾ Tab ∾ "what_state" ∾ Tab ∾ "from_account" ∾ Tab ∾ "where_to_value" ∾ Tab ∾ "where_to_state" ∾ Tab ∾ "amount_text" ∾ Tab ∾ "amount_coefficient" ∾ Tab ∾ "amount_scale" ∾ Tab ∾ "currency" ∾ Tab ∾ "amount_state" ∾ Tab ∾ "action_value" ∾ Tab ∾ "action_state" ∾ Tab ∾ "layer" ∾ Tab ∾ "kind"

result ← fmt.FormatTsv { state ⇐ "ok", rows ⇐ ⟨⟩ }
"ok" lib.AssertEq result.state
(header ∾ Lf) lib.AssertEq result.text
"" lib.AssertEq result.message

•Out "event lens TSV formatter smoke test passed"
