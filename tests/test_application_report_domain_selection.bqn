#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
selection ← •Import "../src/application/report_domain_selection.bqn"

one ← {domains⇐{code⇐⟨"JPY"⟩}}
two ← {domains⇐{code⇐⟨"JPY","USD"⟩}}
none ← {domains⇐{code⇐⟨⟩}}

inferred ← selection.Resolve ⟨one,""⟩
"ok" lib.AssertEq inferred.state
"JPY" lib.AssertEq inferred.domain
0 lib.AssertEq ≠inferred.diagnostics

explicit ← selection.Resolve ⟨two,"USD"⟩
"ok" lib.AssertEq explicit.state
"USD" lib.AssertEq explicit.domain

required ← selection.Resolve ⟨two,""⟩
"error" lib.AssertEq required.state
lib.Assert ∨´"report_domain_required"⊸≡¨{𝕩.code}¨required.diagnostics

unknown ← selection.Resolve ⟨one,"USD"⟩
"error" lib.AssertEq unknown.state
lib.Assert ∨´"report_domain_unknown"⊸≡¨{𝕩.code}¨unknown.diagnostics

empty ← selection.Resolve ⟨none,""⟩
"error" lib.AssertEq empty.state
lib.Assert ∨´"report_domain_required"⊸≡¨{𝕩.code}¨empty.diagnostics

•Out "test_application_report_domain_selection: ok"
