#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
account_admission ← •Import "../src/ledger/account_admission.bqn"
config_admission ← •Import "../src/ledger/config_admission.bqn"
cycle_admission ← •Import "../src/ledger/cycle_admission.bqn"

base ← "fixtures/ledger-facts-phase1-proof/"
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
accounts ← (account_admission.Admit ⟨loader.ReadLines base∾"accounts.tsv",registry⟩).accounts
HasCode ← {𝕊 code‿diagnostics: ∨´0∾code⊸≡¨{𝕩.code}¨diagnostics}

configResult ← config_admission.Admit ⟨loader.ReadLines base∾"config.tsv",registry⟩
"ok" lib.AssertEq configResult.state
"JPY" lib.AssertEq configResult.source.default_currency
"" lib.AssertEq configResult.source.actual_journal_file
"envelope" lib.AssertEq configResult.report_policy.budget_style
"conservative" lib.AssertEq configResult.report_policy.risk_style
"monthly" lib.AssertEq configResult.report_policy.income_cadence
"daily,reserve" lib.AssertEq configResult.report_policy.household_group_order

minimalConfig ← config_admission.Admit ⟨⟨"DEFAULT_CURRENCY	USD","ACTUAL_JOURNAL_FILE	actual.journal"⟩,registry⟩
"ok" lib.AssertEq minimalConfig.state
"USD" lib.AssertEq minimalConfig.source.default_currency
"actual.journal" lib.AssertEq minimalConfig.source.actual_journal_file
2 lib.AssertEq minimalConfig.table.count

CheckConfigRejected ← {𝕊 lines‿code:
  rejected ← config_admission.Admit ⟨lines,registry⟩
  "error" lib.AssertEq rejected.state
  0 lib.AssertEq rejected.table.count
  "" lib.AssertEq rejected.source.default_currency
  1 lib.AssertEq HasCode ⟨code,rejected.diagnostics⟩
}
CheckConfigRejected ⟨⟨⟩,"default_currency_missing"⟩
CheckConfigRejected ⟨⟨"DEFAULT_CURRENCY=XXX"⟩,"default_currency_unsupported"⟩
CheckConfigRejected ⟨⟨"DEFAULT_CURRENCY=JPY","UNKNOWN=x"⟩,"config_key_unsupported"⟩
CheckConfigRejected ⟨⟨"DEFAULT_CURRENCY=JPY","POLICY_BUDGET_STYLE=other"⟩,"budget_style_invalid"⟩
CheckConfigRejected ⟨⟨"DEFAULT_CURRENCY=JPY","HOUSEHOLD_GROUP_ORDER=daily,,reserve"⟩,"config_list_item_empty"⟩
CheckConfigRejected ⟨⟨"DEFAULT_CURRENCY=JPY","ACTUAL_JOURNAL_FILE=../actual.journal"⟩,"actual_journal_file_invalid"⟩

duplicateConfigKeys ← config_admission.Admit ⟨
  ⟨"DEFAULT_CURRENCY=JPY","POLICY_BUDGET_STYLE=envelope","DEFAULT_CURRENCY=USD"⟩,
  registry
⟩
"error" lib.AssertEq duplicateConfigKeys.state
0 lib.AssertEq duplicateConfigKeys.table.count
"" lib.AssertEq duplicateConfigKeys.source.default_currency
"config_key_duplicate" lib.AssertEq (⊑duplicateConfigKeys.diagnostics).code
0 lib.AssertEq (⊑duplicateConfigKeys.diagnostics).source_row

duplicateListItems ← config_admission.Admit ⟨
  ⟨"DEFAULT_CURRENCY=JPY","HOUSEHOLD_GROUP_ORDER=daily,reserve,daily"⟩,
  registry
⟩
"error" lib.AssertEq duplicateListItems.state
0 lib.AssertEq duplicateListItems.table.count
1 lib.AssertEq ≠duplicateListItems.diagnostics
"config_list_item_duplicate" lib.AssertEq (⊑duplicateListItems.diagnostics).code
0 lib.AssertEq (⊑duplicateListItems.diagnostics).source_row

cycleResult ← cycle_admission.Admit ⟨loader.ReadLines base∾"cycle.tsv",accounts⟩
"ok" lib.AssertEq cycleResult.state
"fixed" lib.AssertEq cycleResult.definition.mode
"2026-01-01" lib.AssertEq cycleResult.definition.start
"2026-02-01" lib.AssertEq cycleResult.definition.end_exclusive
"income:salary" lib.AssertEq cycleResult.definition.income_account

incomeCycle ← cycle_admission.Admit ⟨⟨"mode	incomeAnchor","income_account	income:salary","offset	0"⟩,accounts⟩
"ok" lib.AssertEq incomeCycle.state
"incomeAnchor" lib.AssertEq incomeCycle.definition.mode
0 lib.AssertEq incomeCycle.definition.offset
calendarCycle ← cycle_admission.Admit ⟨⟨"mode	calendarMonth","start_day	15"⟩,accounts⟩
"ok" lib.AssertEq calendarCycle.state
15 lib.AssertEq calendarCycle.definition.start_day

CheckCycleRejected ← {𝕊 lines‿code:
  rejected ← cycle_admission.Admit ⟨lines,accounts⟩
  "error" lib.AssertEq rejected.state
  0 lib.AssertEq rejected.table.count
  "" lib.AssertEq rejected.definition.mode
  1 lib.AssertEq HasCode ⟨code,rejected.diagnostics⟩
}
CheckCycleRejected ⟨⟨⟩,"cycle_mode_invalid"⟩
CheckCycleRejected ⟨⟨"mode	monthly"⟩,"cycle_mode_invalid"⟩
CheckCycleRejected ⟨⟨"mode	fixed","start	2026-99-01","end_exclusive	2026-02-01"⟩,"fixed_cycle_start_invalid"⟩
CheckCycleRejected ⟨⟨"mode	fixed","start	2026-02-01","end_exclusive	2026-01-01"⟩,"fixed_cycle_range_invalid"⟩
CheckCycleRejected ⟨⟨"mode	incomeAnchor"⟩,"income_anchor_account_missing"⟩
CheckCycleRejected ⟨⟨"mode	incomeAnchor","income_account	income:salary","offset	-1"⟩,"income_anchor_offset_unsupported"⟩
CheckCycleRejected ⟨⟨"mode	incomeAnchor","income_account	assets:cash"⟩,"cycle_income_account_role_invalid"⟩
CheckCycleRejected ⟨⟨"mode	incomeAnchor","income_account	income:missing"⟩,"cycle_income_account_unknown"⟩
CheckCycleRejected ⟨⟨"mode	calendarMonth","start_day	29"⟩,"calendar_start_day_invalid"⟩
CheckCycleRejected ⟨⟨"mode	calendarMonth","start_day	15","start	2026-01-01"⟩,"calendar_cycle_field_invalid"⟩

duplicateCycle ← cycle_admission.Admit ⟨
  ⟨"mode	fixed","start	2026-01-01","mode	fixed","end_exclusive	2026-02-01"⟩,
  accounts
⟩
"error" lib.AssertEq duplicateCycle.state
0 lib.AssertEq duplicateCycle.table.count
"cycle_key_duplicate" lib.AssertEq (⊑duplicateCycle.diagnostics).code
0 lib.AssertEq (⊑duplicateCycle.diagnostics).source_row

•Out "test_ledger_config_cycle_admission: ok"
