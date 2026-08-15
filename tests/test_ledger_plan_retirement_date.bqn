#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
planAdmission ← •Import "../src/ledger/plan_journal_admission.bqn"

Meta ← {𝕊 key‿value:{key⇐key,value⇐value,source_line⇐1}}
Txn ← {𝕊 planId‿metadata:{plan_id⇐planId,metadata⇐metadata,source_start_line⇐1}}
HasCode ← {𝕊 code‿diagnostics:∨´0∾{𝕩.code≡code}¨diagnostics}

badCancelled ← planAdmission.AdmitRetirements ⟨
  Txn ⟨"bad-cancel",⟨Meta ⟨"cancelled-on","2026-02-30"⟩⟩⟩
⟩
"error" lib.AssertEq badCancelled.state
lib.Assert HasCode ⟨"plan_retirement_date_invalid",badCancelled.diagnostics⟩

badSuperseded ← planAdmission.AdmitRetirements ⟨
  Txn ⟨"old",⟨Meta ⟨"superseded-on","2026-13-01"⟩,Meta ⟨"superseded-by","new"⟩⟩⟩,
  Txn ⟨"new",⟨⟩⟩
⟩
"error" lib.AssertEq badSuperseded.state
lib.Assert HasCode ⟨"plan_retirement_date_invalid",badSuperseded.diagnostics⟩

•Out "test_ledger_plan_retirement_date: ok"
