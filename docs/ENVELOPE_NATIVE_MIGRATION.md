# Envelope-native migration

Status: production Plan claim observation now uses historical Envelope routing.

## Ownership direction

The canonical physical source set remains unchanged. `household.toml` is one physical source with multiple semantic owners. Current policy and historical evidence have different lifetimes and must not reconstruct one another.

```text
household.toml bytes
  -> current Household policy projection -> current policy admission
  -> historical Envelope projection      -> history admission
```

Missing historical routing never falls back to current `budget.toml` assignments.

## Historical Envelope owner

`src/ledger/envelope_history_admission.bqn` owns stable Envelope identities plus effective-dated Expense and PlanId Fulfillment routing. Account and Plan references remain source-local keys at that boundary; cross-source existence is qualified against admitted Account and Plan evidence.

## Actual Consumption

`src/accounting/envelope_consumption.bqn` keeps Actual Posting/day coordinates until each Expense posting is resolved through effective historical Expense routing. Managed, explicit unmanaged, and unrouted attention evidence remain distinct. Charges and credits/refunds retain Posting provenance and route source rows.

## Plan lifecycle

`src/accounting/plan_observation.bqn` owns role-neutral Plan lifecycle observation from stable PlanId, admitted retirement evidence, Actual completion evidence, and observation day. Account role, posting shape, and Envelope meaning are deliberately outside this owner.

Plan retirement evidence is admitted with `plan.journal` and carried separately as `plan_retirements`; it is not encoded into generic Facts.

## Completed Fulfillment

`src/accounting/envelope_fulfillment.bqn` resolves completed Plans through the Fulfillment route effective on the completion Actual day. Only `fulfills` pairs require completion-shape validation. Actual quantities are authoritative, and positive non-Expense target Postings can remain multi-posting evidence.

A later current-policy change therefore cannot rewrite historical completed Fulfillment.

## Open Commitment

`src/accounting/envelope_commitment.bqn` observes open Plan Postings at the statement observation day:

- Expense Postings use observation-day Expense routing;
- positive non-Expense Postings use observation-day PlanId Fulfillment routing;
- explicit unmanaged and unrouted Expense lanes stay separate;
- current `budget.toml` Expense assignments are not an input.

Open Commitment intentionally follows current effective historical routing because it is still intent, not frozen completion evidence.

## Native Budget Entitlement

`src/accounting/envelope_entitlement.bqn` observes the admitted source-ordered Budget movement relation rather than a Budget Account closing. Allocation Accounts resolve to stable Envelope identities; opening/unassigned to Envelope movements are grants, Envelope-to-Envelope movements are reallocations, and Envelope-to-unassigned movements are releases. Envelope-to-spent/execution and spent/execution-to-Envelope rows remain readable legacy evidence but are inert.

The observation carries exact signed effects, effective dates, source event and Posting provenance, plus the requested `[start,end)` and observation-day coordinates. Opening relation evidence before `start` establishes the carried opening position; period movements are cut off at `end` and at the observation day. Unknown or multiply-owned Budget endpoints fail closed. No current Budget/Expense configuration or destination Account is used as historical claim authority.

## Envelope & Backing composition

Production `src/accounting/envelope_backing.bqn` now composes native observations:

```text
Entitlement
Consumption
Fulfillment
Remaining  = Entitlement - Consumption + Refunds - Fulfillment
Commitment
Headroom   = Remaining - Commitment
Backing
```

The retained external `open_plan_reserve` field and `Plan reserve` label are compatibility names for Commitment. They are not a separate semantic owner. Completed Plan Actualization does not write a Budget execution companion.

Current `budget.toml` remains relevant for current Backing topology and current presentation/configuration policy. It is no longer Plan claim authority. Plan destination Account names are not used to infer Envelope meaning.

## Remaining migration boundary

Physical Budget-era source names and other retained compatibility vocabulary may remain until separate source/writer retirement work. They must not regain semantic authority over historical Envelope claims.

Future changes should preserve exact arithmetic, stable identity, provenance, fail-closed ambiguity handling, and the distinction between historical evidence and current configuration. BQN implementations should keep the relations visible rather than mechanically copying another engine's type structure.
