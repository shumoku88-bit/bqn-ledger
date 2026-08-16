#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
io ← •Import "../src/application/source_io.bqn"
registryCore ← •Import "../src/ledger/currency_registry.bqn"
accountAdmission ← •Import "../src/ledger/account_journal_admission.bqn"
budgetAdmission ← •Import "../src/ledger/budget_journal_admission.bqn"
entitlement ← •Import "../src/accounting/envelope_entitlement.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"

lf ← @+10
Raw ← {𝕊 lines:∾lines∾¨lf}
registry ← (registryCore.Build io.ReadLines "config/currencies.tsv").registry
accountsResult ← accountAdmission.Admit Raw ⟨
  "account budget:opening","  type: Budget","  commodity: USD","",
  "account budget:unassigned","  type: Budget","  commodity: USD","",
  "account budget:food","  type: Budget","  commodity: USD"
⟩
"ok" lib.AssertEq accountsResult.state
accounts ← accountsResult.accounts
household ← {
  state⇐"ok",source_name⇐"household.toml",
  budget⇐{
    envelope_id⇐⟨"food"⟩,
    allocation_account_key⇐⟨"budget:food"⟩,
    opening_account_keys⇐⟨"budget:opening"⟩,
    unassigned_account_keys⇐⟨"budget:unassigned"⟩
  }
}
Admit ← {𝕊 lines:
  admitted ← budgetAdmission.Admit ⟨Raw lines,accounts,registry⟩
  "ok" lib.AssertEq admitted.state
  admitted
}
start ← dates.Ordinal "2026-01-01"
finish ← dates.Ordinal "2026-02-01"
observation ← dates.Ordinal "2026-01-31"
Build ← {𝕊 movements:entitlement.Build ⟨movements,accounts,household,"USD",start,finish,observation⟩}

# Opening and unassigned are both native source-side coordinates. Returning an
# Envelope claim to either source coordinate must reduce Entitlement rather than
# disappear merely because Opening is not the published unassigned balance.
releaseToOpening ← Admit ⟨
  "2026-01-01 grant-food",
  "  budget:opening -10 USD",
  "  budget:food 10 USD","",
  "2026-01-02 release-food-to-opening",
  "  budget:food -4 USD",
  "  budget:opening 4 USD"
⟩
released ← Build releaseToOpening
"ok" lib.AssertEq released.state
⟨6⟩ lib.AssertEq released.managed.entitlement
0 lib.AssertEq released.unassigned
2 lib.AssertEq released.observations.count
⟨10,¯4⟩ lib.AssertEq released.observations.amount
⟨"food","food"⟩ lib.AssertEq released.observations.envelope_id
⟨1,0⟩ lib.AssertEq released.observations.source_posting_index
released.observations.source_posting_id lib.AssertEq ({𝕩.posting_id}¨released.observations.contributors)

# The same projection participates in the global historical nonnegative law.
# A release to Opening cannot bypass the law by disappearing from Entitlement.
overReleaseToOpening ← Admit ⟨
  "2026-01-01 grant-food",
  "  budget:opening -10 USD",
  "  budget:food 10 USD","",
  "2026-01-02 over-release-food-to-opening",
  "  budget:food -11 USD",
  "  budget:opening 11 USD"
⟩
overReleased ← Build overReleaseToOpening
"error" lib.AssertEq overReleased.state
"envelope_entitlement_negative" lib.AssertEq (⊑overReleased.diagnostics).code

•Out "test_accounting_envelope_entitlement_opening_release: ok"
