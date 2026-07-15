# Daily Capacity Minimal Input / Result Contract

Status: current runtime contract
Owner: report / ledger policy / envelope
Canonical: yes; canonical for the first evidence-bearing Daily Capacity boundary
Exit: retain until an explicitly reviewed replacement contract supersedes it

Implementation state: the pure `src_next/daily_capacity.bqn` calculation seam is implemented. Policy adapters, config, metadata, report wiring, output migration, and compatibility migration remain absent and unselected.

## 1. Purpose

This contract selects the smallest data-only boundary for replacing the durable meaning of `POLICY_RISK_STYLE` with an evidence-bearing Daily Capacity calculation for the current Outlook consumer.

The selected household question is:

> At an explicit observation date `O`, through the selected cycle horizon `C`, what amount remains after owner-admitted assets and owner-admitted unsettled obligations are reconciled without deducting the same reserved amount twice?

The calculation is not a personality label and is not an automatic envelope system.

```text
DailyCapacity
  asset_scope
  obligation_scope
  horizon
```

This contract defines the calculation carrier only. It does not select how owner choices are stored in config or source metadata.

## 2. Selected boundary

The selected pure calculation boundary is:

```text
BuildDailyCapacityFromEvidence
  ⟨observation, horizon, arithmetic_domain, asset_scope, obligation_scope⟩
```

The production pure boundary is exported from `src_next/daily_capacity.bqn` under this exact name. It accepts already-resolved in-memory evidence only.

The boundary is specific to the first Outlook Daily Capacity consumer. It is not a universal household advice engine, generic forecast engine, or report-wide policy kernel.

## 3. Ownership split

```text
caller / report adapter
  selects explicit observation O
  supplies the selected cycle horizon C

policy adapter
  resolves owner asset decisions
  resolves owner obligation decisions
  supplies reservation provenance

source evidence adapters
  supply observation-bounded balances
  supply plan identity and settlement evidence
  supply cycle and currency evidence
  do not make hidden policy choices

pure Daily Capacity builder
  validates supplied evidence
  prevents mixed or duplicated basis arithmetic
  computes one result
  returns structured diagnostics

presentation / compatibility adapters
  retain current report and machine fields until separately migrated
```

The builder must not infer household policy from account names, country, salary convention, pension cadence, display labels, or repository fallback values.

## 4. Input carrier

The input has exactly five top-level parts:

```text
{
  observation
  horizon
  arithmetic_domain
  asset_scope
  obligation_scope
}
```

All inputs are already loaded and resolved in memory. The pure builder does not accept a base directory or source file path.

## 5. Observation input

`observation` has this meaning:

```text
{
  date
  source
}
```

### 5.1 `date`

`date` is the explicit Outlook observation coordinate `O`.

Required properties:

- valid Gregorian `YYYY-MM-DD` text;
- supplied by the caller;
- not read from system time inside the builder;
- not derived from the journal frontier `L` inside the builder;
- not treated as an Event coordinate for source rows.

### 5.2 `source`

`source` records how the adapter obtained `O`, for example:

```text
explicit_argument
report_today
compatibility_record_frontier
synthetic_test
```

The value is evidence only. It does not change arithmetic.

The canonical human Outlook adapter is expected to supply explicit `O` or `report_today`. The current compact summary may temporarily supply its compatibility record-frontier value, but that adapter must remain visibly non-canonical.

## 6. Horizon input

For the first consumer, `horizon` is the selected cycle window:

```text
{
  kind
  start
  end_exclusive
  source_ref
}
```

Selected first-consumer meaning:

```text
kind = cycle
C = [start, end_exclusive)
```

Required properties:

- `start` and `end_exclusive` are valid dates;
- `start < end_exclusive`;
- `start <= O < end_exclusive` for a calculable current-cycle result;
- `remaining_days = end_exclusive - O`;
- no calendar-month or monthly-salary assumption is introduced;
- an income-anchored two-month cycle and an ordinary monthly cycle use the same boundary shape.

### 6.1 Temporal states

