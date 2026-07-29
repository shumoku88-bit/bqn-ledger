#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
rows ← •Import "../src/application/config_rows.bqn"
defaults ← •Import "../src/application/system_defaults.bqn"
configPath ← •Import "../src/application/editor_config_path.bqn"
actual ← •Import "../src/application/actual_journal_config.bqn"
actualAdmission ← •Import "../src/application/actual_journal_admission.bqn"
budget ← •Import "../src/application/editor_plan_budget_config.bqn"
tab ← @+9

table ← rows.Build ⟨"A=one","B"∾tab∾"two","EMPTY="∾"","A=three"⟩
⟨1,"one"⟩ lib.AssertEq table.Lookup "A"
⟨0,""⟩ lib.AssertEq table.Lookup "MISSING"
2 lib.AssertEq ≠table.Matches "A"
"" lib.AssertEq table.Get "EMPTY"

system ← defaults.Load @
"accounts.tsv" lib.AssertEq system.DefaultAccountsFile @
"plan.tsv" lib.AssertEq system.DefaultPlanFile @
"budget_alloc.tsv" lib.AssertEq system.DefaultBudgetAllocFile @
"config.tsv" lib.AssertEq system.DefaultConfigFile @
"fixtures/ledger-facts-phase1-proof/config.tsv" lib.AssertEq configPath.Resolve "fixtures/ledger-facts-phase1-proof"
"actual.journal" lib.AssertEq (actual.Resolve "fixtures/plan-completion").file
"error" lib.AssertEq (actualAdmission.AdmitExplicit ⟨"BUDGET_PREFIX=budget:"⟩).state
compat ← actualAdmission.AdmitWithRepositoryDefault ⟨
  ⟨"BUDGET_PREFIX=budget:"⟩,⟨"ACTUAL_JOURNAL_FILE=actual.journal"⟩
⟩
"ok" lib.AssertEq compat.state
"actual.journal" lib.AssertEq compat.file

editor ← budget.Load "fixtures/ledger-facts-phase1-proof"
"budget:" lib.AssertEq editor.BudgetPrefix @
"budget:spent" lib.AssertEq editor.BudgetSpent @
"" lib.AssertEq editor.ExecutionPlannedPaymentsEnvelope @

•Out "test_application_editor_config: ok"
