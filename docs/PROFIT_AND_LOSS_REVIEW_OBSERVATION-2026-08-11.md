# Profit and Loss review observation — 2026-08-11

## Baseline

Observed initially against `main` `f9f3ce1a93e9b9e211f51e3cad9b0fc79f49790f` after PR #633 closed the Plan Temporal Status review and advanced the Phase 1 cursor to `src/accounting/profit_and_loss.bqn`.

The only other open PR observed at review start was Draft #550 for canonical Household recovery closeout. It is a separate source-retirement/documentation workstream and does not overlap this accounting owner.

The production owner remained unchanged through the review. Final boundary qualification landed in PR #635 and the owner was reread on `main` `07168702a4427e6d6b98ae3a3a26dc83fd78ebe4`.

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

The focused accounting laws are:

- `tests/test_accounting_profit_and_loss.bqn` for ordinary statement behavior;
- `tests/test_accounting_profit_and_loss_boundaries.bqn` for dense-zero and exact-subset boundaries;
- `tests/test_section_profit_and_loss.bqn` for the section publication path.

The accounting result is therefore a live semantic capability, but current production presentation is bounded to the Profit and Loss section/report path.

## Upstream relation is already array-native

The owner delegates Posting selection, normalization, Account grouping, Account order, period evidence, and exact Account movement to the already-reviewed `src/accounting/account_period.bqn`.

That upstream owner exposes a dense Account axis in canonical Account order. Profit and Loss therefore does **not** rescan raw Postings Account-by-Account. Its successful path starts from aligned Account movement cells:

```text
Account Period dense Account axis
→ admitted Account role per Account row
→ income / expense selection
→ statement sign normalization
→ checked statement totals
→ statement rows + durable Posting contributors
```

Replacing the two simple role masks with another Group/Pivot layer would not remove a repeated Posting scan; the expensive relation has already been classified once upstream.

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

The contract requires every admitted Income and Expense Account in source order, including exact-zero movement. The dense Account axis from `account_period` is therefore semantic evidence, not incidental padding.

PR #635 now proves this directly: zero-movement Income and Expense Accounts remain in canonical Account order with zero statement amount and empty contributor cells.

### KEEP durable Posting evidence

Each published statement Account row converts `account_period.period_contributors` from snapshot-local Posting indices into source-qualified durable Posting references.

### KEEP explicit half-open period and domain

Period/domain selection belongs to the caller. This owner must not choose a Cycle, current profile, observation date, or default currency.

## Exact subset sums are a distinct safety boundary

An initial review hypothesis was that successful Account Period totals might make the local Profit and Loss `scale.Sum` checks redundant. That hypothesis is false, but the first illustrative counterexample recorded during observation was too strong because a single coefficient at `9007199254740991` does not pass the Account Period normalization path.

PR #635 replaced that illustrative argument with an executable counterexample that respects the actual admitted Account Period boundary.

### Normalize and Sum are separate exact operations

`account_period.bqn` normalizes every selected Posting coefficient through `exact_scale.Normalize` before grouping. Therefore a valid downstream counterexample must use coefficients that individually survive normalization.

`exact_scale.Sum` then checks each sequential addition for reversibility:

```text
candidate - previous = value
candidate - value    = previous
```

A semantic subset can therefore introduce a new exact-sum failure even when every coefficient normalized successfully and the complete Account-side sequence summed successfully.

### Executable role-subset construction

PR #635 constructs `2^53 - 1` from ten individually normalizable 15-digit coefficients:

```text
9 × 900000000000000
+   907199254740991
= 9007199254740991
```

All chunk prefixes remain inside the contiguous exact-integer interval.

The complete Account-side sequence then includes a non-statement bridge `1` followed by statement value `2`:

```text
chunks
→ 9007199254740991
→ +1 = 9007199254740992
→ +2 = 9007199254740994
```

`account_period.Build` succeeds for this same Facts/period.

An Expense or Income role subset omits the bridge Account but retains the tail Account, so its statement sum instead attempts:

```text
chunks
→ 9007199254740991
→ +2 = 9007199254740993
```

That final integer is not exactly representable at the current Number spacing, so the role-local `scale.Sum` fails.

The boundary test proves both:

```text
expense_sum_failed
income_sum_failed
```

with no partial statement rows after a successful Account Period.

### Net income is also a separate checked operation

PR #635 additionally constructs a case where:

- Income total is individually exact at `9007199254740991`;
- an abnormal Expense credit publishes exact Expense total `-2`;
- the complete upstream Account-side sequence remains exact;
- final net calculation requires `9007199254740991 - (-2) = 9007199254740993`.

The owner correctly fails closed with:

```text
net_income_sum_failed
```

### Decision

The local failure states:

```text
income_sum_failed
expense_sum_failed
net_income_sum_failed
```

are **reachable and meaningful**. They are not duplicate guards.

Classification: **KEEP all three checked `scale.Sum` boundaries and the `exact_scale` dependency.** A downstream semantic subset creates a new exact operation, so failure checking belongs at that operation even after upstream Account Period exactness succeeds.

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
- the selected lanes have their own necessary checked exact sums.

Classification: **KEEP current role masks.** BQN-native is not a requirement to use Group where direct axis selection is clearer.

## Row projection

`Rows` publishes aligned statement rows directly from selected Account coordinates, statement-normalized amounts, and period contributors. It does not build candidate row namespaces and reproject them later.

The helper is domain-shaped structural publication rather than the row-append/reprojection machinery removed from earlier owners.

Classification: **KEEP**.

## Snapshot-local `account_index` observation

Accounting statement rows currently publish both:

```text
account_index
account_key
```

Repository search found no current `income.account_index` or `expenses.account_index` consumer. The active financial-statement document describes statement identity by Account and contributor evidence, not by snapshot-local numeric index.

However the already-reviewed sibling `src/accounting/balance_sheet.bqn` exposes the same `account_index + account_key` accounting-row shape. Removing the coordinate from Profit and Loss alone would create an unexplained divergence between sibling accounting statement capabilities.

Classification: **DEFER as a cross-statement public-surface question.** Revisit only with a coherent statement/public-result shape review.

## Section result-shape observation

`src/sections/profit_and_loss.bqn` declares an `EmptyRows` shape without `account_index`, while successful section publication forwards accounting rows that currently include it.

The reviewed Balance Sheet section has the same empty/success shape asymmetry. This is evidence for a later Section/publication-shape review rather than a reason to distort the accounting kernel here.

Classification: **DEFER to Phase 3 Section review / cross-cutting publication-shape audit.**

## Final observation outcome

PR #635 converted the two important KEEP reasons into executable laws without changing production code:

- dense zero Income/Expense rows are retained;
- all three local exact statement failures remain reachable after a successful Account Period.

No production refactor is justified by the completed evidence. The owner is ready to close as a KEEP decision after merge-side CI and final main reread.