```text
O < start
  -> error: observation_before_horizon_start

O == end_exclusive
  -> unavailable: horizon_exhausted

O > end_exclusive
  -> error: observation_after_horizon

unavailable cycle evidence
  -> unavailable: horizon_unavailable
```

The builder does not silently select another cycle or replace `O` with `L`.

## 7. Arithmetic-domain input

Daily Capacity is calculated in one proven arithmetic domain.

```text
{
  state
  currency
  amount_scale
  basis
  message
}
```

The carrier may reuse an upstream single-currency proof, but the builder does not accept a detached assertion with no relationship to supplied asset and obligation evidence.

Required properties for calculation:

```text
state = proven
one currency domain
one amount scale
all admitted asset and obligation rows match that domain
```

This contract does not select currency conversion, FX valuation, cross-currency netting, or a preferred reporting currency.

Mixed-domain evidence fails closed rather than being numerically added.

## 8. Asset-scope input

`asset_scope` represents owner-resolved admission decisions over one non-overlapping basis.

```text
{
  state
  scope_id
  basis_kind
  policy_ref
  rows
}
```

### 8.1 Scope state

Allowed values:

```text
resolved
unavailable
error
```

- `resolved` means an owner policy was resolved, including an intentionally empty admitted set.
- `unavailable` means the owner decision is missing or cannot be resolved.
- `error` means the supplied policy evidence is malformed or contradictory.

An empty resolved scope is valid and produces `eligible_assets = 0`. Missing scope ownership is not the same as an intentionally empty scope.

### 8.2 Basis kind

Allowed first-contract values:

```text
account_balance
pool_remaining
```

`account_balance` means the basis rows are observation-bounded balances for explicitly selected accounts.

`pool_remaining` means the basis rows are explicitly selected remaining balances of virtual pools, such as selected envelope balances.

One calculation uses exactly one basis kind. The builder must not add account balances and envelope balances that are claims on the same funding base.

```text
account_balance + pool_remaining without non-overlap proof
  -> error: mixed_asset_basis
```

This contract deliberately does not select a generalized mixed-basis proof system.

### 8.3 Asset evidence row

Each row has:

```text
{
  asset_id
  source_kind
  source_ref
  currency
  amount
  decision
  decision_basis
}
```

Required meanings:

- `asset_id` is unique within the supplied scope;
- `source_kind` matches `basis_kind`;
- `source_ref` is an inspectable stable reference to the upstream evidence;
- `amount` is signed and is not clamped to zero;
- `decision` is exactly `include` or `exclude`;
- `decision_basis` identifies the owner policy evidence that produced the decision.

A negative admitted balance remains part of the calculation. An overdraft or overdrawn pool must not disappear through clamping.

### 8.4 Asset admission rule

```text
eligible_assets
  = sum(amount for asset rows where decision = include)
```

Account `role=asset` and `type=liquid` are useful candidate classification evidence. They are not, by themselves, proof of owner admission.

The builder must not infer admission from:

- account display name;
- `assets:` prefix;
- bank type;
- country;
- envelope group label;
- `type=liquid` alone.

## 9. Obligation-scope input

`obligation_scope` represents owner-resolved admission decisions over payment-obligation evidence.

```text
{
  state
  scope_id
  policy_ref
  rows
}
```

The same `resolved | unavailable | error` distinction used by `asset_scope` applies.

### 9.1 Obligation evidence row

Each row has:

```text
{
  obligation_id
  source_ref
  due_on
  currency
  amount
  settlement_state
  decision
  decision_basis
  excluded_from_asset_basis
  reservation_ref
}
```

Required meanings:

- `obligation_id` is stable and unique within the supplied scope;
- `source_ref` identifies inspectable source evidence without requiring presentation text;
- `due_on` is a valid payment-due coordinate;
- `amount` is a nonnegative obligation amount;
- `settlement_state` is exactly `open` or `completed` in the first contract;
- `decision` is exactly `include` or `exclude`;
- `decision_basis` identifies the owner policy evidence;
- `excluded_from_asset_basis` is the amount already proven to be outside the selected asset basis;
- `reservation_ref` identifies the evidence supporting that exclusion.

