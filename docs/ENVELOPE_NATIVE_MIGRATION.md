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

The lower observer is range-parametric. Production Envelope stock composition does not pass the report Period start as that lower bound. It passes the selected-domain native Entitlement stock origin, so Actual use after Envelope inception remains deducted across later report Periods while older accounting history stays outside the Envelope stock world.

## Plan lifecycle

`src/accounting/plan_observation.bqn` owns role-neutral Plan lifecycle observation from stable PlanId, admitted retirement evidence, Actual completion evidence, and observation day. Account role, posting shape, and Envelope meaning are deliberately outside this owner.

Plan retirement evidence is admitted with `plan.journal` and carried separately as `plan_retirements`; it is not encoded into generic Facts.

## Completed Fulfillment

`src/accounting/envelope_fulfillment.bqn` resolves completed Plans through the Fulfillment route effective on the completion Actual day. Only `fulfills` pairs require completion-shape validation. Actual quantities are authoritative, and positive non-Expense target Postings can remain multi-posting evidence.

Production stock composition observes completed Fulfillment from the same selected-domain Entitlement origin used for Consumption. A report Period boundary therefore cannot resurrect capacity already fulfilled in an earlier Period. Completion evidence before native Envelope inception remains outside stock even if routing evidence already existed.

A later current-policy change therefore cannot rewrite historical completed Fulfillment.

## Open Commitment

`src/accounting/envelope_commitment.bqn` observes open Plan Postings at the statement observation day:

- Expense Postings use observation-day Expense routing;
- positive non-Expense Postings use observation-day PlanId Fulfillment routing;
- explicit unmanaged and unrouted Expense lanes stay separate;
- current `budget.toml` Expense assignments are not an input.

Open Commitment intentionally follows current effective historical routing because it is still intent, not frozen completion evidence. It remains report-Period/current-observation scoped rather than becoming cumulative merely because Consumption and Fulfillment are stock terms.

## Native Budget Entitlement

`src/accounting/envelope_entitlement.bqn` observes the admitted source-ordered Budget movement relation directly rather than reconstructing movements from generic Budget Facts or a Budget Account closing. `budget_source_adapter.bqn` preserves that admission alongside its Facts projection, and report composition carries it only to Envelope Entitlement. Allocation Accounts resolve to stable Envelope identities; opening/unassigned to Envelope movements are grants, Envelope-to-Envelope movements are reallocations, and Envelope-to-unassigned movements are releases. Envelope-to-spent/execution and spent/execution-to-Envelope rows remain readable legacy evidence but are inert.

Historical admission validates the complete selected-domain native effect history independently of the requested report Period and observation cutoff. Same-day effects combine before the chronological cumulative nonnegative law is checked, and a future negative defect invalidates an earlier observation. Publication then cuts native effects at the observation/end coordinate and derives its exact scale only from the included observation universe. The report Period start does not reset Entitlement.

For stock composition, the earliest native Entitlement effect visible through the selected-domain observation is the stock origin. If no native Entitlement effect is visible yet, Consumption and Fulfillment receive a canonical empty post-observation horizon rather than falling back to the report Period or current policy. Unknown or multiply-owned Budget endpoints fail closed. No current Budget/Expense configuration or destination Account is used as historical claim authority.

## Envelope & Backing composition

Production `src/accounting/envelope_backing.bqn` composes two different time horizons intentionally:

```text
stock horizon = native Entitlement origin .. observation

Entitlement
Consumption
Fulfillment
Remaining  = Entitlement - Consumption + Refunds - Fulfillment

current report/observation horizon
Commitment
Headroom   = Remaining - Commitment
Backing
```

The outer statement still retains the requested report `[start,end)` and observation coordinates. Those coordinates select and present the statement; they do not reset the live Envelope stock position. A Period rollover without a new grant therefore preserves previously consumed or fulfilled capacity instead of resurrecting it.

The retained external `open_plan_reserve` field and `Plan reserve` label are compatibility names for Commitment. They are not a separate semantic owner. Completed Plan Actualization does not write a Budget execution companion.

Current `budget.toml` remains relevant for current Backing topology and current presentation/configuration policy. It is no longer Plan claim authority. Plan destination Account names are not used to infer Envelope meaning.

## Remaining migration boundary

Physical Budget-era source names and other retained compatibility vocabulary may remain until separate source/writer retirement work. They must not regain semantic authority over historical Envelope claims.

Future changes should preserve exact arithmetic, stable identity, provenance, fail-closed ambiguity handling, the stock/report horizon distinction, and the distinction between historical evidence and current configuration. BQN implementations should keep the relations visible rather than mechanically copying another engine's type structure.
