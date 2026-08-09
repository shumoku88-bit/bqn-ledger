# Date × dynamic category flow capability

Status: Phase 3B public proof
Owner: `src/accounting/date_category_flow.bqn`

## Boundary

`date_category_flow.Build ⟨facts,domain,layer,startOrdinal,endExclusiveOrdinal⟩` consumes one canonical fact result and explicit query coordinates. It imports only exact arithmetic from `src/ledger`; it does not import source readers, context, Cube/TBDS, report sections, formatters, or clock.

This is the second materially different grouping consumer after Account-period state. It intentionally remains a narrow accounting capability rather than introducing a generic query DSL before grouping semantics are compared.

## Explicit category semantics

Dynamic categories come from admitted Account metadata:

1. selected-domain Accounts with `kind=envelope` must have role `budget` and a nonempty, unique `budget` label;
2. selected-domain expense Accounts whose `budget` exactly matches one envelope label use that category;
3. remaining explicit-role expense Accounts use the reserved `other` category;
4. explicit-role income Accounts contribute to the separate income measure.

No account prefix, display-name trimming, or report label inference participates. The category axis follows canonical envelope Account order, followed by `other`.

Income is the negated signed sum of postings to explicit income Accounts. Expense groups retain the signed sum of postings to explicit expense Accounts, so reversals/refunds remain accounting evidence rather than being forced positive.

## Result

The presentation-neutral result contains:

- sorted unique transaction dates in the selected period;
- per-date income and net coefficients plus income contributor Posting indices;
- dynamic category labels and their envelope Account indices;
- sparse date/category expense groups with exact coefficients and contributor Posting indices;
- the complete selected-domain Account axis in admitted order;
- sparse date/Account groups over every selected Posting, aligned to that Account axis;
- one exact selected-flow scale;
- fail-closed diagnostics and empty result tables on error.

A sparse group exists when postings contribute to that coordinate, even if their exact sum is zero. Dense zero cells and display signs are presentation concerns and are not materialized here.

## Public proof

`tests/test_accounting_date_category_flow.bqn` proves:

- dates `2026-01-02`, `2026-01-10`, and `2026-01-12`;
- dynamic categories `food`, `other`;
- income `1000`, food expenses `20` and `10`, other expense `5`;
- net values `1000`, `-20`, `-15`;
- exact contributors: income Posting `1`, food Postings `2`/`4`, other Posting `5`;
- every JPY Account in admitted order, including zero-posting Budget Accounts;
- sparse date/Account movement with balancing asset, income, food, and transport Posting contributors;
- later-period selection;
- mixed source scales normalized to one exact coefficient scale;
- unknown domain/layer and invalid period fail closed.

The category fields remain the accounting evidence consumed by Month Category Flow. Daily Flow consumes the aligned date/Account fields, then selects active non-Budget columns so individual Accounts are not collapsed into Envelope categories. This module is not a report section and does not own observation/as-of or formatting policy.

## Comparison with Account-period grouping

Shared evidence now exists for:

- explicit domain/layer/period selection;
- Account-index joins;
- exact scale normalization and checked sums;
- deterministic contributor Posting indices;
- fail-closed empty results.

The group policies are still materially different:

- Account-period state includes all domain Accounts, zero rows, and pre-period opening evidence;
- date/category flow uses transaction-date axes, metadata-derived dynamic categories, transformed income, sparse expense coordinates, and no opening state.

The subsequent `month × expense category` proof demonstrated that explicit row-axis plus bounded category coordinate, exact sum, and contributor flattening are identical. That operation now lives in `sparse_group.bqn` and is used by both date and month consumers. Category classification, transaction-date selection, month derivation, income/net, and opening state remain outside the generic Group owner. See `MONTH_CATEGORY_GROUPING.md`.
