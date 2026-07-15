# POLICY_RISK_STYLE daily-capacity decision — 2026-07-15

Status: completed docs-only policy decision
Owner: ledger policy / configuration / report
Canonical: no; current runtime remains in `src_next/config.bqn` until separately selected compatibility and implementation slices
Exit: completed decision record; use this for rationale, not as automatic implementation authority
Supersedes: the enduring semantic classification of `POLICY_RISK_STYLE` in `HOUSEHOLD_POLICY_PROFILE_SCHEMA.md` and the open question in `CONFIG_POLICY_CONTINUATION_HANDOFF-2026-07-14.md`

## Decision

`POLICY_RISK_STYLE` is not a durable household risk-style abstraction.

The current values:

```text
conservative
simple
```

do not primarily describe a person's risk tolerance. They select different arithmetic inputs:

- `simple` divides a broad liquid-asset balance by remaining days without reserving fixed obligations;
- `conservative` first subtracts selected fixed expenses and `fixed_obligation` amounts, then divides the remainder by remaining days.

The names mix value judgment with calculation shape. The target concept is therefore **daily capacity**, derived from three explicit inputs:

```text
DailyCapacity
  asset_scope
  obligation_scope
  horizon
```

The ledger owner chooses the scopes and horizon. The engine validates those choices, computes the result, and exposes the evidence used by the calculation.

## Target calculation contract

The intended calculation shape is:

```text
eligible_assets
  = sum of balances admitted by asset_scope

admitted_obligations
  = sum of unpaid obligations admitted by obligation_scope
    and falling within horizon

capacity_balance
  = eligible_assets - admitted_obligations

daily_capacity
  = capacity_balance / remaining_days_to_horizon
```

The final date-boundary rule, rounding rule, negative-balance presentation, and unavailable states remain separate contract questions. This decision selects the semantic boundary, not those implementation details.

## Asset scope

The owner must be able to distinguish accounts that participate in daily-capacity calculation from accounts that do not.

Examples of possible owner intent include:

- ordinary checking and cash participate;
- savings, emergency reserves, investments, externally managed funds, or restricted balances do not participate;
- a ledger may intentionally include or exclude another liquid account.

The target meaning is explicit admission, not inference from an account's display name, country, bank type, or presumed household custom.

This decision does not choose the storage shape. A future slice must decide whether the owner is represented by account metadata, a named account set, a role vocabulary, another validated configuration structure, or reuse of an existing semantic field.

## Obligation scope

Daily capacity must identify which payment obligations reduce the balance before division.

The target meaning is an explicit, evidence-bearing set of obligations, normally constrained by all of the following:

- still unpaid or otherwise unsettled;
- admitted by the owner's obligation policy;
- due within the selected horizon;
- represented by a source or derived contract that can be inspected.

A tentative purchase, optional plan, long-range aspiration, and confirmed payment obligation are not automatically the same thing.

This decision does not yet choose which current source rows, metadata, statuses, or projections constitute an admitted obligation. That requires a focused consumer and source-evidence audit before implementation.

## Horizon

The calculation period is not universally a calendar month.

The owner may need a horizon such as:

- the current cycle end;
- the next income boundary;
- an explicitly selected date;
- another validated household period.

The engine must not silently assume monthly salary, a particular national payday convention, or a calendar-month household. The exact supported horizon vocabulary remains unselected.

## Relationship to envelope budgeting

Envelope budgeting and daily capacity have related but distinct jobs:

```text
envelope budgeting
  allocates money by purpose

daily capacity
  projects an admitted balance across time
```

Daily capacity must work with both current budget styles:

- with `POLICY_BUDGET_STYLE=envelope`, a future consumer may project a selected envelope or pool across the horizon;
- with `POLICY_BUDGET_STYLE=none`, it may project an explicitly admitted account balance after admitted obligations.

The same reserved amount must not be deducted twice. A future contract must prove whether an obligation is already represented inside the selected envelope or pool before applying another reserve subtraction.

Envelope policy therefore does not disappear, and daily capacity does not become a second hidden envelope system.

## Gross liquidity remains a diagnostic, not spending advice

A broad calculation such as:

```text
all liquid assets / remaining days
```

may remain useful as an observation of gross liquidity or depletion speed.

