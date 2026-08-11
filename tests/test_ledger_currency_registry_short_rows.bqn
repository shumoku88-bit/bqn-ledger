#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
registry ← •Import "../src/ledger/currency_registry.bqn"
tab ← @+9

validLine ← "JPY"∾tab∾"0"∾tab∾"YEN"
invalidFractionLine ← "JPY"∾tab∾"x"∾tab∾"YEN"

CheckFailure ← {𝕊 lines‿code:
  result ← registry.Build lines
  "error" lib.AssertEq result.state
  code lib.AssertEq result.code
  0 lib.AssertEq ≠result.registry.codes
}
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
CheckFailure ⟨⟨tab∾"x"∾tab⟩,"currency_registry_currency_empty"⟩
CheckFailure ⟨⟨invalidFractionLine⟩,"currency_registry_fraction_digits_invalid"⟩
CheckFailure ⟨⟨invalidFractionLine,invalidFractionLine⟩,"currency_registry_fraction_digits_invalid"⟩
CheckFailure ⟨⟨validLine,validLine⟩,"currency_registry_currency_duplicate"⟩

valid ← registry.Build ⟨validLine⟩
"ok" lib.AssertEq valid.state
⟨"JPY"⟩ lib.AssertEq valid.registry.codes
policy ← valid.registry.Policy "JPY"
"ok" lib.AssertEq policy.state
"JPY" lib.AssertEq policy.currency
0 lib.AssertEq policy.max_fraction_digits
"YEN" lib.AssertEq policy.symbol
1 lib.AssertEq valid.registry.IsSupportedCurrency "JPY"

unsupported ← valid.registry.Policy "USD"
"error" lib.AssertEq unsupported.state
"unsupported_currency" lib.AssertEq unsupported.code
"USD" lib.AssertEq unsupported.currency
0 lib.AssertEq valid.registry.IsSupportedCurrency "USD"

ignoredBlank ← registry.Build ⟨"", validLine⟩
"ok" lib.AssertEq ignoredBlank.state
⟨"JPY"⟩ lib.AssertEq ignoredBlank.registry.codes
ignoredOnly ← registry.Build ⟨"", "# comment"⟩
"error" lib.AssertEq ignoredOnly.state
"currency_registry_empty" lib.AssertEq ignoredOnly.code

•Out "test_ledger_currency_registry_short_rows: ok"
