#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
rows ← •Import "../src/application/config_rows.bqn"
tab ← @+9

table ← rows.Build ⟨"A=one","B"∾tab∾"two","EMPTY="∾"","A=three"⟩
⟨⟨"A","one"⟩,⟨"A","three"⟩⟩ lib.AssertEq table.Matches "A"
⟨⟨"B","two"⟩⟩ lib.AssertEq table.Matches "B"
⟨⟨"EMPTY",""⟩⟩ lib.AssertEq table.Matches "EMPTY"
⟨⟩ lib.AssertEq table.Matches "MISSING"

•Out "test_application_editor_config: ok"
