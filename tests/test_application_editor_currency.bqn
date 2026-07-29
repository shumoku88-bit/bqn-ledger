#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
currency ← •Import "../src/application/editor_currency.bqn"
setup ← currency.Load @

⟨"JPY","ILS","USD"⟩ lib.AssertEq setup.registry.codes
"ok" lib.AssertEq (setup.Policy "USD").state
2 lib.AssertEq (setup.Policy "USD").max_fraction_digits
"error" lib.AssertEq (setup.Policy "ZZZ").state

jpy ← setup.ResolveDefault ⟨"DEFAULT_CURRENCY=JPY"⟩
"ok" lib.AssertEq jpy.state
"JPY" lib.AssertEq jpy.currency
"ledger_config" lib.AssertEq jpy.provenance
"missing_default_currency" lib.AssertEq (setup.ResolveDefault ⟨"ACTUAL_JOURNAL_FILE=actual.journal"⟩).code
"duplicate_default_currency" lib.AssertEq (setup.ResolveDefault ⟨"DEFAULT_CURRENCY=JPY","DEFAULT_CURRENCY=USD"⟩).code
"unsupported_default_currency" lib.AssertEq (setup.ResolveDefault ⟨"DEFAULT_CURRENCY=ZZZ"⟩).code

explicit ← setup.ResolveSelection ⟨setup.ResolveDefault ⟨⟩,"ILS"⟩
"ok" lib.AssertEq explicit.state
"ILS" lib.AssertEq explicit.currency
"explicit_selection" lib.AssertEq explicit.provenance
"unsupported_selected_currency" lib.AssertEq (setup.ResolveSelection ⟨jpy,"ZZZ"⟩).code

•Out "test_application_editor_currency: ok"