It must not automatically be labeled as a safe amount to spend. A primary `daily_capacity` value requires explicit asset, obligation, and horizon evidence. If those inputs are unavailable or ambiguous, the engine should prefer an explicit unavailable or diagnostic state over silently presenting gross liquidity as spendable money.

The exact report vocabulary and machine-output shape remain unselected.

## Ownership boundary

The long-term ownership split is:

```text
ledger owner
  chooses asset scope
  chooses obligation scope
  chooses horizon

engine
  validates admitted inputs
  applies the calculation contract
  rejects or exposes ambiguous evidence
  reports the calculation components
```

The engine must not choose a household-management philosophy through a hidden repository fallback. At the same time, a damaged or incomplete configuration must not silently resolve to a different financial meaning.

## Current runtime compatibility

This decision does not change runtime behavior today.

Current behavior remains:

```text
POLICY_RISK_STYLE=conservative
POLICY_RISK_STYLE=simple
missing -> warning + conservative fallback
empty -> error
unknown -> error
```

For compatibility:

- do not remove either current value;
- do not rename current config values or machine fields;
- do not remove the current missing-key fallback;
- do not mass-edit public, private, live, or fixture configuration;
- do not reinterpret existing reports or snapshots through the target model;
- do not rewrite journal, plan, budget, account, or cycle source data.

The old values remain a compatibility vocabulary until a separate audit and migration decision proves a safe path.

## Evidence available today

The repository currently proves that:

- config parsing distinguishes missing, explicit empty, explicit values, and unknown values;
- both `conservative` and `simple` are represented by explicit fixture/profile choices;
- the older profile schema associated `simple` with a monthly-salary, no-envelope example and `conservative` with the moko envelope example;
- account metadata already contains liquidity and budget-related concepts;
- plan metadata already contains at least one fixed-obligation concept.

This is enough to reject `risk style` as the durable semantic owner. It is not enough to choose the final storage fields, source joins, report section, JSON contract, rounding behavior, or migration sequence.

## Next eligible finite slice

The next eligible slice is a **docs-only current consumer and input-evidence audit**.

It may map only:

1. every current runtime consumer of `PolicyRiskStyle`;
2. the current formulas and output fields affected by each value;
3. available account metadata that could express asset admission;
4. available plan, issue, journal, or other evidence that could express payment obligations;
5. current cycle/date evidence that could provide the horizon;
6. envelope paths where reserve subtraction could be duplicated;
7. fixture and negative-test coverage needed before any migration.

That audit is a candidate only. This decision does not automatically select it, and it must not include runtime changes.

## Migration gates

A future migration may replace or retire `POLICY_RISK_STYLE` only after separately reviewed work proves all of the following:

1. current consumers and formulas are completely inventoried;
2. asset, obligation, and horizon ownership are explicit;
3. envelope and non-envelope paths have independent evidence;
4. duplicate reservation is prevented by contract and tests;
5. missing, empty, duplicate, unknown, and unavailable states are designed;
6. current `simple` and `conservative` outputs have an explained compatibility mapping or deliberate break;
7. human and machine output names do not overstate gross liquidity as safe spending capacity;
8. no source TSV or private configuration is automatically rewritten;
9. full repository checks and representative daily-use verification pass.

No implementation, release, or removal date is selected here.

## Non-goals

- no runtime, report, ViewModel, JSON, CLI, editor, or source-schema change;
- no new configuration key or account metadata field;
- no removal or renaming of `conservative` or `simple`;
- no decision that every ledger must use envelope budgeting;
- no universal calendar-month or monthly-salary assumption;
- no automatic classification of all liquid accounts as spendable;
- no automatic promotion of every planned payment to an obligation;
- no private or production-data access;
- no selection of unrelated configurable-ledger, Israel, strict-source, M4, AI context-bundle, or Observatory work.

## Result

The durable model is not `simple` versus `conservative`.

It is an evidence-bearing daily-capacity projection over an owner-selected asset scope, obligation scope, and horizon. Envelope budgeting may provide one admitted pool, but it does not own the entire calculation. Gross liquidity may remain visible as a diagnostic, while a spendable daily-capacity value requires explicit scopes and must not double-count reserved money.

Current runtime behavior remains unchanged until separate audit and migration slices are selected.