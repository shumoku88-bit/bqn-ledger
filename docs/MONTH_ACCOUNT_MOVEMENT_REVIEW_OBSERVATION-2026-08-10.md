# Month Account movement review observation — 2026-08-10

## Baseline

Review starts from merged `main` `28f641e15a7c624b85eaca2900d760cdffc54e6a` after MatrixResult closeout PR #613.

This slice records observation only. No production BQN, result shape, accounting arithmetic, diagnostics, identity, provenance, source authority, report output, or UI behavior changes here.

## Retained purpose

`src/accounting/month_account_movement.bqn` owns one pure query:

```text
canonical Actual Facts
+ one admitted domain
+ strict half-open calendar-month range
→ dense Month × Account signed movement
+ source-qualified Posting contributors
+ month/account/grand reconciliation
```

The semantic axes are:

```text
rows    = ascending YYYY-MM coordinates in the requested range
columns = admitted Accounts in selected-domain order
cell    = exact signed sum of selected Actual Postings
```

Every requested month and every admitted Account remains explicit, including empty months and zero-posting Accounts.

## Historical array-kernel work

This owner already received the important clean-algorithm change before the current architecture review.

PR #504 characterized:

- interleaved source order across month cells;
- occupied exact-zero cells retaining contributors;
- missing cells retaining empty contributors;
- mixed exact scales;
- dense empty months;
- month, Account, and grand reconciliation.

PR #505 then replaced nested Month × Account cell rescans with:

```text
selected Actual Postings
→ month / Account coordinates
→ exact normalization
→ sparse_group.Build
→ sparse_pivot.Build
→ dense MatrixResult
```

The current code still exposes that transformation directly. There is no evidence for another algorithm rewrite merely to make the file look more array-like.

Classification: **KEEP the classify / Group / Pivot kernel**.

## Consumer graph

The retained production route is narrow:

```text
src/report/compose.bqn
  → month_account_movement.Build
  → src/sections/monthly_accounts.bqn
  → human Monthly Accounts presentation
```

`monthly_accounts` consumes:

- `domain`;
- `first_month` / `last_month_exclusive`;
- `months`;
- `account_keys`;
- `matrix`;
- `totals`.

It formats amounts from `matrix.scale` and renders `totals.balanced` specifically as `Balanced by month`.

## Exactness and reconciliation

After Pivot succeeds, the nested value rows are merged into a rectangular array and reduced across both semantic axes:

```text
Month × Account values
→ row reductions       = month totals
→ transpose + reductions = Account totals
→ exact sum(month totals)
→ exact sum(Account totals)
→ equality check
```

This is intentional independent reconciliation evidence, not accidental duplicate computation.

The two grand reductions may encounter different accumulation orders. Exact-operation failure therefore remains attached to each operation, and successful grand totals must agree before publication.

Classification: **KEEP month totals, Account totals, both checked grand reductions, and `matrix_reconciliation_failed`**.

## Admission and failure boundary

The owner currently protects:

- successful `actual.journal` Facts source relation;
- selected domain existence;
- Actual layer existence;
- strict `YYYY-MM` coordinates;
- ascending half-open month range;
- exact coefficient normalization;
- grouped-cell exact summation;
- Pivot diagnostics;
- row/column total exact summation;
- grand total exact summation;
- month-vs-Account reconciliation.

These checks guard source meaning, query coordinates, exact arithmetic, and accounting reconciliation. No evidence presently justifies collapsing the successful-path guard staging if doing so would change failure locality or diagnostic publication.

Classification: **KEEP diagnostic ownership and operation-local exactness guards for now**.

## Local calendar vocabulary

`IsMonth`, `MonthNumber`, and `MonthLabel` are local to the explicit calendar-month query. Repository search does not show a current shared Month coordinate owner that would make extracting them reduce ownership duplication.

Classification: **KEEP local for now**. Do not create a generic date/month helper merely to shorten this file.

## Generic helper observation

`Contains` and `IndexOf` are repeated local idioms across several accounting/ledger owners. That repetition is visible, but moving them into a generic helper would add shared abstraction without moving a domain responsibility.

