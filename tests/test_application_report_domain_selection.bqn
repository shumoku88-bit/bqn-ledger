#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
selection ← •Import "../src/application/report_domain_selection.bqn"

one ← {domains⇐{code⇐⟨"JPY"⟩}}
two ← {domains⇐{code⇐⟨"JPY","USD"⟩}}
none ← {domains⇐{code⇐⟨⟩}}

CheckOk ← {𝕊 expected‿result:
  "ok" lib.AssertEq result.state
  expected lib.AssertEq result.domain
  0 lib.AssertEq ≠result.diagnostics
}
CheckError ← {𝕊 expectedCode‿result:
  "error" lib.AssertEq result.state
  "" lib.AssertEq result.domain
  1 lib.AssertEq ≠result.diagnostics
  expectedCode lib.AssertEq (⊑result.diagnostics).code
}

CheckOk ⟨"JPY",selection.Resolve ⟨one,""⟩⟩
CheckOk ⟨"USD",selection.Resolve ⟨two,"USD"⟩⟩
CheckError ⟨"report_domain_required",selection.Resolve ⟨two,""⟩⟩
CheckError ⟨"report_domain_unknown",selection.Resolve ⟨one,"USD"⟩⟩
CheckError ⟨"report_domain_required",selection.Resolve ⟨none,""⟩⟩

•Out "test_application_report_domain_selection: ok"
