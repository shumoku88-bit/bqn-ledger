#!/usr/bin/env bqn

loader ← •Import "../src/application/source_io.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
issues ← •Import "../src/ledger/issue_admission.bqn"
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry

result ← issues.Admit ⟨⟨""⟩,registry⟩
result.state

•Out "temporary blank-only Issue gate: ok"