A future direct-Find spelling may be worth a focused BQN experiment if it removes repeated scans while preserving the same diagnostics and nested-string semantics.

Classification: **OBSERVE, do not genericize in this owner review**.

## Subtraction candidates

### 1. Duplicate top-level exact scale

Successful publication currently stores the same exact scale twice:

```text
result.scale
result.matrix.scale
```

Both are assigned from `amountScale`.

The production Monthly Accounts section reads `matrix.scale`, not the top-level field. The focused accounting test directly asserts the top-level `ils.scale`, so this is test-visible surface even though no production consumer was found.

Classification: **SUBTRACT candidate requiring focused public-surface review**.

The question is whether Month Account movement needs a second scale authority outside its canonical MatrixResult.

### 2. Duplicate top-level Account coordinates

Successful publication also carries:

```text
result.account_indices
result.matrix.column_coordinates
```

Both are the same admitted selected-domain Account index axis.

The production Monthly Accounts section consumes `account_keys` and the Matrix, but does not read `account_indices`. The focused accounting test also does not assert this top-level field.

Classification: **SUBTRACT candidate** if repository reachability confirms no retained consumer or active contract needs the duplicate coordinate vector.

### 3. Guarded amount-scale initialization

Current code expresses empty-selection scale as mutable guarded state:

```bqn
amountScale ← 0
{𝕊: amountScale↩⌈´selectedScales}⍟(0<≠selectedScales) @
```

Reviewed sibling accounting owners already state the same admitted nonnegative-scale contract directly as:

```bqn
amountScale ← ⌈´0∾selectedScales
```

For canonical Facts scales this preserves empty = 0 and maximum selected scale without a conditional mutation.

Classification: **SUBTRACT candidate / local structural plumbing**.

### 4. Derived grand predicate inside `balanced`

Successful publication currently defines:

```bqn
balanced⇐(∧´1∾monthTotals=0) ∧ grandResult.coefficient=0
```

But `grandResult` is the already-successful exact sum of `monthTotals`. Therefore if every month total is zero, the grand coefficient is necessarily zero. The result has also already passed independent month-vs-Account grand reconciliation.

The human consumer labels this field `Balanced by month`, and active documentation says every valid month must remain zero-sum.

Classification: **SUBTRACT candidate**. The clearer retained meaning appears to be exactly:

```text
balanced = every month total is zero
```

Do not remove the public `balanced` field; remove only the derived extra predicate if focused evidence confirms byte-identical behavior.

## Retained named result fields

`months` duplicates Matrix row coordinates structurally, but unlike the candidates above it has a live semantic consumer and is the named calendar axis exposed to the Monthly Accounts section.

`account_keys` is also live: the Section uses it to produce human Account labels without carrying Facts into presentation.

Classification: **KEEP `months` and `account_keys`**.

## Current classification

KEEP:

- Month Account movement as the use-case owner;
- explicit month and Account axes;
- canonical Actual source/domain/layer admission;
- local Month coordinate vocabulary;
- classify → Group → Pivot kernel;
- MatrixResult ownership of dense cells and contributor alignment;
- source-qualified Posting contributors;
- independent month and Account reductions;
- both checked grand reductions and reconciliation equality;
- operation-local exactness diagnostics;
- public `months`, `account_keys`, `matrix`, and `totals` semantics.

SUBTRACT candidates:

- duplicate top-level `scale` if reachability confirms Matrix `scale` is the sole retained authority;
- duplicate top-level `account_indices` if no retained consumer exists;
- guarded mutable `amountScale` initialization;
- redundant `grand = 0` conjunct inside `balanced`.

OBSERVE:

- local `Contains` / `IndexOf` spelling, without introducing a shared generic helper;
- nested diagnostic control flow, unless a focused law proves a simpler structure preserves failure locality.

## Continuation

Keep the review cursor on `src/accounting/month_account_movement.bqn`.

Before changing production code, finish focused reachability for the duplicate top-level fields. Prefer one coherent public-surface subtraction if both duplicates are truly unconsumed, then reread the owner before deciding whether the two local expression simplifications belong in the same or a separate reason-to-change.
