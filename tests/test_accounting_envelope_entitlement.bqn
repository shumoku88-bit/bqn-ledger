#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registryCore ← •Import "../src/ledger/currency_registry.bqn"
snapshot ← •Import "legacy_snapshot_fixture.bqn"
canonicalBudget ← •Import "canonical_budget_test_facts.bqn"
entitlement ← •Import "../src/accounting/envelope_entitlement.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"

tab ← @+9 ⋄ lf ← @+10
Join ← {𝕊 fields: out ← ⊑fields ⋄ {𝕊 field:out∾↩tab∾field}¨1↓fields ⋄ out}
Raw ← {𝕊 lines:∾lines∾¨lf}
base ← "fixtures/ledger-facts-phase1-proof/"
registry ← (registryCore.Build loader.ReadLines "config/currencies.tsv").registry
accountLines ← loader.ReadLines base∾"accounts.tsv"
actual ← (snapshot.Build ⟨accountLines,•FChars "../"∾base∾"actual.journal",registry⟩).facts

budgetRaw ← Raw ⟨
  "2026-01-01 opening-grant",
  "  budget:opening     -100 JPY",
  "  budget:unassigned   100 JPY","",
  "2026-01-02 grant-food",
  "  budget:unassigned  -10 JPY",
  "  budget:food         10 JPY","",
  "2026-01-03 release-food",
  "  budget:food         -3 JPY",
  "  budget:unassigned    3 JPY","",
  "2026-01-04 legacy-execution",
  "  budget:food         -5 JPY",
  "  budget:spent         5 JPY","",
  "2026-01-05 legacy-execution-reverse",
  "  budget:spent        -7 JPY",
  "  budget:food           7 JPY","",
  "2026-01-20 after-observation",
  "  budget:unassigned -100 JPY",
  "  budget:food        100 JPY","",
  "2026-02-01 at-period-end",
  "  budget:unassigned   -9 JPY",
  "  budget:food           9 JPY"
⟩
budget ← (canonicalBudget.Build ⟨budgetRaw,actual.accounts,registry⟩).facts
"ok" lib.AssertEq budget.state

household ← {
  state⇐"ok",source_name⇐"household.toml",
  budget⇐{
    envelope_id⇐⟨"food"⟩,
    allocation_account_key⇐⟨"budget:food"⟩,
    unassigned_account_keys⇐⟨"budget:unassigned"⟩
  },
  account_policy⇐{
    account_key⇐actual.accounts.key,
    budget_kind⇐⟨"", "", "", "", "opening", "unassigned", "envelope", "spent"⟩,
    envelope_role⇐⟨"", "", "", "", "", "unassigned", "dynamic", "execution"⟩
  }
}
start ← dates.Ordinal "2026-01-01"
finish ← dates.Ordinal "2026-02-01"
observation ← dates.Ordinal "2026-01-09"
result ← entitlement.Build ⟨budget,household,"JPY",start,finish,observation⟩
"ok" lib.AssertEq result.state
⟨7⟩ lib.AssertEq result.managed.entitlement
⟨"budget.journal:line:5","budget.journal:line:9"⟩ lib.AssertEq result.observations.source_event_id
⟨10,¯3⟩ lib.AssertEq result.observations.amount
⟨"food","food"⟩ lib.AssertEq result.observations.envelope_id
⟨93⟩ lib.AssertEq ⟨result.unassigned⟩
"budget.journal" lib.AssertEq (⊑result.observations.contributors).source
"budget.journal" lib.AssertEq (⊑result.unassigned_contributors).source

# A post-observation movement and a movement on end_exclusive do not alter the
# observed relation. Legacy execution rows remain readable but inert.
⟨7⟩ lib.AssertEq result.managed.entitlement
⟨"budget.journal:line:5","budget.journal:line:9"⟩ lib.AssertEq result.observations.source_event_id

# Duplicate endpoint ownership fails closed before publication.
ambiguous ← {
  state⇐"ok",source_name⇐"household.toml",
  budget⇐{envelope_id⇐⟨"food"⟩,allocation_account_key⇐⟨"budget:unassigned"⟩,unassigned_account_keys⇐⟨"budget:unassigned"⟩},
  account_policy⇐household.account_policy
}
ambiguousResult ← entitlement.Build ⟨budget,ambiguous,"JPY",start,finish,observation⟩
"error" lib.AssertEq ambiguousResult.state
"budget_endpoint_ambiguous" lib.AssertEq (⊑ambiguousResult.diagnostics).code

•Out "test_accounting_envelope_entitlement: ok"
