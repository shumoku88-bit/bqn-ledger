#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
today ← •Import "../src/application/date_today.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"

value ← today.Today @
10 lib.AssertEq ≠value
1 lib.AssertEq dates.IsValid value

•Out "test_application_date_today: ok"
