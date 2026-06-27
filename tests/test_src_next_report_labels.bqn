#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
labels ← •Import "../src_next/report_labels.bqn"

"1. 全体サマリ (Snapshot)" lib.AssertEq labels.Text "snapshot.section_title"
"future  : これから" lib.AssertEq labels.Text "planned.future_status"
"ペース診断" lib.AssertEq labels.Text "calc.pace_title"
