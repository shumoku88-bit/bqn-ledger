# Retained Envelope & Backing report

Status: retained production capability on native historical Consumption, Fulfillment, and Commitment observation.

Owners:

- `src/accounting/envelope_entitlement.bqn` owns source-ordered Budget Entitlement observation;
- `src/accounting/envelope_consumption.bqn` owns Actual Expense Consumption observation;
- `src/accounting/plan_observation.bqn` owns role-neutral Plan lifecycle observation;
- `src/accounting/envelope_fulfillment.bqn` owns completed Plan Fulfillment;
- `src/accounting/envelope_commitment.bqn` owns open Plan Commitment;
- `src/accounting/envelope_backing.bqn` composes Envelope terms and Backing;
- `src/sections/envelope_backing.bqn` owns retained human/compact/JSON presentation.

## Inputs and ownership

Envelope/Backing consumes admitted Budget, Actual, Plan Facts, admitted Plan retirement evidence, historical Envelope routing, current `budget.toml`, and current `household.toml` policy over explicit `[start,end_exclusive)`, observation, and domain coordinates.

Ownership is intentionally split by lifetime:

- source-ordered Budget movement evidence supplies native Entitlement; historical Envelope-to-spent/execution compatibility rows are inert;
- historical Expense routing supplies Actual Consumption meaning at Posting day;
- stable PlanId + Actual completion + completion-day Fulfillment routing supplies completed Fulfillment;
- open Plan Postings + observation-day routing supplies Commitment;
- `household.toml` current policy supplies Envelope allocation Account and unassigned Budget Account coordinates;
- `budget.toml` current policy supplies Backing-pool Asset Account topology.

Current Expense assignments do not backfill historical Consumption and do not determine Plan claims. Plan destination Account names are not Envelope claim authority.

Missing, conflicting, unknown, wrong-role, or otherwise invalid required evidence fails closed. Missing historical routing is never silently converted to current configuration.

## Accounting shape

The composition remains purpose-specific rather than a generic pipeline:

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
  -> public result
```

`ResolveOwnership` resolves structural Envelope allocation and Backing topology only. Native Entitlement resolves Budget movement endpoints separately; no current Expense-Account-to-Envelope relation or Plan destination Account is used for claims.

`BuildEnvelopeTerms` aligns native observations by stable Envelope identity and performs exact reductions:

```text
Remaining = Entitlement - Consumption + Refunds - Fulfillment
Headroom  = Remaining - Commitment
```

The outward `open_plan_reserve` field remains as a compatibility label for Commitment. Fulfillment is exposed independently so Remaining does not hide why Envelope capacity changed.

## Plan evidence

Plan lifecycle is role-neutral. A Plan becomes completed through stable PlanId Actual evidence, not through Account similarity. Retirement is separate admitted evidence.

Completed Fulfillment freezes routing at the completion Actual day, validates the routed Plan/Actual Account order, posting direction, and Commodity, then uses Actual quantities as authoritative evidence. Multi-posting non-Expense targets remain representable.

Open Commitment instead observes effective routing at the current observation day. Expense and non-Expense target meaning therefore remain explicit and can evolve without rewriting completed history.

Duplicate completion evidence and ambiguous effective routing fail at their owning observation layer with specific diagnostics rather than being reconstructed as a generic Backing conflict.

## Exactness and evidence

All Envelope arithmetic normalizes exactly and fails closed when exact reduction cannot be represented. Posting and Transaction provenance from Consumption, Fulfillment, Commitment, funding, and Budget evidence is retained through the statement.

Backing remains a whole-Household selected-domain statement: current funding evidence is compared with positive Remaining, then Backing surplus, Budget unassigned, and reconciliation delta are published separately. Pool-specific shortage/surplus semantics are not inferred here.

## Publication

The retained section renders Human, compact, and JSON surfaces. It publishes Entitlement, Consumption, credits/refunds, Fulfillment, Remaining, Plan reserve/Commitment, and Headroom separately, followed by Backing evidence.

The section verifies strict date text against accounting ordinals. Exact-number JSON avoids float conversion. Backed and under-backed states remain explicit.

## Compatibility boundary

`open_plan_reserve` and the visible `Plan reserve` label are retained names only. They must not be interpreted as a second owner beside Commitment.

Physical Budget-era names and result-shape compatibility can be retired independently later. Such cleanup must not restore current configuration or Account-name inference as historical Envelope authority.
