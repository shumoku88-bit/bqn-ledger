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
  "account budget:food","  type: Budget","  commodity: USD","",
  "account budget:transport","  type: Budget","  commodity: USD","",
  "account budget:execution","  type: Budget","  commodity: USD"
⟩
"ok" lib.AssertEq accountsResult.state
accounts ← accountsResult.accounts
household ← {
  state⇐"ok",source_name⇐"household.toml",
  budget⇐{
    envelope_id⇐⟨"food","transport"⟩,
    allocation_account_key⇐⟨"budget:food","budget:transport"⟩,
    unassigned_account_keys⇐⟨"budget:unassigned"⟩
  },
  account_policy⇐{
    account_key⇐accounts.key,
    budget_kind⇐⟨"opening","unassigned","envelope","envelope","spent"⟩,
    envelope_role⇐⟨"","unassigned","dynamic","dynamic","execution"⟩
  }
}
Admit ← {𝕊 raw:
  admitted ← budgetAdmission.Admit ⟨raw,accounts,registry⟩
  "ok" lib.AssertEq admitted.state
  admitted
}
start ← dates.Ordinal "2026-01-01"
finish ← dates.Ordinal "2026-02-01"
observation ← dates.Ordinal "2026-01-10"
Build ← {𝕊 movements:entitlement.Build ⟨movements,accounts,household,"USD",start,finish,observation⟩}

# One source-ordered relation characterizes direct opening grants, unassigned
# grants/releases, reallocation, independent Envelope totals, legacy inert rows,
# pre-start carry, observation cutoff, end_exclusive cutoff, mixed exact scales,
# and Posting/source provenance.
movements ← Admit Raw ⟨
  "2025-12-31 opening-direct",
  "  budget:opening   -12.3 USD",
  "  budget:food       12.3 USD","",
  "2026-01-01 opening-unassigned",
  "  budget:opening       -100.50 USD",
  "  budget:unassigned     100.50 USD","",
  "2026-01-02 grant-food",
  "  budget:unassigned  -4 USD",
  "  budget:food         4 USD","",
  "2026-01-03 release-food",
  "  budget:food        -1.25 USD",
  "  budget:unassigned   1.25 USD","",
  "2026-01-04 reallocate-food-to-transport",
  "  budget:food       -2.0 USD",
  "  budget:transport   2.0 USD","",
  "2026-01-05 legacy-envelope-to-execution",
  "  budget:food       -8 USD",
  "  budget:execution   8 USD","",
  "2026-01-06 legacy-execution-to-envelope",
  "  budget:execution  -9 USD",
  "  budget:transport   9 USD","",
  "2026-01-10 on-observation",
  "  budget:unassigned  -0.75 USD",
  "  budget:transport    0.75 USD","",
  "2026-01-11 after-observation",
  "  budget:unassigned  -50 USD",
  "  budget:food         50 USD","",
  "2026-02-01 at-end-exclusive",
  "  budget:unassigned  -60 USD",
  "  budget:transport    60 USD"
⟩
result ← Build movements
"ok" lib.AssertEq result.state
2 lib.AssertEq result.scale
⟨1305,275⟩ lib.AssertEq result.managed.entitlement
9700 lib.AssertEq result.unassigned
6 lib.AssertEq result.observations.count
⟨1230,400,¯125,¯200,200,75⟩ lib.AssertEq result.observations.amount
⟨"food","food","food","food","transport","transport"⟩ lib.AssertEq result.observations.envelope_id
ids ← {𝕩.source_event_id}¨movements.transactions
(0‿2‿3‿4‿4‿7⊏ids) lib.AssertEq result.observations.source_event_id
⟨1,1,0,0,1,1⟩ lib.AssertEq result.observations.source_posting_index
expectedPostingIds ← ⟨
  1⊑(0⊑movements.transactions).postings,
  1⊑(2⊑movements.transactions).postings,
  0⊑(3⊑movements.transactions).postings,
  0⊑(4⊑movements.transactions).postings,
  1⊑(4⊑movements.transactions).postings,
  1⊑(7⊑movements.transactions).postings
⟩
({𝕩.posting_id}¨expectedPostingIds) lib.AssertEq result.observations.source_posting_id
result.observations.source_posting_id lib.AssertEq ({𝕩.posting_id}¨result.observations.contributors)
lib.Assert 1=∧´"budget.journal"⊸≡¨{𝕩.source}¨result.observations.contributors
⟨4,2⟩ lib.AssertEq ≠¨result.managed.contributors
⟨4⟩ lib.AssertEq ⟨≠result.unassigned_contributors⟩

