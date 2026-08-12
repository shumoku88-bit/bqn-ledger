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
missing ← setup.ResolveDefault ⟨"ACTUAL_JOURNAL_FILE=actual.journal"⟩
"missing_default_currency" lib.AssertEq missing.code
"empty_default_currency" lib.AssertEq (setup.ResolveDefault ⟨"DEFAULT_CURRENCY="⟩).code
"duplicate_default_currency" lib.AssertEq (setup.ResolveDefault ⟨"DEFAULT_CURRENCY=JPY","DEFAULT_CURRENCY=USD"⟩).code
"unsupported_default_currency" lib.AssertEq (setup.ResolveDefault ⟨"DEFAULT_CURRENCY=ZZZ"⟩).code

defaulted ← setup.ResolveSelection ⟨jpy,""⟩
"ok" lib.AssertEq defaulted.state
"JPY" lib.AssertEq defaulted.currency
"ledger_default" lib.AssertEq defaulted.provenance
"default_currency_unavailable" lib.AssertEq (setup.ResolveSelection ⟨missing,""⟩).code

explicit ← setup.ResolveSelection ⟨missing,"ILS"⟩
"ok" lib.AssertEq explicit.state
"ILS" lib.AssertEq explicit.currency
"explicit_selection" lib.AssertEq explicit.provenance
"unsupported_selected_currency" lib.AssertEq (setup.ResolveSelection ⟨jpy,"ZZZ"⟩).code

# Explicit selection is independent of a duplicate or otherwise unavailable default.
duplicate ← setup.ResolveDefault ⟨"DEFAULT_CURRENCY=JPY","DEFAULT_CURRENCY=USD"⟩
explicitWithDuplicate ← setup.ResolveSelection ⟨duplicate,"USD"⟩
"ok" lib.AssertEq explicitWithDuplicate.state
"USD" lib.AssertEq explicitWithDuplicate.currency
"explicit_selection" lib.AssertEq explicitWithDuplicate.provenance

•Out "test_application_editor_currency: ok"
