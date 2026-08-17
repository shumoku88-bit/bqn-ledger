# Envelope & Backing capability

Status: current production capability

## Owners

- `src/ledger/entitlement_journal_admission.bqn`: strict StockOrigin / Transfer source admission
- `src/accounting/envelope_entitlement.bqn`: native Transfer effects on the stable Envelope axis
- `src/accounting/envelope_consumption.bqn`: Actual Expense Consumption
- `src/accounting/plan_observation.bqn`: role-neutral Plan lifecycle
- `src/accounting/envelope_fulfillment.bqn`: completed Plan Fulfillment
- `src/accounting/envelope_commitment.bqn`: open Plan Commitment
- `src/accounting/envelope_backing.bqn`: Envelope term and Backing composition
- `src/sections/envelope_backing.bqn`: human / compact / JSON presentation and StockOrigin evidence

## Source ownership

Envelope & Backing consumes explicit owners with different lifetimes:

- `entitlement.journal` supplies zero-or-one StockOrigin per Commodity and source-ordered native Endpoint transfers;
- `household.toml [envelope-history]` supplies stable Envelope identities plus explicit Expense and Fulfillment routing history;
- `envelope.toml` supplies current Envelope membership/presentation and current Backing topology;
- Actual and Plan Journals supply accounting and intent evidence.

Current configuration never fills missing historical routing. Account names and Plan destination Accounts never infer Envelope ownership. Entitlement admission does not receive an Account registry.

## Native Entitlement source

Exactly two source forms are admitted:

```text
YYYY-MM-DD origin COMMODITY [memo]
YYYY-MM-DD transfer FROM -> TO QUANTITY COMMODITY [memo]
```

Endpoints are `unallocated` or a stable `EnvelopeId`. `unallocated` is a boundary endpoint, not an Account and not a balance-owning pool. Its name is reserved from both stable and current Envelope identities.

A StockOrigin is first-class evidence containing date, Commodity, memo, source line, and source event identity. Duplicate origins fail closed. Every transfer requires an explicit origin on or before the transfer date. No origin is inferred from a first transfer, report Period, current policy, Asset balance, or Account name.

Transfers carry exact positive quantity and explicit direction. Same-endpoint, zero/negative, unknown-Envelope, and noncanonical keyword rows fail closed. Same-day effects combine before cumulative nonnegative validation per Envelope and Commodity.

An empty source and an origin-only Commodity are valid. Neither creates an Unallocated balance.

## Native relation shape

The successful accounting relation is aligned to current `EnvelopeId` order from `envelope.toml`:

```text
E axis
  envelope_id
  entitlement
  consumption
  refunds
  fulfillment
  remaining
  commitment
  headroom
  contributor cells
```

There is no allocation Account column, Account-to-Envelope projection, or Unallocated balance column. Historical transfers may reference retired identities from the stable registry; current report rows select current Envelope membership. The report result separately retains StockOrigin provenance.

## Composition

```text
ValidateInputs
  -> Resolve current Backing ownership
  -> PrepareEvidence
       -> Entitlement
       -> Consumption
       -> Fulfillment
       -> Commitment
  -> Build Envelope-aligned terms
  -> Build Backing
  -> result
```

For each Envelope:

```text
Remaining
  = Entitlement
  - Consumption
  + Refunds
  - Fulfillment

Headroom
  = Remaining
  - Commitment
```

Commitment is published directly as `commitment`; there is no reserve compatibility alias.

## Time horizons

Live stock terms do not reset at report Period boundaries. The explicit StockOrigin date for the selected Commodity starts the stock horizon.

```text
stock horizon = explicit StockOrigin .. observation

Entitlement
Consumption
Fulfillment
Remaining

report / observation horizon
Commitment
Headroom
Backing
```

This prevents a later report Period from resurrecting capacity consumed or fulfilled earlier in the same Envelope epoch.

## Plan evidence

Plan lifecycle is keyed by stable `PlanId` and explicit Actual completion evidence.

Completed Fulfillment freezes routing at the completion evidence boundary and uses Actual quantities as authoritative evidence. Open Commitment observes routing at the current observation day because it remains current intent.

Plan completion never publishes a duplicate Entitlement execution fact.

## Backing

Backing compares current selected-domain Asset funding with positive Remaining claims. It publishes separately:

- funding balance
- signed Envelope total
- positive Backing required
- Backing surplus

No Unallocated balance or reconciliation field is fabricated.

## Safety laws

- exact arithmetic
- stable Envelope / Plan / Actual identity
- source-qualified StockOrigin and Transfer provenance
- ambiguous or missing required evidence fails closed
- historical routing never falls back to current policy
- no Account-name inference or Account-to-Envelope adapter
- no duplicate execution fact
- no compatibility alias for Commitment

Completed migration history belongs to Git history rather than this current capability contract.
