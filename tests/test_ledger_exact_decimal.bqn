#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
dec ← •Import "../src/ledger/exact_decimal.bqn"

CheckOk ← {𝕊 text‿expectedCoefficient‿expectedScale:
  result ← dec.Parse text
  "ok" lib.AssertEq result.state
  expectedCoefficient lib.AssertEq result.coefficient
  expectedScale lib.AssertEq result.scale
  text lib.AssertEq result.source_text
  "" lib.AssertEq result.message
}

CheckFail ← {𝕊 text‿expectedState‿expectedMessage:
  result ← dec.Parse text
  expectedState lib.AssertEq result.state
  ⟨⟩ lib.AssertEq result.coefficient
  ⟨⟩ lib.AssertEq result.scale
  text lib.AssertEq result.source_text
  expectedMessage lib.AssertEq result.message
}

CheckOk ⟨"1200", 1200, 0⟩
CheckOk ⟨"42.50", 425, 1⟩
CheckOk ⟨"0.05", 5, 2⟩
CheckOk ⟨"00042.50", 425, 1⟩
CheckOk ⟨"0.000", 0, 0⟩
CheckOk ⟨"0000.000", 0, 0⟩
CheckOk ⟨"42.5000", 425, 1⟩
CheckOk ⟨"00000000000000000000042.500000000000000000", 425, 1⟩
CheckOk ⟨"0000000000000000000000000000000", 0, 0⟩
CheckOk ⟨"0.0000000000000000001", 1, 19⟩

invalid ← ⟨"", "+1", "-1", ".5", "5.", "1e3", "1E3", "1,000", "42 50", "1.2.3"⟩
{𝕩 ⋄ CheckFail ⟨𝕩, "invalid_syntax", "invalid_decimal_syntax"⟩}¨ invalid

# CBQN's current Number path cannot preserve this coefficient exactly. The
# parser must expose range failure rather than admitting a rounded coefficient.
CheckFail ⟨"9007199254740993", "out_of_exact_range", "amount_out_of_exact_range"⟩
CheckFail ⟨"0009007199254740993", "out_of_exact_range", "amount_out_of_exact_range"⟩
CheckFail ⟨"9007199254740993.0", "out_of_exact_range", "amount_out_of_exact_range"⟩

•Out "test_ledger_exact_decimal.bqn: OK"
