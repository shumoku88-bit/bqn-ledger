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
  "account budget:other","  type: Budget","  commodity: USD"
⟩
"ok" lib.AssertEq accountsResult.state
accounts ← accountsResult.accounts
household ← {
  state⇐"ok",source_name⇐"household.toml",
  budget⇐{
    envelope_id⇐⟨"food","transport"⟩,
    allocation_account_key⇐⟨"budget:food","budget:transport"⟩,
    opening_account_keys⇐⟨"budget:opening"⟩,
    unassigned_account_keys⇐⟨"budget:unassigned"⟩
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

# A clean epoch may begin with no Budget movements at all. Zero claims remain
# valid until an explicit opening movement creates stock.
emptyBudget ← Admit ""
emptyResult ← Build emptyBudget
"ok" lib.AssertEq emptyResult.state
⟨0,0⟩ lib.AssertEq emptyResult.managed.entitlement
0 lib.AssertEq emptyResult.unassigned
0 lib.AssertEq emptyResult.observations.count

# One source-ordered relation characterizes direct opening grants, unassigned
# grants/releases, reallocation, independent Envelope totals, pre-start carry,
# observation cutoff, end_exclusive cutoff, mixed exact scales, and provenance.
# There is no legacy spent/execution endpoint in the clean source contract.
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
(0‿2‿3‿4‿4‿5⊏ids) lib.AssertEq result.observations.source_event_id
⟨1,1,0,0,1,1⟩ lib.AssertEq result.observations.source_posting_index
expectedPostingIds ← ⟨
  1⊑(0⊑movements.transactions).postings,
  1⊑(2⊑movements.transactions).postings,
  0⊑(3⊑movements.transactions).postings,
  0⊑(4⊑movements.transactions).postings,
  1⊑(4⊑movements.transactions).postings,
  1⊑(5⊑movements.transactions).postings
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

# Literal 100.50 is canonical at significant scale 1 and remains valid even
# when no Envelope effect exists.
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
# universe; both are published at one observation scale.
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

# Every movement endpoint must be explicitly owned by opening, unassigned, or
# one allocation relation. A merely declared Budget Account has no fallback role.
unknownMovements ← Admit Raw ⟨
  "2026-01-01 opening-unassigned",
  "  budget:opening       -100 USD",
  "  budget:unassigned     100 USD","",
  "2026-01-02 unowned-endpoint",
  "  budget:unassigned    -1 USD",
  "  budget:other          1 USD"
⟩
unknown ← Build unknownMovements
"error" lib.AssertEq unknown.state
"budget_endpoint_ambiguous" lib.AssertEq (⊑unknown.diagnostics).code

# Duplicate endpoint ownership is equally invalid. Current Account metadata is
# not consulted to choose between competing Household relations.
ambiguousHousehold ← {
  state⇐"ok",source_name⇐"household.toml",
  budget⇐{
    envelope_id⇐household.budget.envelope_id,
    allocation_account_key⇐household.budget.allocation_account_key,
    opening_account_keys⇐household.budget.opening_account_keys,
    unassigned_account_keys⇐⟨"budget:unassigned","budget:food"⟩
  }
}
ambiguous ← entitlement.Build ⟨movements,accounts,ambiguousHousehold,"USD",start,finish,observation⟩
"error" lib.AssertEq ambiguous.state
"budget_endpoint_ambiguous" lib.AssertEq (⊑ambiguous.diagnostics).code

# Historical Nonnegative Law:
# Case A: day 1 grant 10, day 2 release 20 => reject.
negA ← Admit Raw ⟨
  "2026-01-01 opening-unassigned",
  "  budget:opening       -100 USD",
  "  budget:unassigned     100 USD","",
  "2026-01-02 grant-food",
  "  budget:unassigned    -10 USD",
  "  budget:food           10 USD","",
  "2026-01-03 over-release-food",
  "  budget:food          -20 USD",
  "  budget:unassigned     20 USD"
⟩
resA ← Build negA
"error" lib.AssertEq resA.state
"envelope_entitlement_negative" lib.AssertEq (⊑resA.diagnostics).code

# Case B: later restoration does not hide an earlier negative state.
negB ← Admit Raw ⟨
  "2026-01-01 opening-unassigned",
  "  budget:opening       -100 USD",
  "  budget:unassigned     100 USD","",
  "2026-01-02 grant-food",
  "  budget:unassigned    -10 USD",
  "  budget:food           10 USD","",
  "2026-01-03 over-release-food",
  "  budget:food          -20 USD",
  "  budget:unassigned     20 USD","",
  "2026-01-04 later-restore-food",
  "  budget:unassigned    -20 USD",
  "  budget:food           20 USD"
⟩
resB ← Build negB
"error" lib.AssertEq resB.state
"envelope_entitlement_negative" lib.AssertEq (⊑resB.diagnostics).code

# Even when observation precedes the future negative movement, global admitted
# history fails closed.
resBFuture ← entitlement.Build ⟨negB,accounts,household,"USD",start,finish,dates.Ordinal "2026-01-02"⟩
"error" lib.AssertEq resBFuture.state
"envelope_entitlement_negative" lib.AssertEq (⊑resBFuture.diagnostics).code

# Same-day release/grant combine before validation, independent of source order.
posC ← Admit Raw ⟨
  "2026-01-01 opening-unassigned",
  "  budget:opening       -100 USD",
  "  budget:unassigned     100 USD","",
  "2026-01-02 same-day-release-first",
  "  budget:food           -5 USD",
  "  budget:unassigned      5 USD","",
  "2026-01-02 same-day-grant-second",
  "  budget:unassigned     -5 USD",
  "  budget:food            5 USD"
⟩
resC ← Build posC
"ok" lib.AssertEq resC.state
⟨0,0⟩ lib.AssertEq resC.managed.entitlement

posD ← Admit Raw ⟨
  "2026-01-01 opening-unassigned",
  "  budget:opening       -100 USD",
  "  budget:unassigned     100 USD","",
  "2026-01-02 same-day-grant-first",
  "  budget:unassigned     -5 USD",
  "  budget:food            5 USD","",
  "2026-01-02 same-day-release-second",
  "  budget:food           -5 USD",
  "  budget:unassigned      5 USD"
⟩
resD ← Build posD
"ok" lib.AssertEq resD.state
⟨0,0⟩ lib.AssertEq resD.managed.entitlement

# Independent Envelope histories remain independent.
negE ← Admit Raw ⟨
  "2026-01-01 opening-unassigned",
  "  budget:opening       -100 USD",
  "  budget:unassigned     100 USD","",
  "2026-01-02 grant-food",
  "  budget:unassigned    -50 USD",
  "  budget:food           50 USD","",
  "2026-01-03 over-release-transport",
  "  budget:transport     -10 USD",
  "  budget:unassigned     10 USD"
⟩
resE ← Build negE
"error" lib.AssertEq resE.state
"envelope_entitlement_negative" lib.AssertEq (⊑resE.diagnostics).code

# Visible representation is not widened by future movements, while future
# negative history still rejects admission.
witnessA ← Admit Raw ⟨
  "2026-01-01 opening-unassigned",
  "  budget:opening       -100 USD",
  "  budget:unassigned     100 USD","",
  "2026-01-02 grant-food",
  "  budget:unassigned    -10 USD",
  "  budget:food           10 USD","",
  "2026-01-15 future-scale-2-grant",
  "  budget:unassigned    -5.25 USD",
  "  budget:food           5.25 USD"
⟩
resWitA ← Build witnessA
"ok" lib.AssertEq resWitA.state
0 lib.AssertEq resWitA.scale
⟨10,0⟩ lib.AssertEq resWitA.managed.entitlement
90 lib.AssertEq resWitA.unassigned
⟨10⟩ lib.AssertEq resWitA.observations.amount

witnessB ← Admit Raw ⟨
  "2026-01-01 opening-unassigned",
  "  budget:opening       -100 USD",
  "  budget:unassigned     100 USD","",
  "2026-01-02 grant-food",
  "  budget:unassigned    -10 USD",
  "  budget:food           10 USD","",
  "2026-01-15 future-unassigned-seed",
  "  budget:opening       -50.55 USD",
  "  budget:unassigned     50.55 USD"
⟩
resWitB ← Build witnessB
"ok" lib.AssertEq resWitB.state
0 lib.AssertEq resWitB.scale
⟨10,0⟩ lib.AssertEq resWitB.managed.entitlement
90 lib.AssertEq resWitB.unassigned
⟨10⟩ lib.AssertEq resWitB.observations.amount

witnessC ← Admit Raw ⟨
  "2026-01-01 opening-unassigned",
  "  budget:opening       -100 USD",
  "  budget:unassigned     100 USD","",
  "2026-01-02 grant-food",
  "  budget:unassigned    -10 USD",
  "  budget:food           10 USD","",
  "2026-01-15 future-over-release",
  "  budget:food         -10.01 USD",
  "  budget:unassigned    10.01 USD"
⟩
resWitC ← Build witnessC
"error" lib.AssertEq resWitC.state
"envelope_entitlement_negative" lib.AssertEq (⊑resWitC.diagnostics).code

witnessD ← Admit Raw ⟨
  "2026-01-01 opening-unassigned",
  "  budget:opening       -100 USD",
  "  budget:unassigned     100 USD","",
  "2026-01-02 grant-food",
  "  budget:unassigned    -10 USD",
  "  budget:food           10 USD","",
  "2026-01-15 future-transport-grant",
  "  budget:unassigned    -5.25 USD",
  "  budget:transport      5.25 USD"
⟩
resWitD ← Build witnessD
"ok" lib.AssertEq resWitD.state
0 lib.AssertEq resWitD.scale
⟨10,0⟩ lib.AssertEq resWitD.managed.entitlement
90 lib.AssertEq resWitD.unassigned
⟨10⟩ lib.AssertEq resWitD.observations.amount

# Exact-range Boundary Law.
openingRows ← ∾10⥊⟨⟨"2026-01-01 opening-food","  budget:opening -999999999999999 USD","  budget:food 999999999999999 USD",""⟩⟩
oneMovement ← ⟨"2026-01-01 grant-food-one","  budget:opening -1 USD","  budget:food 1 USD"⟩
largeSameDay ← Admit Raw (openingRows ∾ oneMovement)
resLargeSameDay ← Build largeSameDay
"error" lib.AssertEq resLargeSameDay.state
"coefficient_sum_failed" lib.AssertEq (⊑resLargeSameDay.diagnostics).code

oneMovementWithBlank ← ⟨"2026-01-01 grant-food-one","  budget:opening -1 USD","  budget:food 1 USD",""⟩
openingRowsLast ← ∾(9⥊⟨⟨"2026-01-01 opening-food","  budget:opening -999999999999999 USD","  budget:food 999999999999999 USD",""⟩⟩) ∾ ⟨⟨"2026-01-01 opening-food","  budget:opening -999999999999999 USD","  budget:food 999999999999999 USD"⟩⟩
largeSameDayReversed ← Admit Raw (oneMovementWithBlank ∾ openingRowsLast)
resLargeSameDayReversed ← Build largeSameDayReversed
"error" lib.AssertEq resLargeSameDayReversed.state
"coefficient_sum_failed" lib.AssertEq (⊑resLargeSameDayReversed.diagnostics).code

largeCum ← Admit Raw ⟨
  "2026-01-01 opening-food","  budget:opening -999999999999999 USD","  budget:food 999999999999999 USD","",
  "2026-01-02 opening-food","  budget:opening -999999999999999 USD","  budget:food 999999999999999 USD","",
  "2026-01-03 opening-food","  budget:opening -999999999999999 USD","  budget:food 999999999999999 USD","",
  "2026-01-04 opening-food","  budget:opening -999999999999999 USD","  budget:food 999999999999999 USD","",
  "2026-01-05 opening-food","  budget:opening -999999999999999 USD","  budget:food 999999999999999 USD","",
  "2026-01-06 opening-food","  budget:opening -999999999999999 USD","  budget:food 999999999999999 USD","",
  "2026-01-07 opening-food","  budget:opening -999999999999999 USD","  budget:food 999999999999999 USD","",
  "2026-01-08 opening-food","  budget:opening -999999999999999 USD","  budget:food 999999999999999 USD","",
  "2026-01-09 opening-food","  budget:opening -999999999999999 USD","  budget:food 999999999999999 USD","",
  "2026-01-10 opening-food","  budget:opening -999999999999999 USD","  budget:food 999999999999999 USD","",
  "2026-01-11 opening-food","  budget:opening -999999999999999 USD","  budget:food 999999999999999 USD","",
  "2026-01-12 grant-food-one","  budget:opening -1 USD","  budget:food 1 USD"
⟩
resLargeCum ← Build largeCum
"error" lib.AssertEq resLargeCum.state
"coefficient_sum_failed" lib.AssertEq (⊑resLargeCum.diagnostics).code

•Out "test_accounting_envelope_entitlement: ok"
