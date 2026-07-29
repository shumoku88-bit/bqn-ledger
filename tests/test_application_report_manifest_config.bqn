#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
admission ← •Import "../src/application/report_manifest_admission.bqn"
tab ← @+9

valid ← admission.Admit ⟨
  "REPORT_HUMAN_MANIFEST=human.tsv",
  "REPORT_COMPACT_MANIFEST=compact.tsv"
⟩
"ok" lib.AssertEq valid.state
"" lib.AssertEq valid.code
"human.tsv" lib.AssertEq valid.human_file
"compact.tsv" lib.AssertEq valid.compact_file

missing ← admission.Admit ⟨"REPORT_HUMAN_MANIFEST=human.tsv"⟩
"error" lib.AssertEq missing.state
"report_compact_manifest_missing_or_duplicate" lib.AssertEq missing.code
"" lib.AssertEq missing.human_file
"" lib.AssertEq missing.compact_file

duplicate ← admission.Admit ⟨
  "REPORT_HUMAN_MANIFEST=one.tsv",
  "REPORT_HUMAN_MANIFEST=two.tsv",
  "REPORT_COMPACT_MANIFEST=compact.tsv"
⟩
"report_human_manifest_missing_or_duplicate" lib.AssertEq duplicate.code
empty ← admission.Admit ⟨"REPORT_HUMAN_MANIFEST=","REPORT_COMPACT_MANIFEST=compact.tsv"⟩
"report_human_manifest_empty" lib.AssertEq empty.code
unsafe ← admission.Admit ⟨"REPORT_HUMAN_MANIFEST=../human.tsv","REPORT_COMPACT_MANIFEST=compact.tsv"⟩
"report_human_manifest_basename_invalid" lib.AssertEq unsafe.code
same ← admission.Admit ⟨"REPORT_HUMAN_MANIFEST=all.tsv","REPORT_COMPACT_MANIFEST=all.tsv"⟩
"report_manifests_must_differ" lib.AssertEq same.code

tsvValid ← admission.Admit ⟨
  "REPORT_HUMAN_MANIFEST"∾tab∾"human.tsv",
  "REPORT_COMPACT_MANIFEST"∾tab∾"compact.tsv"
⟩
"ok" lib.AssertEq tsvValid.state
•Out "test_application_report_manifest_config: ok"
