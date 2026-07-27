#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
arith ← •Import "../src_next/currency_arithmetic.bqn"
dec ← •Import "../src/ledger/exact_decimal.bqn"

Row ← {𝕊 currency‿coefficient‿scale:
  {
    state ⇐ "ok",
    currency ⇐ currency,
    parsed ⇐ {
      state ⇐ "ok",
      coefficient ⇐ coefficient,
      scale ⇐ scale
    }
  }
}

AssertErrorEmpty ← {𝕊 result‿message:
  "error" lib.AssertEq result.state
  ⟨⟩ lib.AssertEq result.domain
  ⟨⟩ lib.AssertEq result.amount_scale
  ⟨⟩ lib.AssertEq result.normalized_coefficients
  message lib.AssertEq result.message
}

empty ← arith.Build ⟨⟩
"ok" lib.AssertEq empty.state
"JPY" lib.AssertEq empty.domain
0 lib.AssertEq empty.amount_scale
⟨⟩ lib.AssertEq empty.normalized_coefficients
"" lib.AssertEq empty.message

jpyRows ← ⟨Row ⟨"JPY", 425, 1⟩, Row ⟨"JPY", 5, 2⟩, Row ⟨"JPY", 18, 0⟩⟩
jpy ← arith.Build jpyRows
"ok" lib.AssertEq jpy.state
"JPY" lib.AssertEq jpy.domain
2 lib.AssertEq jpy.amount_scale
⟨4250, 5, 1800⟩ lib.AssertEq jpy.normalized_coefficients

ilsRows ← ⟨Row ⟨"ILS", 425, 1⟩, Row ⟨"ILS", 5, 2⟩, Row ⟨"ILS", 18, 0⟩⟩
ils ← arith.Build ilsRows
"ok" lib.AssertEq ils.state
"ILS" lib.AssertEq ils.domain
2 lib.AssertEq ils.amount_scale
⟨4250, 5, 1800⟩ lib.AssertEq ils.normalized_coefficients

# A non-sorted input makes one-to-one input-order preservation explicit.
ordered ← arith.Build ⟨Row ⟨"JPY", 18, 0⟩, Row ⟨"JPY", 425, 1⟩, Row ⟨"JPY", 5, 2⟩⟩
⟨1800, 4250, 5⟩ lib.AssertEq ordered.normalized_coefficients

mixed ← arith.Build ⟨Row ⟨"JPY", 1, 0⟩, Row ⟨"ILS", 2, 0⟩⟩
AssertErrorEmpty ⟨mixed, "mixed_currency_domains"⟩

invalidRow ← {state⇐"error", currency⇐"JPY", parsed⇐{state⇐"ok", coefficient⇐7, scale⇐0}}
invalid ← arith.Build ⟨invalidRow, Row ⟨"JPY", 2, 0⟩⟩
AssertErrorEmpty ⟨invalid, "invalid_row_evidence"⟩

invalidParsed ← {state⇐"ok", currency⇐"JPY", parsed⇐{state⇐"out_of_exact_range", coefficient⇐⟨⟩, scale⇐⟨⟩}}
invalidParsedResult ← arith.Build ⟨invalidParsed⟩
AssertErrorEmpty ⟨invalidParsedResult, "invalid_row_evidence"⟩

# Start from a coefficient executable evidence proves is exactly admitted by
# the current parser boundary. It remains valid without scale-up, but appending
# one decimal zero must fail closed.
largeParsed ← dec.Parse "999999999999999"
"ok" lib.AssertEq largeParsed.state
large ← largeParsed.coefficient
largeBoundary ← arith.Build ⟨Row ⟨"JPY", large, largeParsed.scale⟩⟩
"ok" lib.AssertEq largeBoundary.state
⟨large⟩ lib.AssertEq largeBoundary.normalized_coefficients

overflow ← arith.Build ⟨Row ⟨"JPY", large, 0⟩, Row ⟨"JPY", 1, 1⟩⟩
AssertErrorEmpty ⟨overflow, "normalized_amount_out_of_exact_range"⟩

•Out "test_src_next_currency_arithmetic.bqn: OK"
