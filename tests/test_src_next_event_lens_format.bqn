#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
fmt ← •Import "../src_next/event_lens_format.bqn"

tab_char ← @+9
lf_char ← @+10

header_text ← "source_file" ∾ tab_char ∾ "source_row" ∾ tab_char ∾ "source_id" ∾ tab_char ∾ "when_value" ∾ tab_char ∾ "when_state" ∾ tab_char ∾ "party_value" ∾ tab_char ∾ "party_state" ∾ tab_char ∾ "what_value" ∾ tab_char ∾ "what_state" ∾ tab_char ∾ "from_account" ∾ tab_char ∾ "where_to_value" ∾ tab_char ∾ "where_to_state" ∾ tab_char ∾ "amount_text" ∾ tab_char ∾ "amount_coefficient" ∾ tab_char ∾ "amount_scale" ∾ tab_char ∾ "currency" ∾ tab_char ∾ "amount_state" ∾ tab_char ∾ "action_value" ∾ tab_char ∾ "action_state" ∾ tab_char ∾ "layer" ∾ tab_char ∾ "kind"

result ← fmt.FormatTsv { state ⇐ "ok", rows ⇐ ⟨⟩ }
"ok" lib.AssertEq result.state
(header_text ∾ lf_char) lib.AssertEq result.text
"" lib.AssertEq result.message

•Out "event lens TSV formatter header-only test passed"
