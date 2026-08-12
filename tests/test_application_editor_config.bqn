#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
rows ← •Import "../src/application/config_rows.bqn"
defaults ← •Import "../src/application/system_defaults.bqn"
configPath ← •Import "../src/application/editor_config_path.bqn"
tab ← @+9

table ← rows.Build ⟨"A=one","B"∾tab∾"two","EMPTY="∾"","A=three"⟩
⟨⟨"A","one"⟩,⟨"A","three"⟩⟩ lib.AssertEq table.Matches "A"
⟨⟨"B","two"⟩⟩ lib.AssertEq table.Matches "B"
⟨⟨"EMPTY",""⟩⟩ lib.AssertEq table.Matches "EMPTY"
⟨⟩ lib.AssertEq table.Matches "MISSING"

system ← defaults.Load @
"accounts.tsv" lib.AssertEq system.DefaultAccountsFile @
"plan.tsv" lib.AssertEq system.DefaultPlanFile @
"config.tsv" lib.AssertEq system.DefaultConfigFile @
"fixtures/ledger-facts-phase1-proof/config.tsv" lib.AssertEq configPath.Resolve "fixtures/ledger-facts-phase1-proof"

•Out "test_application_editor_config: ok"
