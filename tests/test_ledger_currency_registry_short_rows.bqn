#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
registry ← •Import "../src/ledger/currency_registry.bqn"
tab ← @+9

CheckRowInvalid ← {𝕊 lines:
  result ← registry.Build lines
  "error" lib.AssertEq result.state
  "currency_registry_row_invalid" lib.AssertEq result.code
  "currency registry rows require currency, max_fraction_digits, and symbol" lib.AssertEq result.message
  0 lib.AssertEq ≠result.registry.codes
}

CheckRowInvalid ⟨"JPY"⟩
CheckRowInvalid ⟨"JPY"∾tab∾"0"⟩
CheckRowInvalid ⟨tab∾"x"⟩
CheckRowInvalid ⟨"JPY"∾tab∾"0"∾tab∾"YEN"∾tab∾"extra"⟩

valid ← registry.Build ⟨"JPY"∾tab∾"0"∾tab∾"YEN"⟩
"ok" lib.AssertEq valid.state
⟨"JPY"⟩ lib.AssertEq valid.registry.codes
policy ← valid.registry.Policy "JPY"
"ok" lib.AssertEq policy.state
"JPY" lib.AssertEq policy.currency
0 lib.AssertEq policy.max_fraction_digits
"YEN" lib.AssertEq policy.symbol

•Out "test_ledger_currency_registry_short_rows: ok"
