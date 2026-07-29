#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
io ← •Import "../src/application/source_io.bqn"
accounts ← •Import "../src/application/editor_accounts.bqn"

admitted ← accounts.Admit io.ReadLines "fixtures/plan-completion/accounts.tsv"
"ok" lib.AssertEq admitted.state
16 lib.AssertEq admitted.accounts.count
"assets:bank" lib.AssertEq 1⊑admitted.accounts.key
"JPY" lib.AssertEq 1⊑admitted.accounts.currency
"asset" lib.AssertEq 1⊑admitted.accounts.role

missingCurrency ← accounts.Admit ⟨"assets:cash"∾(@+9)∾"role=asset"⟩
"error" lib.AssertEq missingCurrency.state
missingRole ← accounts.Admit ⟨"assets:cash"∾(@+9)∾"currency=JPY"⟩
"error" lib.AssertEq missingRole.state
unknownCurrency ← accounts.Admit ⟨"assets:cash"∾(@+9)∾"role=asset"∾(@+9)∾"currency=ZZZ"⟩
"error" lib.AssertEq unknownCurrency.state

•Out "test_application_editor_accounts: ok"
