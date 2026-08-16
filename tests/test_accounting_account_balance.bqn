#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
account_admission ← •Import "../src/ledger/account_admission.bqn"
snapshot ← •Import "legacy_snapshot_fixture.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
balance ← •Import "../src/accounting/account_balance.bqn"

base ← "fixtures/ledger-facts-phase1-proof/"
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
accountLines ← loader.ReadLines base∾"accounts.tsv"
facts ← (snapshot.Build ⟨accountLines,•FChars "../"∾base∾"actual.journal",registry⟩).facts
result ← balance.Build ⟨facts,"JPY",dates.Ordinal "2026-01-12"⟩
"ok" lib.AssertEq result.state
7 lib.AssertEq result.accounts.count
⟨965,¯1000,30,5,0,0,0⟩ lib.AssertEq result.accounts.closing
0 lib.AssertEq result.scale
1 lib.AssertEq result.balanced
3 lib.AssertEq ≠0⊑result.accounts.contributors
"actual.journal" lib.AssertEq (⊑0⊑result.accounts.contributors).source
(("JPY"⊸≡¨facts.accounts.currency)/facts.accounts.key) lib.AssertEq result.accounts.account_key
cashAccountIndex ← ⊑result.accounts.account_index
cashPostingMask ← (cashAccountIndex=facts.postings.account_index) ∧ facts.postings.date_ordinal≤result.observation_ordinal
cashPostingIds ← cashPostingMask/facts.postings.posting_id
cashContributorIds ← {𝕩.posting_id}¨⊑result.accounts.contributors
cashPostingIds lib.AssertEq cashContributorIds

atJan10 ← balance.Build ⟨facts,"JPY",dates.Ordinal "2026-01-10"⟩
⟨980,¯1000,20,0,0,0,0⟩ lib.AssertEq atJan10.accounts.closing

lf ← @+10
BuildDomain ← {𝕊 currency‿accountText‿raw:
  lines ← accountText
  admittedAccounts ← (account_admission.Admit ⟨lines,registry⟩).accounts
  domainFacts ← (snapshot.Build ⟨lines,raw,registry⟩).facts
  balance.Build ⟨domainFacts,currency,dates.Ordinal "2026-03-02"⟩
}
ilsLines ← ⟨
  "assets:ils	role=asset	type=liquid	currency=ILS",
  "expenses:a-ils	role=expense	currency=ILS",
  "expenses:b-ils	role=expense	currency=ILS"
⟩
ilsRaw ← ∾⟨
  "commodity ILS",lf,lf,
  "account assets:ils",lf,"    ; role: asset",lf,lf,
  "account expenses:a-ils",lf,"    ; role: expense",lf,lf,
  "account expenses:b-ils",lf,"    ; role: expense",lf,lf,
  "2026-03-01 * a",lf,"    ; event-id: ils-a",lf,"    ; layer: actual",lf,
  "    expenses:a-ils 12.3 ILS",lf,"    assets:ils -12.3 ILS",lf,lf,
  "2026-03-02 * b",lf,"    ; event-id: ils-b",lf,"    ; layer: actual",lf,
  "    expenses:b-ils 0.05 ILS",lf,"    assets:ils -0.05 ILS",lf
⟩
ils ← BuildDomain ⟨"ILS",ilsLines,ilsRaw⟩
"ok" lib.AssertEq ils.state
2 lib.AssertEq ils.scale
⟨¯1235,1230,5⟩ lib.AssertEq ils.accounts.closing

emptyRaw ← ∾⟨
  "commodity USD",lf,lf,
  "account assets:usd",lf,"    ; role: asset",lf,lf,
  "account expenses:usd",lf,"    ; role: expense",lf
⟩
emptyLines ← ⟨"assets:usd	role=asset	currency=USD","expenses:usd	role=expense	currency=USD"⟩
empty ← BuildDomain ⟨"USD",emptyLines,emptyRaw⟩
"ok" lib.AssertEq empty.state
⟨0,0⟩ lib.AssertEq empty.accounts.closing
⟨⟨⟩,⟨⟩⟩ lib.AssertEq empty.accounts.contributors

unknown ← balance.Build ⟨facts,"USD",dates.Ordinal "2026-01-12"⟩
"error" lib.AssertEq unknown.state
0 lib.AssertEq unknown.accounts.count
"domain_unknown" lib.AssertEq (⊑unknown.diagnostics).code
•Out "test_accounting_account_balance: ok"
