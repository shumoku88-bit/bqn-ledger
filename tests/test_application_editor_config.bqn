#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
rows ← •Import "../src/application/config_rows.bqn"
defaults ← •Import "../src/application/system_defaults.bqn"
configPath ← •Import "../src/application/editor_config_path.bqn"
tab ← @+9

table ← rows.Build ⟨"A=one","B"∾tab∾"two","EMPTY="∾"","A=three"⟩
⟨1,"one"⟩ lib.AssertEq table.Lookup "A"
⟨0,""⟩ lib.AssertEq table.Lookup "MISSING"
2 lib.AssertEq ≠table.Matches "A"
"" lib.AssertEq table.Get "EMPTY"

system ← defaults.Load @
"accounts.tsv" lib.AssertEq system.DefaultAccountsFile @
"plan.tsv" lib.AssertEq system.DefaultPlanFile @
"config.tsv" lib.AssertEq system.DefaultConfigFile @
"fixtures/ledger-facts-phase1-proof/config.tsv" lib.AssertEq configPath.Resolve "fixtures/ledger-facts-phase1-proof"

•Out "test_application_editor_config: ok"
