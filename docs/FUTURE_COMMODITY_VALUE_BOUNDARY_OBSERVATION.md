# Future Commodity / Value Boundary Observation

Status: observation only
Date: 2026-08-11
Scope: future-proofing review; no implementation roadmap
Related: `docs/CURRENCY_AWARENESS_CAMPAIGN_MAP.md`, `docs/CURRENCY_STAGE1_AMOUNT_SEMANTICS_DECISION.md`

## Purpose

Record the boundaries that should remain open if this Household ledger later needs to represent a life that is not JPY-only and not money-only.

The goal is deliberately narrower than implementing multi-currency, securities, crypto assets, points, FX, valuation, tax lots, or reconciliation now.

The acceptance rule for this observation is:

> An unimplemented future capability is acceptable. A current representation that makes the future meaning impossible to add without silently rewriting historical evidence is the risk.

Do not turn this document into a feature checklist or use it to justify speculative framework code.

## Current evidence

The repository already has a currency-specific registry owner. `config/currencies.tsv` currently admits JPY, ILS, and USD with currency-specific fraction/display policy. The currency registry is data-driven rather than a `JPY`/`USD` branch scattered through accounting code.

The existing Currency Awareness work already preserves important separations:

```text
amount != currency
original_amount != reporting_value
currency != exchange_rate
transaction_date != rate_observation_date
rate_observation_date != valuation_date
valuation_date != report_coordinate
```

Those separations remain valid and should be extended, not collapsed, if broader commodity/value semantics ever become concrete.

## Currency pressure cases worth keeping in view

Supporting every ISO currency now is not a goal. A small set of intentionally different examples is more useful than a long list of codes because it catches distinct hidden assumptions.

```text
JPY  -> ordinary zero-fraction household money
USD  -> ordinary two-fraction money and ambiguous "$" symbol family
EUR  -> major external household currency and currency-transition destination
ILS  -> already-proven non-JPY decimal household currency
GBP  -> another major two-fraction currency
CHF  -> reminder that accounting precision and physical-cash denomination policy differ
INR  -> reminder that numeric grouping/presentation is locale policy, not amount semantics
KWD  -> three-fraction currency; "money always has 0 or 2 decimals" is invalid
```

EUR is especially useful as the next ordinary registry witness because it is not currently in `config/currencies.tsv`. KWD is useful even if never used operationally because it catches a two-decimal assumption. INR is useful even if internal numbers never adopt Indian digit grouping because it catches presentation leaking into arithmetic/source meaning.

Do not encode these examples as a permanent closed currency enum merely because they are useful tests.

## Currency is not the widest future domain

A household may later need quantities that are not ordinary fiat currency:

```text
securities / funds
crypto assets
precious metals
reward points / miles
stored-value or gift balances
foreign cash
physical inventory or other countable assets
possibly time or another user-defined unit
```

This observation does not decide that bqn-ledger must support any of them.

It does decide that `Currency` should not quietly become the universal identity for every countable thing. The current `currency_registry.bqn` has a clear currency-specific responsibility: supported monetary codes, fraction policy, and symbol policy. Do not force AAPL, BTC, airline miles, or kilograms into that owner merely to reuse an existing table.

If a concrete non-currency requirement appears, first decide whether a broader `Commodity` identity is needed and how currency becomes one kind/policy of commodity. Do not rename or genericize the existing currency registry speculatively.

## Non-equivalences to preserve

Future work should keep these meanings separable:

```text
commodity identity != display symbol
commodity identity != display name
quantity != monetary value
quantity != reporting value
source amount != current market value
cost != price observation
cost != valuation
price observation != valuation policy
transaction date != settlement date
transaction date != price observation date
lot identity != commodity identity
account identity != commodity identity
current registry/config != historical evidence
external/import identity != ledger transaction identity
recorded != cleared != reconciled
```

A feature may omit one of these coordinates when it is irrelevant. It should not redefine two coordinates as the same concept just because the current household does not yet distinguish them.

## Quantity and value

The most important future boundary outside currency identity is:

```text
quantity != value
```

Examples:

```text
10 shares of a fund
0.005 BTC
25,000 reward points
```

are quantities. None is inherently a JPY/USD/EUR value.

