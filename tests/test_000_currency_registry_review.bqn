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

CheckFailure ⟨⟨tab∾"x"∾tab⟩,"currency_registry_currency_empty"⟩
CheckFailure ⟨⟨invalidFractionLine⟩,"currency_registry_fraction_digits_invalid"⟩
CheckFailure ⟨⟨invalidFractionLine,invalidFractionLine⟩,"currency_registry_fraction_digits_invalid"⟩
CheckFailure ⟨⟨validLine,validLine⟩,"currency_registry_currency_duplicate"⟩

valid ← registry.Build ⟨"", validLine⟩
"ok" lib.AssertEq valid.state
⟨"JPY"⟩ lib.AssertEq valid.registry.codes
"ok" lib.AssertEq (valid.registry.Policy "JPY").state
"error" lib.AssertEq (valid.registry.Policy "USD").state
1 lib.AssertEq valid.registry.IsSupportedCurrency "JPY"
0 lib.AssertEq valid.registry.IsSupportedCurrency "USD"

•Out "test_000_currency_registry_review: ok"
