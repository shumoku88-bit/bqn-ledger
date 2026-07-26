#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
source_fields ← •Import "../src_next/source_fields.bqn"

flds ← ⟨"2026-07-27", "", "Assets:Cash"⟩

"2026-07-27" lib.AssertEq source_fields.FieldOrEmpty ⟨flds, 0⟩
"" lib.AssertEq source_fields.FieldOrEmpty ⟨flds, 1⟩
"Assets:Cash" lib.AssertEq source_fields.FieldOrEmpty ⟨flds, 2⟩
"" lib.AssertEq source_fields.FieldOrEmpty ⟨flds, 3⟩
"" lib.AssertEq source_fields.FieldOrEmpty ⟨⟨⟩, 0⟩

•Out "test_src_next_source_fields.bqn: OK"