### 9.2 Horizon admission

For the first cycle-bound consumer, an included obligation must satisfy:

```text
settlement_state = open
due_on < C.end_exclusive
```

An open overdue obligation with `due_on < O` remains eligible for admission. Observation does not erase an unsettled obligation.

An obligation exactly on `C.end_exclusive` belongs outside the current half-open horizon and is not admitted by this contract.

A completed obligation must not be included. A raw plan row without settlement evidence is insufficient proof that the obligation remains open.

### 9.3 Classification boundary

The following may contribute evidence, but none alone is the canonical obligation owner:

- `plan_id` and journal completion linkage;
- `cashflow=fixed_obligation`;
- expense-account `spend_class=fixed`;
- transaction endpoints;
- `due_on`;
- plan date;
- anchor activation.

An open issue amount is not an admitted payment obligation.

A liquid-to-non-liquid transfer is not automatically a payment obligation.

The policy adapter must decide admission and expose its basis. The pure builder validates the supplied decision but does not invent it.

## 10. Reservation provenance and duplicate-deduction rule

`excluded_from_asset_basis` is the only amount that reduces the obligation deduction before arithmetic.

Its meaning is precise:

> This exact portion of this exact admitted obligation is already proven to be outside the selected asset basis.

It does not mean merely that an envelope exists or that money is described as reserved.

Required invariants:

```text
0 <= excluded_from_asset_basis <= amount
```

When:

```text
excluded_from_asset_basis > 0
```

then:

```text
reservation_ref must be non-empty and inspectable
```

A reservation held inside the selected asset basis does not qualify as excluded. It still belongs to the admitted basis and the corresponding obligation must still be deducted.

Examples:

```text
selected basis = all admitted bank balances
execution envelope is only a virtual claim on those balances
  -> excluded_from_asset_basis = 0

selected basis = daily/flex pool only
execution pool is outside the selected basis
exact obligation linkage is proven
  -> linked amount may be excluded_from_asset_basis

selected basis relationship is ambiguous
  -> no calculation
  -> unavailable: reservation_provenance_ambiguous
```

Aggregate equality between one execution envelope and total unfinished plans is useful diagnostic evidence, but it is not per-obligation reservation provenance.

## 11. Selected arithmetic

For all included and valid obligation rows:

```text
gross_admitted_obligations
  = sum(amount)

already_excluded_from_asset_basis
  = sum(excluded_from_asset_basis)

obligation_deduction
  = gross_admitted_obligations
    - already_excluded_from_asset_basis

capacity_balance
  = eligible_assets
    - obligation_deduction

remaining_days
  = C.end_exclusive - O
```

The same amount must not appear twice in `already_excluded_from_asset_basis` through duplicate obligation identity or duplicate reservation linkage.

### 11.1 Nonnegative capacity

When:

```text
capacity_balance >= 0
remaining_days > 0
```

then:

```text
state = ok
daily_capacity = floor(capacity_balance / remaining_days)
daily_shortfall = 0
```

### 11.2 Deficit

When:

```text
capacity_balance < 0
remaining_days > 0
```

then:

```text
state = deficit
daily_capacity = 0
daily_shortfall = ceiling((-capacity_balance) / remaining_days)
```

The signed `capacity_balance` remains visible. The builder must not relabel a negative balance as spendable daily capacity.

The separate positive `daily_shortfall` indicates the average daily recovery needed across the remaining horizon. It is arithmetic evidence, not financial advice.

### 11.3 Rounding

Selected first-contract rounding:

- positive daily capacity rounds down to the arithmetic-domain unit;
- daily shortfall rounds up to the arithmetic-domain unit;
- aggregate amounts remain exact in the supplied amount scale;
- presentation formatting does not change stored arithmetic values.

## 12. Result carrier

The builder returns:

```text
{
  state
  observation
  horizon
  arithmetic_domain
  asset_evidence
  obligation_evidence
  calculation
  diagnostics
}
```