# A scale-2 unassigned position with no Envelope effect still selects scale 2.
seedOnly ← Admit Raw ⟨
  "2026-01-01 opening-unassigned",
  "  budget:opening       -100.55 USD",
  "  budget:unassigned     100.55 USD"
⟩
seedResult ← Build seedOnly
"ok" lib.AssertEq seedResult.state
2 lib.AssertEq seedResult.scale
⟨0,0⟩ lib.AssertEq seedResult.managed.entitlement
10055 lib.AssertEq seedResult.unassigned
0 lib.AssertEq seedResult.observations.count

# The review's literal 100.50 witness is admitted canonically at significant
# scale 1; with no Envelope effect it must likewise succeed instead of trying
# to normalize its unassigned coefficient to scale 0.
trailingZeroSeed ← Admit Raw ⟨
  "2026-01-01 opening-unassigned",
  "  budget:opening       -100.50 USD",
  "  budget:unassigned     100.50 USD"
⟩
trailingZeroResult ← Build trailingZeroSeed
"ok" lib.AssertEq trailingZeroResult.state
1 lib.AssertEq trailingZeroResult.scale
1005 lib.AssertEq trailingZeroResult.unassigned

# An Envelope effect at scale 1 normalizes exactly to the scale-2 unassigned
# universe; Entitlement and unassigned are published at one observation scale.
lowerEffect ← Admit Raw ⟨
  "2026-01-01 opening-unassigned",
  "  budget:opening       -100.55 USD",
  "  budget:unassigned     100.55 USD","",
  "2026-01-02 grant-food",
  "  budget:unassigned  -4.0 USD",
  "  budget:food         4.0 USD"
⟩
lowerResult ← Build lowerEffect
"ok" lib.AssertEq lowerResult.state
2 lib.AssertEq lowerResult.scale
⟨400,0⟩ lib.AssertEq lowerResult.managed.entitlement
9655 lib.AssertEq lowerResult.unassigned
⟨400⟩ lib.AssertEq lowerResult.observations.amount

# Unknown and multiply-owned movement endpoints fail closed.
unknownHousehold ← {
  state⇐"ok",source_name⇐"household.toml",budget⇐household.budget,
  account_policy⇐{account_key⇐accounts.key,budget_kind⇐⟨"opening","unassigned","envelope","envelope",""⟩}
}
unknown ← entitlement.Build ⟨movements,accounts,unknownHousehold,"USD",start,finish,observation⟩
"error" lib.AssertEq unknown.state
"budget_endpoint_ambiguous" lib.AssertEq (⊑unknown.diagnostics).code

# An allocation Account that still carries legacy envelope_role=execution resolves
# cleanly as an Envelope endpoint; envelope_role is no longer an endpoint authority.
legacyRoleExecutionHousehold ← {
  state⇐"ok",source_name⇐"household.toml",budget⇐household.budget,
  account_policy⇐{
    account_key⇐accounts.key,
    budget_kind⇐⟨"opening","unassigned","envelope","envelope","spent"⟩,
    envelope_role⇐⟨"","unassigned","execution","dynamic","execution"⟩
  }
}
legacyRoleResult ← entitlement.Build ⟨movements,accounts,legacyRoleExecutionHousehold,"USD",start,finish,observation⟩
"ok" lib.AssertEq legacyRoleResult.state
⟨1305,275⟩ lib.AssertEq legacyRoleResult.managed.entitlement

# account_policy without envelope_role column succeeds; Entitlement does not depend on envelope_role.
noEnvelopeRoleHousehold ← {
  state⇐"ok",source_name⇐"household.toml",budget⇐household.budget,
  account_policy⇐{
    account_key⇐accounts.key,
    budget_kind⇐⟨"opening","unassigned","envelope","envelope","spent"⟩
  }
}
noRoleResult ← entitlement.Build ⟨movements,accounts,noEnvelopeRoleHousehold,"USD",start,finish,observation⟩
"ok" lib.AssertEq noRoleResult.state
⟨1305,275⟩ lib.AssertEq noRoleResult.managed.entitlement

ambiguousHousehold ← {
  state⇐"ok",source_name⇐"household.toml",
  budget⇐{envelope_id⇐household.budget.envelope_id,allocation_account_key⇐household.budget.allocation_account_key,unassigned_account_keys⇐⟨"budget:unassigned","budget:food"⟩},
  account_policy⇐household.account_policy
}
ambiguous ← entitlement.Build ⟨movements,accounts,ambiguousHousehold,"USD",start,finish,observation⟩
"error" lib.AssertEq ambiguous.state
"budget_endpoint_ambiguous" lib.AssertEq (⊑ambiguous.diagnostics).code

•Out "test_accounting_envelope_entitlement: ok"
