# Multi-currency Journal container contract

Status: selected docs-only contract decision
Date: 2026-07-25
Owner: native Journal admission and currency-domain boundary
Scope: public-synthetic design evidence only

## 1. Decision

A single native Journal file may contain ordinary transactions from more than one registry-supported currency domain.

The Journal file is therefore a **multi-currency container**, but ordinary arithmetic remains **single-domain per transaction**.

This decision replaces the narrower assumption that one complete Journal file must have exactly one arithmetic domain.

It does not authorize production parser, writer, Stage 2A, context, Cube, TBDS, report, editor, source-data, metadata, FX, valuation, or travel changes.

## 2. Required distinction

The following is admitted as the target contract:

```text
one Journal file
  transaction A: JPY postings only, balanced in JPY
  transaction B: ILS postings only, balanced in ILS
  transaction C: USD postings only, balanced in USD
```

The following is not admitted as an ordinary transaction by this contract:

```text
one ordinary transaction
  JPY posting
  ILS posting
  implicit conversion or cross-currency cancellation
```

A Journal may contain multiple currencies without any permission to add, compare, offset, value, or total unlike currencies.

## 3. Source authority

Currency facts come from explicit source evidence and the account registry.

For each ordinary transaction:

1. every posting has an explicit commodity code;
2. every posting commodity is registry-supported;
3. every posting account resolves exactly once;
4. every posting account currency equals the posting commodity;
5. all postings in the transaction share exactly one currency domain;
6. all posting amounts obey that domain's precision policy;
7. all postings normalize to one transaction calculation scale;
8. normalized coefficients sum to zero within that transaction.

Configuration or caller selection may request a currency view, but must not rewrite or manufacture source currency facts.

## 4. Parser result contract

A future complete-source admission result must not expose one Journal-wide `domain` field as if the whole file had one arithmetic domain.

The minimum successful result shape is conceptually:

```text
journal
  declared_domains
  transactions
    source identity and provenance
    domain
    calculation_scale
    normalized postings
      account_key
      account_currency
      commodity
      source amount text
      source coefficient
      source scale
      normalized coefficient
      source line
  diagnostics
```

The parser may also expose a derived domain partition index, but the transaction remains the first arithmetic authorization boundary.

## 5. Arithmetic rule

No operation may add coefficients unless their currency domain and calculation scale have been proven compatible.

A consumer has only two initially permitted choices:

1. select exactly one currency domain and calculate within it; or
2. return separate currency partitions without a combined total.

The following remain prohibited:

- JPY + ILS totals;
- implicit FX conversion;
- default-currency valuation;
- comparison of unlike currency coefficients as money;
- silently dropping the commodity or scale;
- inferring currency from account names, country, trip, payment method, or description.

## 6. Exchange boundary

A cross-currency exchange is not an ordinary single-domain transaction under this contract.

The current account-explicit exchange event rail remains the available evidence shape for JPY→ILS exchange.

A future decision may admit an explicit typed exchange transaction into the Journal, but only with separately selected semantics for:

- source quantity and source currency;
- destination quantity and destination currency;
- fees;
- rate or cost evidence when present;
- account ownership;
- provenance;
- reversal and correction;
- reporting without treating exchange as expense.

Until that decision is selected, an ordinary transaction containing more than one currency domain must fail closed.

## 7. Relation to the completed test-only proof

The merged test-only supported-single-currency proof remains valid evidence for one transaction or one same-domain partition.

It already demonstrates reusable registry-driven behavior for ILS and USD:

- exact-decimal parsing;
- precision validation;
- account-currency equality;
- normalized coefficient and scale evidence;
- balanced ordinary transaction evidence;
- privacy-safe diagnostics;
- reuse of unchanged Stage 1 structural validation.

The next proof must compose these properties across multiple ordinary transactions in one raw Journal without creating a Journal-wide arithmetic domain.

## 8. Stage 1 ownership direction

The preferred production direction is a complete-source admission wrapper rather than silently widening the historical profiles.

The wrapper should:

1. preserve the raw Journal as source truth;
2. identify all declared supported commodity domains;
3. establish a domain and calculation scale for each ordinary transaction;
4. reject mixed-domain ordinary transactions;
5. delegate date, declaration, metadata, identity, and transaction structure checks to a common structural parser;
6. return transaction-domain evidence without converting it to JPY;
7. preserve existing JPY behavior and diagnostics.

The existing integer-JPY structural shadow is test evidence only. It is not selected as the permanent production representation.

## 9. Stage 2A and context implications

A future Stage 2A carrier must retain, at minimum:

- posting currency domain;
- calculation scale;
- normalized coefficient;
- source amount text and scale;
- account-currency proof;
- source provenance.

The current context and Cube must not receive mixed-domain coefficients as one arithmetic input.

A future context decision must choose one of these explicitly:

1. build one selected-currency context at a time; or
2. build separate contexts or partitions per currency.

This contract does not automatically add a Currency axis to the Canonical Daily Cube.

## 10. Consumer implications

Balances and reports must never display a combined multi-currency money total.

Initially, a consumer must either:

- require an explicit selected currency; or
- display separately labelled currency sections.

Formatting must use each partition's registry precision and symbol policy.

## 11. Writer implications

A future ordinary-add writer must accept an explicit currency domain and prove that:

- the domain is registry-supported;
- every selected account belongs to that domain;
- every posting amount obeys domain precision;
- the transaction balances after exact normalization;
- the Journal declaration surface admits that domain.

The writer must not infer currency from account names and must not create accounts automatically.

## 12. Finite continuation order

The recommended independently selected order is:

1. **Test-only multi-currency Journal container proof** — one public-synthetic raw Journal containing separate balanced JPY and ILS transactions, plus an equivalent USD witness; mixed-domain ordinary transactions fail closed.
2. **Production complete-source admission contract implementation** — transaction-domain output without silently widening historical profiles.
3. **Stage 2A currency-proof carrier** — retain domain, scale, normalized coefficient, and provenance.
4. **Selected-domain context composition** — one currency view at a time, with companion-source domain equality proven.
5. **Native ordinary-add writer widening** — explicit supported currency, preserving JPY parity.
6. **Per-domain consumer and formatting verification**.
7. **Explicit exchange-in-Journal design**, only if still desired after observing the separate exchange rail.

Each item requires a separate selection.

## 13. Acceptance criteria for this contract decision

This decision is satisfied when the repository records all of the following without runtime widening:

- one Journal file may contain JPY and ILS ordinary transactions;
- each ordinary transaction has exactly one arithmetic domain;
- USD remains a second generality witness;
- unlike currencies are never added;
- a mixed-domain ordinary transaction is rejected;
- exchange remains separately typed and unbundled;
- Stage 1, Stage 2A, context, writer, and consumers remain separately selected work;
- no private production data is used to decide policy.

## 14. Non-goals

This contract does not add or authorize:

- production multi-currency Journal parsing;
- a mixed-currency transaction;
- FX or valuation;
- a reporting currency;
- automatic conversion;
- a Currency axis;
- travel metadata;
- reverse exchange;
- friend finalization;
- Wise semantics;
- account creation;
- source-data edits;
- private-data inspection.
