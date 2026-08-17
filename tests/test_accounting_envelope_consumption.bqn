#!/usr/bin/env bqn

loader ← •Import "../src/application/source_io.bqn"
registryCore ← •Import "../src/ledger/currency_registry.bqn"
snapshot ← •Import "canonical_snapshot_fixture.bqn"
historyAdmission ← •Import "../src/ledger/envelope_history_admission.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
consumption ← •Import "../src/accounting/envelope_consumption.bqn"
lf ← @+10 ⋄ quote ← @+34
Raw ← {𝕊 lines:∾{𝕩∾⟨lf⟩}¨lines}
Q ← {𝕊 text:⟨quote⟩∾text∾⟨quote⟩}
AssertEq ← {
  𝕨 ≡ 𝕩 ? 1;
  •Out "::error file=tests/test_accounting_envelope_consumption.bqn::expected "∾(•Fmt 𝕨)∾" but got "∾(•Fmt 𝕩)
  •Exit 1
}

base ← "fixtures/ledger-facts-phase1-proof/"
registry ← (registryCore.Build loader.ReadLines "config/currencies.tsv").registry
accountSource ← •FChars "../"∾base∾"accounts.journal"
actualRaw ← •FChars "../"∾base∾"actual.journal"
refundRaw ← Raw ⟨
  "",
  "2026-01-13 * food refund",
  "    ; event-id: proof-refund-1",
  "    ; layer: actual",
  "    ; currency: JPY",
  "    assets:cash 4 JPY",
  "    expenses:food -4 JPY"
⟩
actual ← (snapshot.Build ⟨accountSource,actualRaw∾refundRaw,registry⟩).facts
"ok" AssertEq actual.state

historyRaw ← Raw ⟨
  "[envelope-history]",
  "identities = ["∾(Q "food")∾", "∾(Q "travel")∾"]",
  "",
  "[[envelope-history.expense-routing]]",
  "effective-from = "∾(Q "initial"),
  "expense-account = "∾(Q "expenses:food"),
  "route = "∾(Q "managed"),
  "target = "∾(Q "food"),
  "note = "∾(Q "initial food route"),
  "",
  "[[envelope-history.expense-routing]]",
  "effective-from = "∾(Q "2026-01-11"),
  "expense-account = "∾(Q "expenses:food"),
  "route = "∾(Q "managed"),
  "target = "∾(Q "travel"),
  "note = "∾(Q "food moves to travel"),
  "",
  "[[envelope-history.expense-routing]]",
  "effective-from = "∾(Q "initial"),
  "expense-account = "∾(Q "expenses:transport"),
  "route = "∾(Q "unmanaged"),
  "note = "∾(Q "transport explicitly outside Envelopes")
⟩
history ← historyAdmission.Admit historyRaw
"ok" AssertEq history.state

result ← consumption.Build ⟨actual,history,"JPY",dates.Ordinal "2026-01-01",dates.Ordinal "2026-01-14"⟩
"ok" AssertEq result.state
⟨"food","travel"⟩ AssertEq result.managed.envelope_id
⟨20,10⟩ AssertEq result.managed.consumption
⟨0,4⟩ AssertEq result.managed.refunds
0 AssertEq result.unrouted.count
1 AssertEq result.unmanaged.count
⟨"expenses:transport"⟩ AssertEq result.unmanaged.account_key
⟨5⟩ AssertEq result.unmanaged.coefficient
4 AssertEq result.evidence.count
⟨"managed","managed","unmanaged","managed"⟩ AssertEq result.evidence.route
⟨"food","travel","","travel"⟩ AssertEq result.evidence.target_id
"actual.journal" AssertEq (⊑⊑result.managed.consumption_contributors).source
"actual.journal" AssertEq (⊑result.unmanaged.contributors).source

# Missing history is attention evidence. It never falls back to a current
# envelope.toml assignment because current policy is not an input to this owner.
missingTransportRaw ← Raw ⟨
  "[envelope-history]",
  "identities = ["∾(Q "food")∾", "∾(Q "travel")∾"]",
  "",
  "[[envelope-history.expense-routing]]",
  "effective-from = "∾(Q "initial"),
  "expense-account = "∾(Q "expenses:food"),
  "route = "∾(Q "managed"),
  "target = "∾(Q "food"),
  "note = "∾(Q "initial food route"),
  "",
  "[[envelope-history.expense-routing]]",
  "effective-from = "∾(Q "2026-01-11"),
  "expense-account = "∾(Q "expenses:food"),
  "route = "∾(Q "managed"),
  "target = "∾(Q "travel"),
  "note = "∾(Q "food moves to travel")
⟩
missingTransportHistory ← historyAdmission.Admit missingTransportRaw
missingTransport ← consumption.Build ⟨actual,missingTransportHistory,"JPY",dates.Ordinal "2026-01-01",dates.Ordinal "2026-01-14"⟩
"ok" AssertEq missingTransport.state
1 AssertEq missingTransport.unrouted.count
0 AssertEq missingTransport.unmanaged.count
⟨"expenses:transport"⟩ AssertEq missingTransport.unrouted.account_key

# A route becoming effective inside the statement period applies only from that
# Posting day onward. Account-first aggregation would incorrectly erase this law.
jan10 ← result.evidence.date_ordinal=dates.Ordinal "2026-01-10"
jan12 ← result.evidence.date_ordinal=dates.Ordinal "2026-01-12"
⟨"food"⟩ AssertEq jan10/result.evidence.target_id
⟨"travel",""⟩ AssertEq jan12/result.evidence.target_id

•Out "test_accounting_envelope_consumption: ok"
