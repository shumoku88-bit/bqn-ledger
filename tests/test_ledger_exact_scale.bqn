#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
scale ← •Import "../src/ledger/exact_scale.bqn"
empty ← ⟨⟩

CheckNormalizeOk ← {𝕊 input‿expected:
  result ← scale.Normalize input
  "ok" lib.AssertEq result.state
  expected lib.AssertEq result.coefficient
  "" lib.AssertEq result.code
}

CheckNormalizeFail ← {𝕊 input‿code:
  result ← scale.Normalize input
  "error" lib.AssertEq result.state
  empty lib.AssertEq result.coefficient
  code lib.AssertEq result.code
}

CheckSumOk ← {𝕊 coefficients‿expected:
  result ← scale.Sum coefficients
  "ok" lib.AssertEq result.state
  expected lib.AssertEq result.coefficient
  "" lib.AssertEq result.code
}

CheckSumFail ← {𝕊 coefficients:
  result ← scale.Sum coefficients
  "error" lib.AssertEq result.state
  empty lib.AssertEq result.coefficient
  "coefficient_sum_out_of_exact_range" lib.AssertEq result.code
}

CheckNormalizeOk ⟨⟨425,1,1⟩,425⟩
CheckNormalizeOk ⟨⟨425,1,2⟩,4250⟩
CheckNormalizeOk ⟨⟨¯425,1,2⟩,¯4250⟩
CheckNormalizeOk ⟨⟨0,0,19⟩,0⟩
CheckNormalizeFail ⟨⟨425,2,1⟩,"scale_invalid"⟩
CheckNormalizeFail ⟨⟨9007199254740991,0,1⟩,"normalized_coefficient_out_of_exact_range"⟩

CheckSumOk ⟨⟨⟩,0⟩
CheckSumOk ⟨⟨1,2,3⟩,6⟩
CheckSumOk ⟨⟨5,¯5,7,¯7⟩,0⟩
CheckSumOk ⟨⟨9007199254740991,1⟩,9007199254740992⟩
CheckSumFail ⟨9007199254740992,1⟩

# Checked summation is source-order sequential. A mathematically cancelling tail
# does not authorize an inexact intermediate runtime addition.
CheckSumFail ⟨9007199254740992,1,¯1⟩
CheckSumOk ⟨⟨1,¯1,9007199254740992⟩,9007199254740992⟩

•Out "test_ledger_exact_scale: ok"