### 12.1 State

Allowed values:

```text
ok
deficit
unavailable
error
```

Precedence is:

```text
error
  > unavailable
  > deficit
  > ok
```

- `ok` means all evidence was admitted and capacity is nonnegative.
- `deficit` means all evidence was admitted and capacity is negative.
- `unavailable` means required semantic ownership or evidence is absent or ambiguous.
- `error` means supplied evidence is invalid, contradictory, duplicated, or outside the selected contract.

`deficit` is a successful arithmetic result, not an unavailable state.

### 12.2 Evidence fields

`asset_evidence` and `obligation_evidence` retain normalized evidence and admission decisions in deterministic input order.

For each admitted obligation, normalized obligation evidence also exposes:

```text
deduction_amount
  = amount - excluded_from_asset_basis
```

Evidence remains available on `unavailable` and `error` results so a caller can explain why calculation did not proceed.

No private presentation memo, party name, or free-text issue body is required by this contract. Presentation and privacy-safe redaction remain downstream concerns.

### 12.3 Calculation field

On `ok` or `deficit`, `calculation` contains exactly:

```text
{
  eligible_assets
  gross_admitted_obligations
  already_excluded_from_asset_basis
  obligation_deduction
  capacity_balance
  remaining_days
  daily_capacity
  daily_shortfall
}
```

On `unavailable` or `error`:

```text
calculation = empty
```

The builder does not return a plausible partial daily amount after a fatal evidence failure.

### 12.4 Diagnostics

`diagnostics` is an ordered list of:

```text
{
  severity
  stage
  code
  message
  evidence_refs
}
```

Selected severities:

```text
unavailable
error
```

Selected stages:

```text
temporal
currency
asset_scope
obligation_scope
reservation
structure
```

Minimum selected diagnostic codes:

```text
observation_invalid
horizon_unavailable
horizon_invalid
observation_before_horizon_start
horizon_exhausted
observation_after_horizon
arithmetic_domain_rejected
asset_scope_unavailable
asset_scope_error
duplicate_asset_id
mixed_asset_basis
asset_row_invalid
obligation_scope_unavailable
obligation_scope_error
duplicate_obligation_id
obligation_row_invalid
completed_obligation_included
obligation_outside_horizon
reservation_amount_invalid
reservation_provenance_missing
reservation_provenance_ambiguous
duplicate_reservation_linkage
```

Diagnostics are ordered by the evaluation sequence below, then by source evidence order.

## 13. Evaluation order

The selected validation and calculation order is:

```text
1. validate observation
2. validate horizon and O position
3. authorize arithmetic domain
4. validate asset scope state, IDs, basis, rows, and domain
5. validate obligation scope state, IDs, rows, settlement, horizon, and domain
6. validate per-obligation reservation provenance and duplicate linkage
7. if any error diagnostic exists, return state=error with empty calculation
8. if no error and any unavailable diagnostic exists, return state=unavailable with empty calculation
9. compute eligible assets and obligation totals
10. compute capacity balance and remaining days
11. return state=deficit or state=ok with complete calculation
```

Independent diagnostics within a stage may be collected together. Arithmetic is all-or-nothing after validation.

## 14. Purity and safety rules

`BuildDailyCapacityFromEvidence` must be deterministic for identical inputs.

It must not:

- read `journal.tsv`, `plan.tsv`, `accounts.tsv`, `budget_alloc.tsv`, `cycle.tsv`, or `issues.tsv`;
- load config or environment variables;
- read system time;
- call `•Out` or `•Exit`;
- infer owner policy from display strings or prefixes;
- mutate source TSV;
- create a plan, journal row, envelope allocation, issue, or advice item;
- perform currency conversion;
- hide negative balances;
- subtract an aggregate envelope reserve without per-obligation provenance;
- render human text, machine text, or JSON.

Loading, policy resolution, compatibility fallback, rendering, and process behavior remain adapter responsibilities.

## 15. Current runtime compatibility

