#!/usr/bin/env bqn

ak ← •Import "../src_next/account_key.bqn"
admission ← •Import "../src_next/journal_supported_single_currency_admission_for_test.bqn"

lf ← @+10
Raw ← {𝕊 lines: ∾ (lines ∾¨ lf) }

resolved ← ak.Resolve ⟨⟩
ilsRaw ← Raw ⟨"commodity ILS"⟩
ils ← admission.Admit ⟨ilsRaw, resolved⟩

•Out "test_journal_supported_single_currency_admission_proof.bqn: EMPTY CALL OK"
