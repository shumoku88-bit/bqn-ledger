# Profit and Loss review observation — 2026-08-11

## Baseline

Observed against `main` `f9f3ce1a93e9b9e211f51e3cad9b0fc79f49790f` after PR #633 closed the Plan Temporal Status review and advanced the Phase 1 cursor to `src/accounting/profit_and_loss.bqn`.

The only other open PR observed at review start is Draft #550 for canonical Household recovery closeout. It is a separate source-retirement/documentation workstream and does not overlap this accounting owner.

This document is observation-only. It does not change production BQN, tests, public result shape, statement semantics, arithmetic, provenance, source authority, writer behavior, or the TODO cursor.

## Owner boundary

`src/accounting/profit_and_loss.bqn` is the pure Actual Profit and Loss statement owner for one explicit currency domain and half-open ordinal period.

Input:

```text
Actual Facts
currency domain
start ordinal
end-exclusive ordinal
```

Output meaning:

```text
income Account rows
expense Account rows
exact total income
exact total expenses
exact net income
source-qualified Posting contributors
```

The owner reads no source files, chooses no period, reads no clock, renders no text, owns no report request policy, and infers no Account role from names.

## Current consumer graph

The production composition path is:

```text
src/report/compose.bqn
  → src/accounting/profit_and_loss.bqn
  → src/sections/profit_and_loss.bqn
  → human renderer
```

The focused accounting law is `tests/test_accounting_profit_and_loss.bqn`; the section law is `tests/test_section_profit_and_loss.bqn`.

The accounting result is therefore a live semantic capability, but current production presentation is bounded to the Profit and Loss section/report path.

## Upstream relation is already array-native

The owner delegates Posting selection, normalization, Account grouping, Account order, period evidence, and exact Account movement to the already-reviewed `src/accounting/account_period.bqn`.

That upstream owner exposes a dense Account axis in canonical Account order. Profit and Loss therefore does **not** rescan raw Postings Account-by-Account. Its successful path starts from aligned Account movement cells:

```text
Account Period dense Account axis
→ admitted Account role per Account row
→ income / expense selection
→ statement sign normalization
→ exact totals
→ statement rows + durable Posting contributors
```

This matters for the BQN review. Replacing the two simple role masks with another Group/Pivot layer would not remove a repeated Posting scan; the expensive relation has already been classified once upstream.

## Protected statement semantics

The active `docs/FINANCIAL_STATEMENTS.md` contract states:

```text
income amount  = - signed income movement
expense amount =   signed expense movement
net income     = total income - total expenses
```

Canonical Posting signs remain debit-positive / credit-negative. A debit to Income or credit to Expense remains visible as a negative statement amount; it is not reclassified by Account name or counterpart.

### KEEP Account-role authority

Only admitted `facts.accounts.role` determines statement membership. `income` and `expense` are selected; Asset, Liability, Equity, Budget, and other roles are outside this statement question.

### KEEP dense zero rows

The contract requires every admitted income and expense Account in source order, including exact-zero movement. The dense Account axis from `account_period` is therefore semantic evidence, not incidental padding.

### KEEP exact staged totals

Income and expense totals are independently checked through `scale.Sum`. Net income is then a separate checked exact subtraction. These are distinct failure boundaries and should not be compressed into unchecked arithmetic.

### KEEP durable Posting evidence

Each published statement Account row converts `account_period.period_contributors` from snapshot-local Posting indices into source-qualified durable Posting references.

### KEEP explicit half-open period and domain

Period/domain selection belongs to the caller. This owner must not choose a Cycle, current profile, observation date, or default currency.

## Array-visibility decision

Current role selection is intentionally simple:

```bqn
incomeIndices ← ("income"⊸≡¨roles)/source.index
expenseIndices ← ("expense"⊸≡¨roles)/source.index
```

A classify-once Group form is possible, but current evidence does not justify it:

- the input is already one dense Account axis rather than raw repeated Posting evidence;
- there are only two retained statement lanes;
- direct masks make role semantics and canonical Account order visible;
- zero-movement Accounts remain naturally present;
- totals require independent exact failure boundaries anyway.

Classification: **KEEP current role masks unless a later measured or cross-statement reason changes the question.** BQN-native is not a requirement to use Group where a scalar/axis selection is clearer.

## Row projection

`Rows` publishes aligned statement rows directly from selected Account coordinates, statement-normalized amounts, and period contributors. It does not build candidate row namespaces and reproject them later.

The helper is therefore domain-shaped structural publication rather than the row-append/reprojection machinery removed from earlier owners.

Classification: **KEEP**.

## Snapshot-local `account_index` observation

Accounting statement rows currently publish both:

```text
account_index
account_key
```

Repository search finds no current `income.account_index` or `expenses.account_index` consumer. The active financial-statement document describes statement identity by Account and contributor evidence, not by snapshot-local numeric index.

However the already-reviewed sibling `src/accounting/balance_sheet.bqn` deliberately exposes the same `account_index + account_key` accounting-row shape. Removing the coordinate from Profit and Loss alone would create an unexplained divergence between sibling accounting statement capabilities.

Classification: **OBSERVE / cross-statement public-surface candidate, not a local subtraction yet.** Revisit only with a coherent statement/public-result shape review rather than deleting one coordinate owner-by-owner without a shared decision.

## Section result-shape observation

`src/sections/profit_and_loss.bqn` declares an `EmptyRows` shape without `account_index`, but successful section publication forwards `accounting.income` and `accounting.expenses` unchanged, which currently include `account_index`.

The reviewed Balance Sheet section has the same empty/success shape asymmetry. This suggests a Section/publication-shape concern rather than a Profit and Loss accounting-kernel defect.

Classification: **DEFER to Phase 3 Section review / cross-cutting publication-shape audit.** Do not distort the accounting owner to repair a downstream empty-result schema inconsistency.

## Focused-law gap

The current accounting test directly proves:

- normal Income/Expense amounts and totals;
- period slicing;
- abnormal Income debit / Expense credit signs;
- source-qualified contributor source;
- unknown-domain failure.

It does **not** directly fix the documented dense-zero-row law. The current synthetic Account fixture has one Income and two Expense Accounts, all of which move in the tested period.

Before declaring this review complete, add one focused characterization proving that an admitted income or expense Account with no selected-period movement remains in canonical Account order with exact zero amount and an empty contributor cell.

That law protects the strongest reason not to replace the dense Account projection with a sparse statement-only representation.

## Current review direction

No production refactor is justified from the evidence so far.

The next coherent step is a **law-only** change for dense zero statement rows. After that merges, reread the owner on current `main`. If no new defect appears, close the Profit and Loss accounting review as a KEEP decision and advance to `src/accounting/recent_transactions.bqn`.