This contract does not change current runtime behavior.

The following remain unchanged until separate characterization and implementation slices are selected:

```text
POLICY_RISK_STYLE=conservative
POLICY_RISK_STYLE=simple
missing -> warning + conservative fallback
empty -> error
unknown -> error

liq_daily
liq_safe_daily
src_next_outlook_liq_daily
src_next_outlook_liq_safe_daily
```

The contract makes no claim that current `liq_daily` or `liq_safe_daily` equals future `daily_capacity`.

The current human Outlook observation adapter and compact-summary compatibility adapter may continue to provide different observation sources temporarily:

```text
human Outlook -> explicit O / report_today
compact summary -> compatibility record frontier L
```

The pure builder always requires an explicit observation input and never owns either default.

A future runtime seam should first calculate the new result alongside current outputs in synthetic characterization. It must not silently reinterpret old fields or snapshots.

## 16. Storage decisions deliberately deferred

This contract does not choose:

- a new config key;
- an account metadata key such as `daily_capacity=include`;
- a named account-set file;
- a plan metadata expansion;
- a new obligation source file;
- an issues-to-obligation mapping;
- a generalized reservation ledger;
- a new JSON section;
- a CLI flag;
- a report label;
- a migration date;
- a private-data rewrite.

Those choices require evidence from characterization and the smallest concrete adapter requirement.

## 17. Synthetic characterization retained before adapter wiring

`tests/test_src_next_daily_capacity.bqn` covers:

1. resolved empty asset scope;
2. included and excluded liquid accounts;
3. one negative admitted asset balance;
4. account-balance basis without envelopes;
5. pool-remaining basis with envelopes;
6. rejection of mixed account and pool basis;
7. open admitted obligation;
8. completed obligation exclusion;
9. overdue open obligation;
10. obligation exactly on `C.end_exclusive`;
11. optional plan excluded by policy;
12. liquid-to-non-liquid transfer excluded as non-obligation;
13. full and partial `excluded_from_asset_basis` evidence;
14. missing and ambiguous reservation provenance;
15. duplicate obligation and duplicate reservation linkage;
16. nonnegative capacity rounding down;
17. deficit with positive daily shortfall rounded up;
18. exhausted, before-start, and after-horizon observation states;
19. unavailable asset or obligation policy;
20. rejected arithmetic domain;
21. current `simple` and `conservative` compatibility outputs unchanged.

The characterization uses public in-memory synthetic evidence only. It does not require private or production data.

## 18. Next eligible finite slice

The pure runtime seam is complete. No adapter or output slice is selected by this contract.

The smallest separately selectable candidate is a test-only characterization of one evidence adapter boundary that can produce the five-part input carrier without changing Outlook output. Before selection, it must name the concrete evidence owner and preserve these constraints:

- no new or reinterpreted config key;
- no account or plan metadata change;
- no report wiring or current Outlook arithmetic change;
- no JSON or UI;
- no private-data access;
- no `simple` or `conservative` migration.

## 19. Non-goals

- no runtime adapter or report connection;
- no report, ViewModel, JSON, CLI, editor, or source-schema change;
- no envelope redesign;
- no broad temporal campaign;
- no automatic admission of every liquid account;
- no automatic admission of every plan or issue;
- no hidden monthly or salary assumption;
- no cross-currency arithmetic;
- no source TSV mutation;
- no private or production-data access;
- no selection of unrelated AI context-bundle, Israel, strict-source, M4, or Observatory work.

## 20. Result

The selected first Daily Capacity boundary is a pure calculation over:

```text
explicit O
selected cycle horizon C
one proven arithmetic domain
one owner-resolved non-overlapping asset basis
owner-resolved open obligations
per-obligation proof of amounts already outside that basis
```

It returns exact evidence, a signed capacity balance, a nonnegative spendable daily capacity or a separately named daily shortfall, and structured diagnostics.

Envelope budgeting may supply a selected pool basis or reservation evidence, but an envelope label alone never authorizes subtraction. The same amount is deducted exactly once.