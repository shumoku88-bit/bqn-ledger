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
→ statement totals
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

### KEEP durable Posting evidence

Each published statement Account row converts `account_period.period_contributors` from snapshot-local Posting indices into source-qualified durable Posting references.

### KEEP explicit half-open period and domain

Period/domain selection belongs to the caller. This owner must not choose a Cycle, current profile, observation date, or default currency.

## Exact-range proof and duplicate guards

The initial review treated the local `scale.Sum` calls as independent exact failure boundaries. Reading `account_period.bqn` and `exact_scale.bqn` shows that this is too conservative.

A successful Account Period has already proved all selected Posting coefficients normalized to one common scale and has checked exact totals for:

```text
all debit movement   — nonnegative side
all credit movement  — nonpositive side
```

For each Account `a`, let:

```text
D[a] >= 0
C[a] <= 0
M[a] = D[a] + C[a]
```

For any subset of Accounts `S`:

- the total positive part of `M[S]` cannot exceed the already-checked total debit movement;
- the absolute total negative part of `M[S]` cannot exceed the already-checked absolute total credit movement;
- therefore every partial sum of `M[S]`, in any Account order, remains inside the exact bounds already admitted upstream.

Profit and Loss statement measures are only sign changes and subsets of this same movement axis:

```text
income total  = - sum M[income]
expense total =   sum M[expense]
net income    = - sum M[income ∪ expense]
```

Consequently, after `accountPeriod.state = "ok"`, the local failure states:

```text
income_sum_failed
expense_sum_failed
net_income_sum_failed
```

are unreachable unless the upstream Account Period exactness contract is broken.

`exact_scale.Sum` itself performs checked sequential addition. The subset proof above is strong enough for any order because every prefix is bounded by the total admitted positive and negative sides, not merely by the final algebraic result.

Classification: **SUBTRACT candidate, strong proof.** A coherent implementation may replace the three local checked sums with direct reductions/subtraction and remove the now-unused `exact_scale` dependency while preserving exact arithmetic by construction.

This is not weakening the exact boundary. It recognizes that the exact boundary is already owned and proved once by `account_period`.

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
- zero-movement Accounts remain naturally present.

Classification: **KEEP current role masks.** BQN-native is not a requirement to use Group where direct axis selection is clearer.

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

However the already-reviewed sibling `src/accounting/balance_sheet.bqn` exposes the same `account_index + account_key` accounting-row shape. Removing the coordinate from Profit and Loss alone would create an unexplained divergence between sibling accounting statement capabilities.

Classification: **OBSERVE / cross-statement public-surface candidate, not a local subtraction yet.** Revisit only with a coherent statement/public-result shape review rather than deleting one coordinate owner-by-owner without a shared decision.

## Section result-shape observation

`src/sections/profit_and_loss.bqn` declares an `EmptyRows` shape without `account_index`, but successful section publication forwards `accounting.income` and `accounting.expenses` unchanged, which currently include `account_index`.

The reviewed Balance Sheet section has the same empty/success shape asymmetry. This suggests a Section/publication-shape concern rather than a Profit and Loss accounting-kernel defect.

Classification: **DEFER to Phase 3 Section review / cross-cutting publication-shape audit.** Do not distort the accounting owner to repair a downstream empty-result schema inconsistency.

## Focused-law gaps

The current accounting test directly proves:

- normal Income/Expense amounts and totals;
- period slicing;
- abnormal Income debit / Expense credit signs;
- source-qualified contributor source;
- unknown-domain failure.

Two laws deserve direct characterization before subtracting the duplicate exact guards.

### A. Dense zero statement rows

The current synthetic Account fixture has one Income and two Expense Accounts, all of which move in the tested period. Add explicit zero-movement Income and Expense Accounts and prove:

- they remain in canonical Account order;
- their statement amount is exact zero;
- their contributor cell is empty.

This protects the strongest reason not to replace the dense Account projection with a sparse statement-only representation.

### B. Exact admitted edge

Add one admitted statement example whose debit and credit sides reach the largest exact coefficient admitted by the ledger while the statement contains both normal and abnormal signs. Prove that Profit and Loss publishes the exact edge value successfully.

This does not attempt to manufacture a local P&L overflow failure. The proof says such a failure is unreachable after a successful Account Period. The edge law instead fixes the positive contract at the boundary where the upstream exact proof still succeeds.

## Current review direction

The next sequence should be:

1. merge this observation;
2. add the dense-zero and exact-edge characterization laws without production changes;
3. subtract the three unreachable local checked-sum diagnostics and `exact_scale` dependency, replacing them with direct reductions/subtraction over the already-bounded Account movement axis;
4. run the full suite and reread the final owner on merged `main`;
5. close the Profit and Loss review and advance to `src/accounting/recent_transactions.bqn` if no new evidence appears.
