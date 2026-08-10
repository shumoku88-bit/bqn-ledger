# Date × dynamic category flow capability

Status: current retained capability
Owner: `src/accounting/date_category_flow.bqn`

## Boundary

`date_category_flow.Build ⟨facts,budgetPolicy,householdPolicy,domain,layer,startOrdinal,endExclusiveOrdinal⟩` consumes canonical Facts, admitted `budget.toml` / `household.toml` policy, and explicit query coordinates. It imports exact-scale arithmetic and the retained sparse Group owner; it does not read sources, the clock, report policy, sections, or presentation state.

The public owner is intentionally narrow:

```text
capability admission / cross-source coordinate resolution
  -> selected Posting array kernel
  -> exact semantic result + contributor evidence
```

Admission protects request and cross-source compatibility. The successful kernel owns the accounting transformation. Exact normalization and checked reductions remain at the operations that can fail.

## Category ownership

Category meaning is no longer carried by Account metadata.

- `accounts.journal` / Account Facts own Account identity, accounting role/type, and Commodity coordinate.
- `budget.toml` owns the sparse `Expense AccountKey -> Envelope` relation and Envelope order.
- `household.toml` owns each Envelope's structural Budget allocation Account coordinate.
- Date Category Flow owns the synthetic trailing `other` category for Expense Accounts not assigned to a spendable Envelope.

For one successful build:

1. the Budget-policy Expense Account keys are resolved against the current Facts Account axis;
2. each declared Envelope is matched to its Household allocation Account;
3. the selected-domain Account axis is retained in canonical Facts order;
4. Expense Accounts map to their Envelope coordinate or `other`; non-Expense Accounts remain outside the expense-category coordinate space;
5. income is reduced separately from explicit Income postings.

No Account prefix, display-label inference, or presentation policy participates.

## Selected Posting kernel

The admitted domain/layer/half-open period selects one Posting axis. The selected coefficients are normalized once to one exact scale, then the capability performs independent checked reductions:

```text
selected Posting axis
  -> Date × Income
  -> Date × dynamic Expense Category
  -> Date × Account
  -> Date net
```

Date × Category and Date × Account remain independent reductions. Deriving one from the already-reduced other can change exact-range failure semantics and contributor order, so sharing stops before semantic reduction.

The Account-category relation is built once as an aligned Account vector. The kernel does not rescan every Account for its Envelope assignment.

## Result

The presentation-neutral result contains:

- sorted unique transaction dates in the selected period;
- per-date income and net coefficients plus income contributor Posting indices;
- dynamic category labels in Budget-policy Envelope order followed by `other`;
- each Envelope category's Household Budget allocation Account index;
- sparse Date × Category expense groups with exact coefficients and contributor Posting indices;
- the complete selected-domain Account axis in canonical Facts order;
- sparse Date × Account groups over every selected Posting;
- one exact selected-flow scale;
- owner-specific diagnostics and empty semantic tables on error.

A sparse group exists when postings contribute to that coordinate, even if their exact sum is zero. Dense zero cells, display signs, Account visibility, and observation/as-of policy are presentation/section concerns.

## Consumers

`src/accounting/month_category_flow.bqn` consumes Date × Category evidence and performs the distinct Month-axis reduction.

`src/sections/daily_flow.bqn` consumes Date × Account evidence, applies observation/period checks, selects active non-Budget Account columns, pivots the admitted sparse groups, and owns labels/sign presentation. It does not recompute category/accounting classification.

## Focused proof

`tests/test_accounting_date_category_flow.bqn` protects:

- canonical date, category, and Account axes;
- exact income, expense, and net coefficients;
- Posting contributor alignment and order;
- mixed-scale exact normalization;
- later-period selection;
- independent Date × Account movement evidence;
- Budget-policy Account-admission-order invariance;
- fail-closed missing Expense Account key and Expense-role drift;
- missing Household Envelope coordinates;
- unknown domain/layer and invalid period;
- empty semantic tables on error.

The capability therefore treats source admission as evidence rather than re-parsing source-internal policy syntax, while retaining the request/cross-source checks needed by independently supplied admitted values.
