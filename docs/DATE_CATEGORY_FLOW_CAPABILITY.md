# Date × dynamic category flow capability

Status: current retained capability  
Owner: `src/accounting/date_category_flow.bqn`

## Boundary

`date_category_flow.Build ⟨facts,envelopeHistory,domain,layer,startOrdinal,endExclusiveOrdinal⟩` consumes admitted Facts, explicit historical Envelope routing, and query coordinates.

It does not read source files, current Household policy, `envelope.toml`, the clock, report policy, sections, or presentation state.

```text
admitted Facts
  + stable Envelope identity / ExpenseRoutingHistory
  + explicit query
    -> selected Posting array kernel
    -> exact semantic result + contributor evidence
```

## Category ownership

Category meaning is not Account metadata and is not current Envelope configuration.

- Account Facts own Account identity, accounting role, and Commodity.
- `EnvelopeHistory` owns stable Envelope identities and effective-dated Expense routing.
- Date Category Flow owns the synthetic trailing `other` presentation-neutral category for selected Expense evidence that is not managed by an Envelope.

For a successful build:

1. historical Expense Account keys resolve against the current Facts Account axis;
2. historical Expense routing is observed at each Posting day;
3. managed Expense Postings map directly to a stable `EnvelopeId`;
4. non-managed or otherwise non-envelope Expense evidence is represented by the trailing `other` result coordinate;
5. non-Expense Accounts remain outside the expense-category coordinate space;
6. Income is reduced independently from explicit Income Postings.

There is no allocation Account coordinate or Account-to-Envelope projection in the category relation. No Account prefix, display label, current `envelope.toml`, or current-config fallback participates.

Missing or conflicting historical routing is never reconstructed from current policy. Invalid cross-source references fail closed at admission or capability validation.

## Selected Posting kernel

The admitted domain/layer/half-open period selects one Posting axis. Selected coefficients normalize once to one exact scale, followed by independent checked reductions:

```text
selected Posting axis
  -> Date × Income
  -> Date × dynamic Expense Category
  -> Date × Account
  -> Date net
```

Date × Category and Date × Account remain independent reductions. Sharing stops before semantic reduction so exact-range failure behavior and contributor order remain explicit.

## Result

The presentation-neutral result contains:

- sorted selected transaction dates;
- per-date Income and net coefficients plus contributors;
- stable Envelope IDs in registry order plus trailing `other`;
- sparse Date × Category Expense groups;
- complete selected-domain Account axis in canonical Facts order;
- sparse Date × Account groups;
- one exact selected-flow scale;
- owner-specific diagnostics and empty semantic tables on error.

A sparse group exists when Postings contribute to a coordinate even when the exact sum is zero. Dense zero cells, display signs, Account visibility, and observation/as-of policy belong to sections/presentation.

## Consumers

`src/accounting/month_category_flow.bqn` consumes Date × Category evidence and performs Month-axis reduction.

`src/sections/daily_flow.bqn` consumes Date × Account evidence, applies observation/period checks, selects active accounting Account columns, pivots sparse groups, and owns display labels/sign presentation. It does not recompute routing or Account classification.

## Focused proof

`tests/test_accounting_date_category_flow.bqn` protects:

- canonical Date, category, and Account axes;
- exact Income, Expense, and net coefficients;
- contributor alignment and order;
- mixed-scale exact normalization;
- later-period selection;
- independent Date × Account evidence;
- explicit historical routing behavior;
- missing/invalid historical Account and Envelope references;
- unknown domain/layer and invalid period;
- empty semantic tables on error.

Current configuration is never treated as retrospective Expense routing authority. Completed migration history belongs to Git rather than this capability contract.