If valuation is needed later, it should be derived from separate evidence/policy rather than replacing the original quantity.

Conceptually:

```text
observed quantity
+ separate price evidence
+ explicit valuation coordinate/policy
-> reporting value
```

Do not add `base_amount` or a converted value to every current source merely to reserve this future.

## Cost, price, valuation, and lot

Securities and other acquired commodities introduce several meanings that ordinary household cash can often ignore:

```text
Cost
  what was given/accrued to acquire a quantity

PriceObservation
  an observed relationship between commodities at a time/source

Valuation
  a report-time interpretation using selected price evidence/policy

Lot
  distinguishable acquired quantity carrying acquisition history
```

These are not current implementation requirements.

The future-proofing law is only:

```text
Cost != PriceObservation != Valuation
Lot != Commodity
```

Do not infer historical acquisition cost from today's price. Do not overwrite source quantity with a converted reporting value. Do not assume all units of one security are interchangeable for every future tax/cost-basis question merely because they share a commodity code.

## Time coordinates

Current Household transactions mostly use one accounting date. Future banking/import/investment pressure may require another temporal coordinate.

Possible examples include:

```text
transaction / economic-occurrence date
bank posting date
settlement date
price observation date
valuation date
```

Do not add these now. Preserve the ability to add named coordinates later without changing the meaning of the existing date retrospectively.

## Reconciliation and external provenance

A future bank/card importer should not force imported status into transaction identity or description text.

Potential later meanings include:

```text
external source identity
import batch/source provenance
matching decision
cleared state
reconciled state
reconciliation statement/date
```

These are workflow/evidence coordinates, not accounting amount arithmetic.

If import is added later, duplicate detection should prefer durable external identity/provenance where available instead of guessing only from date + memo + amount.

## Historical stability

Configuration and registries may change over a long-lived household:

- a currency can be retired or replaced;
- a security ticker/name can change;
- a points programme can alter its rules;
- display symbols and decimal presentation can change;
- an Account can be closed or reclassified;
- current valuation policy can change.

A later current configuration must not silently rewrite what an old source event meant at the time.

Therefore preserve:

```text
current policy/configuration
!= historical identity/evidence
```

When historical meaning genuinely needs correction, prefer an explicit migration/correction with provenance over reinterpretation by a new default.

## Repository-specific guardrails

For bqn-ledger specifically:

- keep `currency_registry.bqn` currency-specific unless a concrete broader owner is justified;
- keep exact decimal source/arithmetic semantics and never introduce binary floating-point money as a shortcut;
- keep currency/domain proof separate from FX valuation;
- keep account default Commodity/currency metadata distinct from source amount authority;
- keep currency-partitioned arithmetic fail-closed rather than inventing cross-currency addition;
- do not expand Facts/cube/report axes merely to reserve hypothetical future fields;
- when a new capability becomes real, observe the current array shape first and add only the semantic axis/evidence that the capability needs.

## Useful future characterization witnesses

If future work touches these boundaries, representative synthetic witnesses are preferable to broad speculative implementation:

```text
USD-only Household
EUR-only Household
ILS-only Household
KWD exact 3-fraction amount
same "$" display symbol with distinct currency identities
a non-currency commodity quantity
same commodity acquired in two distinct lots
one quantity with acquisition cost and later independent price observation
transaction date distinct from settlement date
same imported event replayed with stable external identity
```

No witness above is required to be implemented by this observation PR.

## Explicit non-goals

This observation does not authorize:

- adding EUR/GBP/CHF/INR/KWD to production configuration;
- ISO 4217 synchronization;
- generic Commodity registry implementation;
- securities/investment features;
- crypto support;
- points/miles tracking;
- FX APIs or automatic conversion;
- base/reporting currency fields;
- price database;
- cost basis or tax-lot engine;
- settlement workflow;
- bank import;
- reconciliation workflow;
- new Facts/cube/TBDS axes;
- source migration;
- writer changes;
- private Household data changes.

## Decision

Keep the repository open to broader value semantics by preserving semantic distinctions, not by prebuilding unused abstractions.

The next implementation remains whatever concrete Household need or current engineering review selects. This document becomes relevant only when a proposed change would erase one of the boundaries above or when a real new requirement needs one of them.
