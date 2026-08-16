#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
adapter ← •Import "../src/application/account_source_adapter.bqn"

result ← adapter.Load "fixtures/canonical-household-v1"
"ok" lib.AssertEq result.state
"accounts.journal" lib.AssertEq result.source_name
7 lib.AssertEq result.accounts.count
"Assets:Bank" lib.AssertEq ⊑result.accounts.key
"Asset" lib.AssertEq ⊑result.accounts.type
"asset" lib.AssertEq ⊑result.accounts.role
"JPY" lib.AssertEq ⊑result.accounts.default_commodity

•Out "test_application_account_source_adapter: ok"
