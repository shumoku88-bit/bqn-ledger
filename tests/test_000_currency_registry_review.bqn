#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
registry ← •Import "../src/ledger/currency_registry.bqn"
tab ← @+9

validLine ← "JPY"∾tab∾"0"∾tab∾"YEN"
valid ← registry.Build ⟨"", validLine⟩
"ok" lib.AssertEq valid.state
⟨"JPY"⟩ lib.AssertEq valid.registry.codes

•Out "test_000_currency_registry_review: ok"
