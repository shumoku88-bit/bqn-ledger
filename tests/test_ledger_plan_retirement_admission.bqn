#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
planAdmission ← •Import "../src/ledger/plan_journal_admission.bqn"

Meta ← {𝕊 key‿value: {key⇐key,value⇐value,source_line⇐1}}
Txn ← {𝕊 planId‿metadata: {plan_id⇐planId,metadata⇐metadata,source_start_line⇐1}}
HasCode ← {𝕊 code‿diagnostics: ∨´0∾{𝕩.code≡code}¨diagnostics}

valid ← planAdmission.AdmitRetirements ⟨
  Txn ⟨"plan-old",⟨Meta ⟨"superseded-on","2026-08-13"⟩,Meta ⟨"superseded-by","plan-new"⟩⟩⟩,
  Txn ⟨"plan-new",⟨⟩⟩,
  Txn ⟨"plan-cancelled",⟨Meta ⟨"cancelled-on","2026-08-12"⟩⟩⟩
⟩
"ok" lib.AssertEq valid.state
2 lib.AssertEq valid.rows.count
⟨"superseded","cancelled"⟩ lib.AssertEq valid.rows.kind
⟨"plan-old","plan-cancelled"⟩ lib.AssertEq valid.rows.plan_id
⟨"2026-08-13","2026-08-12"⟩ lib.AssertEq valid.rows.retired_on
⟨"plan-new",""⟩ lib.AssertEq valid.rows.successor_plan_id

partial ← planAdmission.AdmitRetirements ⟨
  Txn ⟨"plan-old",⟨Meta ⟨"superseded-on","2026-08-13"⟩⟩⟩
⟩
"error" lib.AssertEq partial.state
lib.Assert HasCode ⟨"plan_superseded_by_missing",partial.diagnostics⟩

conflict ← planAdmission.AdmitRetirements ⟨
  Txn ⟨"plan-old",⟨
    Meta ⟨"cancelled-on","2026-08-13"⟩,
    Meta ⟨"superseded-on","2026-08-13"⟩,
    Meta ⟨"superseded-by","plan-new"⟩
  ⟩⟩,
  Txn ⟨"plan-new",⟨⟩⟩
⟩
"error" lib.AssertEq conflict.state
lib.Assert HasCode ⟨"plan_retirement_conflict",conflict.diagnostics⟩

duplicate ← planAdmission.AdmitRetirements ⟨
  Txn ⟨"plan-old",⟨Meta ⟨"cancelled-on","2026-08-13"⟩,Meta ⟨"cancelled-on","2026-08-14"⟩⟩⟩
⟩
"error" lib.AssertEq duplicate.state
lib.Assert HasCode ⟨"plan_retirement_metadata_duplicate",duplicate.diagnostics⟩

unknown ← planAdmission.AdmitRetirements ⟨
  Txn ⟨"plan-old",⟨Meta ⟨"superseded-on","2026-08-13"⟩,Meta ⟨"superseded-by","plan-missing"⟩⟩⟩
⟩
"error" lib.AssertEq unknown.state
lib.Assert HasCode ⟨"plan_supersession_target_unknown",unknown.diagnostics⟩

self ← planAdmission.AdmitRetirements ⟨
  Txn ⟨"plan-old",⟨Meta ⟨"superseded-on","2026-08-13"⟩,Meta ⟨"superseded-by","plan-old"⟩⟩⟩
⟩
"error" lib.AssertEq self.state
lib.Assert HasCode ⟨"plan_supersession_self",self.diagnostics⟩

cycle ← planAdmission.AdmitRetirements ⟨
  Txn ⟨"plan-a",⟨Meta ⟨"superseded-on","2026-08-13"⟩,Meta ⟨"superseded-by","plan-b"⟩⟩⟩,
  Txn ⟨"plan-b",⟨Meta ⟨"superseded-on","2026-08-14"⟩,Meta ⟨"superseded-by","plan-a"⟩⟩⟩
⟩
"error" lib.AssertEq cycle.state
lib.Assert HasCode ⟨"plan_supersession_cycle",cycle.diagnostics⟩

•Out "test_ledger_plan_retirement_admission: ok"
