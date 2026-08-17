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
  registry⇐{id⇐⟨"food"⟩}
}

Admit ← {𝕊 lines:
  admitted ← entitlementAdmission.Admit ⟨Raw lines,history,registry⟩
  "ok" lib.AssertEq admitted.state
  admitted
}
start ← dates.Ordinal "2026-01-01"
finish ← dates.Ordinal "2026-02-01"
observation ← dates.Ordinal "2026-01-31"
Build ← {𝕊 source: entitlement.Build ⟨source,history,"USD",start,finish,observation⟩}

# unallocated is the open boundary endpoint. Releasing an Envelope claim
# to unallocated reduces Entitlement.
releaseSource ← Admit ⟨
  "2026-01-01 origin USD",
  "2026-01-01 transfer unallocated -> food 10 USD ; grant-food",
  "2026-01-02 transfer food -> unallocated 4 USD ; release-food"
⟩
released ← Build releaseSource
"ok" lib.AssertEq released.state
⟨6⟩ lib.AssertEq released.managed.entitlement
2 lib.AssertEq released.observations.count
⟨10,¯4⟩ lib.AssertEq released.observations.amount
⟨"food","food"⟩ lib.AssertEq released.observations.envelope_id
1 lib.AssertEq released.origin.present

# The same projection participates in the global historical nonnegative law.
# A release cannot exceed available entitlement.
overReleaseSourceText ← Raw ⟨
  "2026-01-01 origin USD",
  "2026-01-01 transfer unallocated -> food 10 USD ; grant-food",
  "2026-01-02 transfer food -> unallocated 11 USD ; over-release"
⟩
overReleaseSource ← entitlementAdmission.Admit ⟨overReleaseSourceText,history,registry⟩
"error" lib.AssertEq overReleaseSource.state
"envelope_entitlement_negative" lib.AssertEq (⊑overReleaseSource.diagnostics).code

•Out "test_accounting_envelope_entitlement_opening_release: ok"
