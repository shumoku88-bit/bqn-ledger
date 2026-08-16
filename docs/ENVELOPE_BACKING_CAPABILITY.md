# Envelope & Backing capability

Status: current production capability

## Owners

- `src/accounting/envelope_entitlement.bqn`: Entitlement from admitted source-ordered Budget movements
- `src/accounting/envelope_consumption.bqn`: Actual Expense Consumption
- `src/accounting/plan_observation.bqn`: role-neutral Plan lifecycle
- `src/accounting/envelope_fulfillment.bqn`: completed Plan Fulfillment
- `src/accounting/envelope_commitment.bqn`: open Plan Commitment
- `src/accounting/envelope_backing.bqn`: Envelope term and Backing composition
- `src/sections/envelope_backing.bqn`: human / compact / JSON presentation

## Source ownership

Envelope & Backing consumes explicit owners with different lifetimes:

- `budget.journal` supplies ordered Entitlement movement evidence;
- `household.toml [budget]` supplies explicit opening and unassigned Budget Account coordinates;
- `household.toml [[budget.envelopes]]` supplies stable allocation Account -> Envelope identity coordinates;
- `household.toml [envelope-history]` supplies stable Envelope identities plus explicit Expense and Fulfillment routing history;
- `budget.toml` supplies current Envelope definition/presentation and current Backing topology;
- Actual and Plan Journals supply accounting and intent evidence.

Current configuration never fills missing historical routing. Account names and Plan destination Accounts never infer Envelope ownership.

## Clean epoch

An empty canonical `budget.journal` is valid and represents zero Entitlement claims before the first explicit source movement. No opening amount is inferred from Actual balances or previous Budget-era history.

Native Entitlement recognizes only explicit opening / unassigned / allocation coordinates. There is no spent or execution endpoint in the current model.

## Composition

```text
ValidateInputs
  -> ResolveOwnership
  -> PrepareEvidence
       -> Entitlement
       -> Consumption
       -> Fulfillment
       -> Commitment
  -> BuildEnvelopeTerms
  -> BuildBacking
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

Live stock terms do not reset at report Period boundaries. Production derives a stock origin from the earliest admitted Entitlement-source movement visible for the selected Commodity.

```text
stock horizon = Entitlement-source origin .. observation

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

Plan completion never publishes a duplicate Budget execution fact.

## Backing

Backing compares current selected-domain Asset funding with positive Remaining claims. It publishes separately:

- funding balance
- signed Envelope total
- positive backing required
- Backing surplus
- Budget unassigned
- reconciliation delta

These are observations of different evidence systems and are not forced to equality.

## Safety laws

- exact arithmetic
- stable Envelope / Plan / Actual identity
- source-qualified provenance
- ambiguous or missing required evidence fails closed
- historical routing never falls back to current policy
- no Account-name inference
- no duplicate execution fact
- no compatibility alias for Commitment

Completed migration history belongs to Git history rather than this current capability contract.
