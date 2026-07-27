#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
cycle ← •Import "../src_next/cycle.bqn"
loader ← •Import "../src_next/loader.bqn"
ak ← •Import "../src_next/account_key.bqn"
actual_source ← •Import "../src_next/actual_source.bqn"
admission ← •Import "../src/ledger/journal_complete_admission.bqn"
setup ← •Import "../src_next/currency_setup.bqn"

# The prepared-evidence fixture deliberately has no config, accounts, or Actual
# Journal. Success proves this adapter does not fall back to source reloading.
Posting ← {𝕊 account‿coefficient: {account_key⇐account, normalized_coefficient⇐coefficient} }
Transaction ← {𝕊 dateText‿postings: {date⇐dateText, postings⇐postings} }
transactions ← ⟨
  Transaction ⟨"2026-06-15", ⟨Posting ⟨"income:salary", ¯100⟩, Posting ⟨"assets:bank", 100⟩⟩⟩,
  Transaction ⟨"2026-06-20", ⟨Posting ⟨"assets:bank", ¯5⟩, Posting ⟨"expenses:food", 5⟩⟩⟩
⟩

# Report consumers can derive dates from their context without touching base.
# The deliberately missing base makes any accidental source fallback fail.
preparedContext ← {base⇐"fixtures/does-not-exist", actual_transactions⇐transactions}
⟨"2026-06-15", "2026-06-20"⟩ lib.AssertEq actual_source.DatesFromContext preparedContext

preparedOnly ← cycle.ReadCycleFromAdmittedTransactions ⟨"fixtures/cycle-prepared-evidence", transactions⟩
"incomeAnchor" lib.AssertEq preparedOnly.mode
"2026-06-15" lib.AssertEq preparedOnly.start
"2026-07-15" lib.AssertEq preparedOnly.end_exclusive
30 lib.AssertEq preparedOnly.day_count

# The compatibility evidence carrier may contain the historical fallback shape;
# cycle interpretation preserves its delta-based income semantics without I/O.
LegacyPosting ← {𝕊 account‿delta: {account_key⇐account, delta⇐delta} }
LegacyTransaction ← {𝕊 dateText‿postings: {date⇐dateText,description⇐"prepared completion",plan_id⇐"pid-"∾dateText,postings⇐postings} }
legacyTransactions ← ⟨
  LegacyTransaction ⟨"2026-06-15", ⟨LegacyPosting ⟨"income:salary", ¯100⟩, LegacyPosting ⟨"assets:bank", 100⟩⟩⟩,
  LegacyTransaction ⟨"2026-06-20", ⟨LegacyPosting ⟨"assets:bank", ¯5⟩, LegacyPosting ⟨"expenses:food", 5⟩⟩⟩
⟩
legacyEvidence ← {complete⇐0, transactions⇐legacyTransactions}
legacyPrepared ← cycle.ReadCycleFromActualEvidence ⟨"fixtures/cycle-prepared-evidence", legacyEvidence⟩
preparedOnly.mode lib.AssertEq legacyPrepared.mode
preparedOnly.start lib.AssertEq legacyPrepared.start
preparedOnly.end_exclusive lib.AssertEq legacyPrepared.end_exclusive
preparedOnly.day_count lib.AssertEq legacyPrepared.day_count

# Completion and plan-ID consumers reuse the same historical transaction shape
# from context without touching the deliberately missing base.
legacyContext ← {base⇐"fixtures/does-not-exist",cy⇐preparedOnly,actual_transactions⇐legacyTransactions}
completion ← actual_source.CompletionEvidenceFromContext legacyContext
2 lib.AssertEq ≠ completion
⟨"pid-2026-06-15", "pid-2026-06-20"⟩ lib.AssertEq {𝕩.plan_id}¨completion
⟨100, 5⟩ lib.AssertEq {𝕩.amount}¨completion
⟨"pid-2026-06-15", "pid-2026-06-20"⟩ lib.AssertEq actual_source.PlanIdsInCycleFromContext legacyContext

# On a complete production fixture, source-loaded and already-admitted evidence
# resolve the same cycle contract.
base ← "fixtures/src-next-income-anchor-golden"
resolved ← ak.Resolve loader.ReadLines (base ∾ "/accounts.tsv")
sourceFile ← actual_source.ResolveRelativePath base
raw ← loader.ReadRaw (base ∾ "/" ∾ sourceFile)
admittedAccounts ← {key⇐resolved.accounts,currency⇐resolved.currencies}
admitted ← admission.Admit ⟨raw,admittedAccounts,setup.registry_value⟩
"ok" lib.AssertEq admitted.state

loadedCycle ← cycle.ReadCycle base
preparedCycle ← cycle.ReadCycleFromAdmittedTransactions ⟨base, admitted.transactions⟩
loadedCycle.mode lib.AssertEq preparedCycle.mode
loadedCycle.start lib.AssertEq preparedCycle.start
loadedCycle.end_exclusive lib.AssertEq preparedCycle.end_exclusive
loadedCycle.day_count lib.AssertEq preparedCycle.day_count

•Out "test_src_next_cycle_prepared_evidence.bqn: OK"
