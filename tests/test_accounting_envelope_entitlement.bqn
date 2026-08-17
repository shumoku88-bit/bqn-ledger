#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
io ← •Import "../src/application/source_io.bqn"
registryCore ← •Import "../src/ledger/currency_registry.bqn"
entitlementAdmission ← •Import "../src/ledger/entitlement_journal_admission.bqn"
entitlement ← •Import "../src/accounting/envelope_entitlement.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"

lf ← @+10
Raw ← {𝕊 lines: ∾lines∾¨lf}
registry ← (registryCore.Build io.ReadLines "config/currencies.tsv").registry

history ← {
  state⇐"ok",source_name⇐"household.toml",
  registry⇐{id⇐⟨"food","transport"⟩}
}

Admit ← {𝕊 raw:
  admitted ← entitlementAdmission.Admit ⟨raw,history,registry⟩
  "ok" lib.AssertEq admitted.state
  admitted
}

start ← dates.Ordinal "2026-01-01"
finish ← dates.Ordinal "2026-02-01"
observation ← dates.Ordinal "2026-01-10"
Build ← {𝕊 source: entitlement.Build ⟨source,history,"USD",start,finish,observation⟩}

# A clean epoch may begin with no Entitlement movements at all. Zero claims remain
# valid until an explicit StockOrigin and transfer creates stock.
emptySource ← Admit ""
emptyResult ← Build emptySource
"ok" lib.AssertEq emptyResult.state
⟨0,0⟩ lib.AssertEq emptyResult.managed.entitlement
0 lib.AssertEq emptyResult.observations.count
0 lib.AssertEq emptyResult.origin.present

# One source-ordered relation characterizes direct StockOrigin, unallocated
# allocations/releases, reallocation, independent Envelope totals, pre-start carry,
# observation cutoff, end_exclusive cutoff, mixed exact scales, and provenance.
sampleText ← Raw ⟨
  "2025-12-31 origin USD ; clean epoch start",
  "2025-12-31 transfer unallocated -> food 12.3 USD ; opening-direct",
  "2026-01-02 transfer unallocated -> food 4 USD ; grant-food",
  "2026-01-03 transfer food -> unallocated 1.25 USD ; release-food",
  "2026-01-04 transfer food -> transport 2.0 USD ; reallocate-food-to-transport",
  "2026-01-10 transfer unallocated -> transport 0.75 USD ; on-observation",
  "2026-01-11 transfer unallocated -> food 50 USD ; after-observation",
  "2026-02-01 transfer unallocated -> transport 60 USD ; at-end-exclusive"
⟩
source ← Admit sampleText
result ← Build source
"ok" lib.AssertEq result.state
2 lib.AssertEq result.scale
⟨1305,275⟩ lib.AssertEq result.managed.entitlement
6 lib.AssertEq result.observations.count
⟨1230,400,¯125,¯200,200,75⟩ lib.AssertEq result.observations.amount
⟨"food","food","food","food","transport","transport"⟩ lib.AssertEq result.observations.envelope_id
1 lib.AssertEq result.origin.present
"USD" lib.AssertEq result.origin.commodity
(dates.Ordinal "2025-12-31") lib.AssertEq result.origin.date_ordinal
"clean epoch start" lib.AssertEq result.origin.memo
"entitlement.journal:line:1" lib.AssertEq result.origin.source_event_id

# Provenance: contributors point to entitlement.journal
lib.Assert 1=∧´"entitlement.journal"⊸≡¨{𝕩.source}¨result.observations.contributors
⟨4,2⟩ lib.AssertEq ≠¨result.managed.contributors

# StockOrigin only with no transfers
originOnlySource ← Admit Raw ⟨"2026-01-01 origin USD ; epoch"⟩
originOnlyResult ← Build originOnlySource
"ok" lib.AssertEq originOnlyResult.state
0 lib.AssertEq originOnlyResult.scale
⟨0,0⟩ lib.AssertEq originOnlyResult.managed.entitlement
0 lib.AssertEq originOnlyResult.observations.count
1 lib.AssertEq originOnlyResult.origin.present

# Historical Nonnegative Law:
# Case A: day 1 grant 10, day 2 release 20 => reject.
negAText ← Raw ⟨
  "2026-01-01 origin USD",
  "2026-01-02 transfer unallocated -> food 10 USD",
  "2026-01-03 transfer food -> unallocated 20 USD"
⟩
negA ← entitlementAdmission.Admit ⟨negAText,history,registry⟩
"error" lib.AssertEq negA.state
"envelope_entitlement_negative" lib.AssertEq (⊑negA.diagnostics).code

# Case B: later restoration does not hide an earlier negative state.
negBText ← Raw ⟨
  "2026-01-01 origin USD",
  "2026-01-02 transfer unallocated -> food 10 USD",
  "2026-01-03 transfer food -> unallocated 20 USD",
  "2026-01-04 transfer unallocated -> food 20 USD"
⟩
negB ← entitlementAdmission.Admit ⟨negBText,history,registry⟩
"error" lib.AssertEq negB.state
"envelope_entitlement_negative" lib.AssertEq (⊑negB.diagnostics).code

# Same-day release/grant combine before validation, independent of source order.
posC ← Admit Raw ⟨
  "2026-01-01 origin USD",
  "2026-01-02 transfer food -> unallocated 5 USD",
  "2026-01-02 transfer unallocated -> food 5 USD"
⟩
resC ← Build posC
"ok" lib.AssertEq resC.state
⟨0,0⟩ lib.AssertEq resC.managed.entitlement

posD ← Admit Raw ⟨
  "2026-01-01 origin USD",
  "2026-01-02 transfer unallocated -> food 5 USD",
  "2026-01-02 transfer food -> unallocated 5 USD"
⟩
resD ← Build posD
"ok" lib.AssertEq resD.state
⟨0,0⟩ lib.AssertEq resD.managed.entitlement

# Independent Envelope histories remain independent.
negEText ← Raw ⟨
  "2026-01-01 origin USD",
  "2026-01-02 transfer unallocated -> food 50 USD",
  "2026-01-03 transfer transport -> unallocated 10 USD"
⟩
negE ← entitlementAdmission.Admit ⟨negEText,history,registry⟩
"error" lib.AssertEq negE.state
"envelope_entitlement_negative" lib.AssertEq (⊑negE.diagnostics).code

# Exact-range Boundary Law
openingRows ← ∾10⥊⟨⟨"2026-01-01 transfer unallocated -> food 999999999999999 USD"⟩⟩
oneMovement ← ⟨"2026-01-01 transfer unallocated -> food 1 USD"⟩
largeSameDayText ← Raw (⟨"2026-01-01 origin USD"⟩ ∾ openingRows ∾ oneMovement)
largeSameDay ← entitlementAdmission.Admit ⟨largeSameDayText,history,registry⟩
"error" lib.AssertEq largeSameDay.state
"coefficient_sum_failed" lib.AssertEq (⊑largeSameDay.diagnostics).code

•Out "test_accounting_envelope_entitlement: ok"
